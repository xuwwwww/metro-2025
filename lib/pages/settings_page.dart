import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/version_check_wrapper.dart';
import '../utils/version_checker.dart';
import '../utils/grid_config.dart';
import '../utils/font_size_manager.dart';
import '../widgets/adaptive_text.dart';

// 全局登入狀態管理
class GlobalLoginState {
  static bool _isLoggedIn = false;
  static String? _currentUid;
  static bool _isAdmin = false;
  static String _userName = '';

  // 初始化 - 從本地存儲載入登入狀態
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _currentUid = prefs.getString('currentUid');
      _isAdmin = prefs.getBool('isAdmin') ?? false;
      _userName = prefs.getString('userName') ?? '';
    } catch (e) {
      print('載入登入狀態失敗: $e');
    }
  }

  // 設置登入狀態
  static Future<void> setLoginState({
    required bool isLoggedIn,
    String? uid,
    bool isAdmin = false,
    String userName = '',
  }) async {
    _isLoggedIn = isLoggedIn;
    _currentUid = uid;
    _isAdmin = isAdmin;
    _userName = userName;

    // 保存到本地存儲
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);
      await prefs.setString('currentUid', uid ?? '');
      await prefs.setBool('isAdmin', isAdmin);
      await prefs.setString('userName', userName);
    } catch (e) {
      print('保存登入狀態失敗: $e');
    }
  }

  // 清除登入狀態
  static Future<void> clearLoginState() async {
    _isLoggedIn = false;
    _currentUid = null;
    _isAdmin = false;
    _userName = '';

    // 清除本地存儲
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('currentUid');
      await prefs.remove('isAdmin');
      await prefs.remove('userName');
    } catch (e) {
      print('清除登入狀態失敗: $e');
    }
  }

  // 獲取登入狀態
  static bool get isLoggedIn => _isLoggedIn;
  static String? get currentUid => _currentUid;
  static bool get isAdmin => _isAdmin;
  static String get userName => _userName;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 登入與使用者狀態
  bool _isLoggedIn = false;
  String? _currentUid;
  bool _isAdmin = false;
  String _userName = '';

  // App 設定
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  double _fontSize = FontSizeManager.defaultFontSize;

  // 聊天室列表與選擇
  List<String> _allRooms = [];
  Set<String> _selectedRooms = {};

  @override
  void initState() {
    super.initState();
    _loadAllRooms();
    // 從全局狀態載入登入狀態
    _loadGlobalLoginState();
    // 如果已經登入，載入用戶權限
    if (_isLoggedIn) {
      _loadUserPermissions();
    }
    // 初始化字體大小管理器
    _initializeFontSize();
  }

  // 從全局狀態載入登入狀態
  void _loadGlobalLoginState() {
    setState(() {
      _isLoggedIn = GlobalLoginState.isLoggedIn;
      _currentUid = GlobalLoginState.currentUid;
      _isAdmin = GlobalLoginState.isAdmin;
      _userName = GlobalLoginState.userName;
    });
  }

  // 初始化字體大小
  Future<void> _initializeFontSize() async {
    await FontSizeManager.initialize();
    setState(() {
      _fontSize = FontSizeManager.fontSize;
    });
    // 添加字體大小變更監聽器
    FontSizeManager.addListener(_onFontSizeChanged);
  }

  // 字體大小變更回調
  void _onFontSizeChanged(double newFontSize) {
    setState(() {
      _fontSize = newFontSize;
    });
  }

  // 讀取所有聊天室 ID
  Future<void> _loadAllRooms() async {
    try {
      final snap = await _firestore.collection('chatRooms').get();
      setState(() {
        _allRooms = snap.docs.map((d) => d.id).toList();
      });
    } catch (e) {
      // 如果 Firestore 未初始化或沒有聊天室，使用預設列表
      setState(() {
        _allRooms = ['room1', 'room2', 'room3'];
      });
    }
  }

  // 讀取當前使用者的聊天室權限
  Future<void> _loadUserPermissions() async {
    if (_currentUid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUid).get();
      final data = doc.data();
      final perms = List<String>.from(data?['permissions'] ?? []);
      final userName = data?['displayName'] as String? ?? '';
      setState(() {
        _selectedRooms = perms.toSet();
        _userName = userName;
      });
      // 更新靜態變數
      await GlobalLoginState.setLoginState(
        isLoggedIn: _isLoggedIn,
        uid: _currentUid,
        isAdmin: _isAdmin,
        userName: _userName,
      );
    } catch (e) {
      // 如果讀取失敗，清空選擇
      setState(() {
        _selectedRooms.clear();
        _userName = '';
      });
    }
  }

  // 儲存並同步聊天室權限
  Future<void> _savePermissions() async {
    final uid = _currentUid!;
    try {
      // 更新 users/{uid}.permissions
      await _firestore.collection('users').doc(uid).set({
        'permissions': _selectedRooms.toList(),
      }, SetOptions(merge: true));

      // 同步 chatRooms/{room}/members
      final batch = _firestore.batch();
      for (var roomId in _allRooms) {
        final memberRef = _firestore
            .collection('chatRooms')
            .doc(roomId)
            .collection('members')
            .doc(uid);
        if (_selectedRooms.contains(roomId)) {
          batch.set(memberRef, {'joinedAt': FieldValue.serverTimestamp()});
        } else {
          batch.delete(memberRef);
        }
      }
      await batch.commit();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('聊天室權限已更新')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('儲存失敗，請稍後再試')));
    }
  }

  // 更新用戶名稱
  Future<void> _updateUserName(String newName) async {
    if (_currentUid == null) return;
    try {
      await _firestore.collection('users').doc(_currentUid).update({
        'displayName': newName,
      });
      setState(() {
        _userName = newName;
      });
      // 更新靜態變數
      await GlobalLoginState.setLoginState(
        isLoggedIn: _isLoggedIn,
        uid: _currentUid,
        isAdmin: _isAdmin,
        userName: _userName,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名稱已更新')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('更新失敗，請稍後再試')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頁首
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: const AdaptiveTitle('設定'),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('帳戶設定'),
            const SizedBox(height: 12),
            if (_isLoggedIn) ...[
              _buildSettingTile(
                icon: Icons.person,
                title: '用戶: $_currentUid',
                subtitle: _userName.isNotEmpty
                    ? _userName
                    : (_isAdmin ? '管理者' : '一般成員'),
                onTap: () => _showNameEditDialog(context),
              ),
              _buildSettingTile(
                icon: Icons.logout,
                title: '登出',
                subtitle: '登出當前帳戶',
                onTap: () async {
                  setState(() {
                    _isLoggedIn = false;
                    _currentUid = null;
                    _isAdmin = false;
                    _userName = '';
                    _selectedRooms.clear();
                  });
                  // 更新靜態登入狀態
                  await GlobalLoginState.clearLoginState();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已登出')));
                },
              ),
            ] else ...[
              _buildSettingTile(
                icon: Icons.login,
                title: '登入',
                subtitle: '登入現有帳戶',
                onTap: () => _showLoginDialog(context),
              ),
              _buildSettingTile(
                icon: Icons.person_add,
                title: '創立帳戶',
                subtitle: '建立新帳戶',
                onTap: () => _showCreateAccountDialog(context),
              ),
            ],

            const SizedBox(height: 24),
            if (_isLoggedIn) ...[
              _buildSectionTitle('聊天室設定'),
              const SizedBox(height: 12),
              Container(
                height: 200, // 固定高度確保可見性
                child: ListView.builder(
                  itemCount: _allRooms.length,
                  itemBuilder: (context, index) {
                    final roomId = _allRooms[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22303C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF114D4D),
                          width: 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          roomId,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: _selectedRooms.contains(roomId),
                        activeColor: const Color(0xFF26C6DA),
                        onChanged: (v) {
                          setState(() {
                            if (v!)
                              _selectedRooms.add(roomId);
                            else
                              _selectedRooms.remove(roomId);
                          });
                        },
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26C6DA),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '儲存房間選擇',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // App 設定區塊（保留原有功能）
            _buildSectionTitle('App 設定'),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.notifications,
              title: '通知',
              subtitle: '開啟或關閉推播通知',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                activeColor: const Color(0xFF26C6DA),
              ),
            ),
            _buildSettingTile(
              icon: Icons.dark_mode,
              title: '深色模式',
              subtitle: '使用深色主題',
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: (v) => setState(() => _darkModeEnabled = v),
                activeColor: const Color(0xFF26C6DA),
              ),
            ),
            _buildSettingTile(
              icon: Icons.text_fields,
              title: '字體大小',
              subtitle:
                  '${FontSizeManager.currentFontSizeDescription} (${_fontSize.toStringAsFixed(1)})',
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _fontSize,
                  min: FontSizeManager.minFontSize,
                  max: FontSizeManager.maxFontSize,
                  divisions: 6,
                  activeColor: const Color(0xFF26C6DA),
                  onChanged: (v) async {
                    await FontSizeManager.setFontSize(v);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('開發人員選項'),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.developer_mode,
              title: '版本檢查',
              subtitle: '檢查應用程式版本資訊',
              onTap: () => _showVersionInfoDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.clear_all,
              title: '清除本地資料',
              subtitle: '清除所有本地保存的設定和佈局',
              onTap: () => _showClearDataDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.refresh,
              title: '重新載入配置',
              subtitle: '重新載入網格配置設定',
              onTap: () => _reloadGridConfig(context),
            ),
            _buildSettingTile(
              icon: Icons.text_fields,
              title: '重置字體大小',
              subtitle: '重置為預設字體大小',
              onTap: () => _resetFontSize(context),
            ),

            const SizedBox(height: 24),
            FutureBuilder<String>(
              future: VersionChecker().getLocalVersionString(),
              builder: (context, snapshot) {
                final version = snapshot.data ?? '載入中...';
                return Center(child: AdaptiveSmallText('版本 $version'));
              },
            ),
            const SizedBox(height: 24), // 底部額外間距
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return AdaptiveSubtitle(title, color: const Color(0xFF114D4D));
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22303C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF114D4D), width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF26C6DA)),
        title: AdaptiveText(
          title,
          fontSizeMultiplier: 1.0,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        subtitle: AdaptiveSmallText(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  // 名稱編輯對話框
  void _showNameEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '編輯名稱',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '顯示名稱',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF114D4D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF26C6DA)),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                _updateUserName(newName);
              }
              Navigator.pop(context);
            },
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 登入對話框
  void _showLoginDialog(BuildContext context) {
    final uidController = TextEditingController();
    final pwdController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '登入',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uidController,
              decoration: const InputDecoration(
                labelText: 'UID',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF114D4D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF26C6DA)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密碼',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF114D4D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF26C6DA)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            onPressed: () async {
              final uid = uidController.text.trim();
              final password = pwdController.text.trim();

              if (uid.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('請輸入 UID')));
                return;
              }
              if (password.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('請輸入密碼')));
                return;
              }

              try {
                // 檢查用戶是否存在
                final doc = await _firestore.collection('users').doc(uid).get();
                if (!doc.exists) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('帳戶不存在，請先創立帳戶')));
                  return;
                }

                final data = doc.data()!;
                final storedPassword = data['password'] as String? ?? '';
                final userName = data['displayName'] as String? ?? '';

                if (password != storedPassword) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('密碼錯誤')));
                  return;
                }

                setState(() {
                  _isLoggedIn = true;
                  _currentUid = uid;
                  _isAdmin = (uid == '0');
                  _userName = userName;
                });
                // 更新靜態登入狀態
                await GlobalLoginState.setLoginState(
                  isLoggedIn: true,
                  uid: uid,
                  isAdmin: (uid == '0'),
                  userName: userName,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('登入成功')));
                await _loadUserPermissions();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('登入失敗，請稍後再試')));
              }
            },
            child: const Text('登入', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 創立帳戶對話框
  void _showCreateAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final pwdController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '創立帳戶',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '顯示名稱',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF114D4D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF26C6DA)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密碼',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF114D4D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF26C6DA)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final password = pwdController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('請輸入顯示名稱')));
                return;
              }
              if (password.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('請輸入密碼')));
                return;
              }

              try {
                // 生成下一個可用的 UID
                final nextUid = await _getNextAvailableUid();

                await _firestore.collection('users').doc(nextUid).set({
                  'displayName': name,
                  'permissions': [],
                  'password': password,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('帳戶創立成功！您的 UID 是: $nextUid'),
                    duration: const Duration(seconds: 4),
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('創立帳戶失敗，請稍後再試')));
              }
            },
            child: const Text('創立帳戶', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 獲取下一個可用的 UID
  Future<String> _getNextAvailableUid() async {
    try {
      // 獲取所有用戶文檔
      final usersSnapshot = await _firestore.collection('users').get();

      if (usersSnapshot.docs.isEmpty) {
        // 如果沒有用戶，從 1 開始
        return '1';
      }

      // 找出最大的數字 UID
      int maxUid = 0;
      for (final doc in usersSnapshot.docs) {
        final uid = doc.id;
        // 只考慮數字 UID，跳過特殊 UID 如 '0' (admin)
        if (uid != '0' && int.tryParse(uid) != null) {
          final uidNum = int.parse(uid);
          if (uidNum > maxUid) {
            maxUid = uidNum;
          }
        }
      }

      // 返回下一個可用的 UID
      return (maxUid + 1).toString();
    } catch (e) {
      // 如果出錯，返回一個基於時間戳的 UID
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // 顯示版本資訊對話框
  void _showVersionInfoDialog(BuildContext context) async {
    final localVersion = await VersionChecker().getLocalVersionString();
    final remoteVersion = await VersionChecker().getLatestVersionString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '版本資訊',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptiveBodyText('本地版本: $localVersion'),
            const SizedBox(height: 8),
            AdaptiveBodyText('遠端版本: $remoteVersion'),
            const SizedBox(height: 16),
            AdaptiveSubtitle('網格配置:'),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, dynamic>>(
              future: _getGridConfigInfo(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final config = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveSmallText('格線大小: ${config['cellSize']}'),
                      AdaptiveSmallText('格線間距: ${config['cellSpacing']}'),
                      AdaptiveSmallText('欄位數量: ${config['crossAxisCount']}'),
                      AdaptiveSmallText('時鐘寬度: ${config['clockWidth']}'),
                      AdaptiveSmallText('天氣寬度: ${config['weatherWidth']}'),
                    ],
                  );
                }
                return const AdaptiveSmallText('載入中...');
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 獲取網格配置資訊
  Future<Map<String, dynamic>> _getGridConfigInfo() async {
    try {
      return {
        'cellSize': GridConfig.cellSize,
        'cellSpacing': GridConfig.cellSpacing,
        'crossAxisCount': GridConfig.defaultCrossAxisCount,
        'clockWidth': GridConfig.getWidgetDimensions('clock')['width'],
        'weatherWidth': GridConfig.getWidgetDimensions('weather')['width'],
      };
    } catch (e) {
      return {
        'cellSize': '載入失敗',
        'cellSpacing': '載入失敗',
        'crossAxisCount': '載入失敗',
        'clockWidth': '載入失敗',
        'weatherWidth': '載入失敗',
      };
    }
  }

  // 顯示清除資料對話框
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '清除本地資料',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '這將會清除所有本地保存的設定、佈局和登入狀態。\n\n此操作無法復原，確定要繼續嗎？',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _clearAllLocalData();
              Navigator.pop(context);
            },
            child: const Text('清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 清除所有本地資料
  Future<void> _clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // 清除所有 SharedPreferences 資料

      // 重新初始化登入狀態
      await GlobalLoginState.initialize();

      // 重新載入狀態
      _loadGlobalLoginState();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('本地資料已清除，請重新啟動應用程式'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清除資料失敗: $e')));
    }
  }

  // 重新載入網格配置
  void _reloadGridConfig(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '重新載入配置',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '網格配置已重新載入。\n\n請重新啟動應用程式以套用變更。',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 重置字體大小
  void _resetFontSize(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '重置字體大小',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '確定要將字體大小重置為預設值嗎？',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            onPressed: () async {
              await FontSizeManager.resetToDefault();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('字體大小已重置為預設值')));
            },
            child: const Text('重置', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
