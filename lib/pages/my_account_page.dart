import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/version_checker.dart';
import '../utils/font_size_manager.dart';
import '../utils/global_login_state.dart';
import '../widgets/adaptive_text.dart';

class MyAccountPage extends StatefulWidget {
  final bool autoOpenAccountDialog;
  const MyAccountPage({super.key, this.autoOpenAccountDialog = false});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
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

  // 移除最新消息數據

  @override
  void initState() {
    super.initState();
    _loadAllRooms();
    // 從全局狀態載入登入狀態
    _loadGlobalLoginState();
    // 如果已經登入，載入用戶權限
    if (_isLoggedIn) {
      _loadUserPermissions();
      _verifyUserStillExists();
    }
    // 初始化字體大小管理器
    _initializeFontSize();
    // 若要求自動開啟帳戶設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoOpenAccountDialog) {
        _showAccountDialog();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22303C),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部標題欄
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFF22303C),
              child: const Center(
                child: Text(
                  '台北捷運',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 頁面標題
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFF2A3A4A),
              child: Center(
                child: Text(
                  _userName.isNotEmpty ? '我的帳戶 · $_userName' : '我的帳戶',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // 主要內容區域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 常用功能區塊
                    _buildFrequentFunctionsSection(),

                    const SizedBox(height: 24),

                    // 開發者選項區塊
                    _buildDeveloperOptionsSection(),

                    const SizedBox(height: 24),

                    // 版本資訊
                    FutureBuilder<String>(
                      future: VersionChecker().getLocalVersionString(),
                      builder: (context, snapshot) {
                        final version = snapshot.data ?? '載入中...';
                        return Center(child: AdaptiveSmallText('版本 $version'));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 常用設定：改為與「開發人員選項」一致的清單排版
  Widget _buildFrequentFunctionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '常用設定',
          style: TextStyle(
            color: Color(0xFF114D4D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          icon: Icons.person,
          title: '帳戶',
          subtitle: '管理帳戶資訊與安全',
          onTap: _showAccountDialog,
        ),
        _buildSettingTile(
          icon: Icons.notifications,
          title: '通知',
          subtitle: '推播提醒與通知設定',
          onTap: _showNotificationSettings,
        ),
        _buildSettingTile(
          icon: Icons.dark_mode,
          title: '主題',
          subtitle: '深色模式與外觀',
          onTap: _showThemeSettings,
        ),
        _buildSettingTile(
          icon: Icons.text_fields,
          title: '字體',
          subtitle: '調整字體大小',
          onTap: _showFontSettings,
        ),
      ],
    );
  }

  // 功能按鈕
  Widget _buildFunctionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF22303C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF114D4D), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF26C6DA), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // 開發者選項區塊
  Widget _buildDeveloperOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '開發人員選項',
          style: TextStyle(
            color: Color(0xFF114D4D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        // 移除舊的網格配置相關選項
        _buildSettingTile(
          icon: Icons.text_fields,
          title: '重置字體大小',
          subtitle: '重置為預設字體大小',
          onTap: () => _resetFontSize(context),
        ),
      ],
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

  // 帳戶對話框
  void _showAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '帳戶設定',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoggedIn) ...[
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF26C6DA)),
                title: const Text(
                  '用戶資訊',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'UID: $_currentUid\n名稱: $_userName',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showNameEditDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF26C6DA)),
                title: const Text('登出', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  setState(() {
                    _isLoggedIn = false;
                    _currentUid = null;
                    _isAdmin = false;
                    _userName = '';
                    _selectedRooms.clear();
                  });
                  await GlobalLoginState.clearLoginState();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已登出')));
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  '刪除帳戶',
                  style: TextStyle(color: Colors.redAccent),
                ),
                subtitle: const Text(
                  '此動作將清除本地登入狀態（示意）',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () async {
                  // 示意刪除：清除本地登入與權限（實際應呼叫後端刪除）
                  setState(() {
                    _isLoggedIn = false;
                    _currentUid = null;
                    _isAdmin = false;
                    _userName = '';
                    _selectedRooms.clear();
                  });
                  await GlobalLoginState.clearLoginState();
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('帳戶已刪除（示意）')));
                  }
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.login, color: Color(0xFF26C6DA)),
                title: const Text('登入', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showLoginDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Color(0xFF26C6DA)),
                title: const Text(
                  '創立帳戶',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateAccountDialog(context);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // 通知設定對話框
  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '通知設定',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('推播通知', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                '開啟或關閉推播通知',
                style: TextStyle(color: Colors.grey),
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: const Color(0xFF26C6DA),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 主題設定對話框
  void _showThemeSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '主題設定',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('深色模式', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                '使用深色主題',
                style: TextStyle(color: Colors.grey),
              ),
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
              activeColor: const Color(0xFF26C6DA),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 字體設定對話框
  void _showFontSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '字體大小設定',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${FontSizeManager.currentFontSizeDescription} (${_fontSize.toStringAsFixed(1)})',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    Slider(
                      value: _fontSize,
                      min: FontSizeManager.minFontSize,
                      max: FontSizeManager.maxFontSize,
                      divisions: 6,
                      activeColor: const Color(0xFF26C6DA),
                      onChanged: (value) async {
                        setDialogState(() {
                          _fontSize = value;
                        });
                        await FontSizeManager.setFontSize(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('小', style: TextStyle(color: Colors.grey)),
                        const Text('大', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
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
    final outerContext = context;
    final uidController = TextEditingController();
    final pwdController = TextEditingController();

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
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
                  outerContext,
                ).showSnackBar(const SnackBar(content: Text('請輸入 UID')));
                return;
              }
              if (password.isEmpty) {
                ScaffoldMessenger.of(
                  outerContext,
                ).showSnackBar(const SnackBar(content: Text('請輸入密碼')));
                return;
              }

              try {
                // 檢查用戶是否存在
                final doc = await _firestore.collection('users').doc(uid).get();
                if (!doc.exists) {
                  ScaffoldMessenger.of(
                    outerContext,
                  ).showSnackBar(const SnackBar(content: Text('帳戶不存在，請先創立帳戶')));
                  return;
                }

                final data = doc.data()!;
                final storedPassword = data['password'] as String? ?? '';
                final userName = data['displayName'] as String? ?? '';

                if (password != storedPassword) {
                  ScaffoldMessenger.of(
                    outerContext,
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
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(
                  outerContext,
                ).showSnackBar(const SnackBar(content: Text('登入成功')));
                await _loadUserPermissions();
              } catch (e) {
                ScaffoldMessenger.of(
                  outerContext,
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
    final outerContext = context;
    final nameController = TextEditingController();
    final pwdController = TextEditingController();

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
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
                  outerContext,
                ).showSnackBar(const SnackBar(content: Text('請輸入顯示名稱')));
                return;
              }
              if (password.isEmpty) {
                ScaffoldMessenger.of(
                  outerContext,
                ).showSnackBar(const SnackBar(content: Text('請輸入密碼')));
                return;
              }

              try {
                // 以雲端 config 取得下一個 UID（交易遞增），若失敗則回退掃描法
                String nextUid;
                try {
                  nextUid = await _reserveNextUidFromConfig();
                } catch (_) {
                  nextUid = await _getNextAvailableUid();
                }

                await _firestore.collection('users').doc(nextUid).set({
                  'displayName': name,
                  'permissions': [],
                  'password': password,
                });

                // 直接登入並保存狀態
                setState(() {
                  _isLoggedIn = true;
                  _currentUid = nextUid;
                  _isAdmin = false;
                  _userName = name;
                });
                await GlobalLoginState.setLoginState(
                  isLoggedIn: true,
                  uid: nextUid,
                  isAdmin: false,
                  userName: name,
                );

                // 顯示 UID 成功訊息
                if (mounted) {
                  Navigator.pop(dialogContext); // 關閉建立對話框
                }
                if (mounted) {
                  showDialog(
                    context: outerContext,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF22303C),
                      title: const Text(
                        '帳戶創立成功',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      content: Text(
                        '您的 UID 是: $nextUid',
                        style: const TextStyle(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            '確定',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  outerContext,
                ).showSnackBar(const SnackBar(content: Text('創立帳戶失敗，請稍後再試')));
              }
            },
            child: const Text('創立帳戶', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 使用 Firestore config 以交易方式保留下一個 UID 並自動 +1
  Future<String> _reserveNextUidFromConfig() async {
    final docRef = _firestore.collection('config').doc('app');
    return await _firestore.runTransaction<String>((tx) async {
      final snap = await tx.get(docRef);
      int counter = 1;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final value = data?['uidCounter'];
        if (value is int) counter = value;
        if (value is String && int.tryParse(value) != null)
          counter = int.parse(value);
      }
      final reserved = counter.toString();
      tx.set(docRef, {'uidCounter': counter + 1}, SetOptions(merge: true));
      return reserved;
    });
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

  // 啟動時驗證本地已登入帳號是否仍存在雲端
  Future<void> _verifyUserStillExists() async {
    if (_currentUid == null || _currentUid!.isEmpty) return;
    try {
      final snap = await _firestore.collection('users').doc(_currentUid).get();
      if (!snap.exists) {
        await GlobalLoginState.clearLoginState();
        setState(() {
          _isLoggedIn = false;
          _currentUid = null;
          _isAdmin = false;
          _userName = '';
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('您的帳號已不存在，請重新登入')));
        }
      }
    } catch (_) {
      // 靜默失敗，不打斷啟動
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

  // 已移除舊的網格配置相關函式

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

  // 移除舊的網格配置重新載入對話框

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
