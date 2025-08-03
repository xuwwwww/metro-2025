import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double _fontSize = 16.0;

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
              child: const Text(
                '設定',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF26C6DA),
                ),
              ),
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
              subtitle: '調整應用程式字體大小',
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 6,
                  activeColor: const Color(0xFF26C6DA),
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                '版本 0.0.1',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            const SizedBox(height: 24), // 底部額外間距
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF114D4D),
      ),
    );
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
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
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
}
