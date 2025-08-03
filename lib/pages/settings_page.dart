import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoggedIn = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  double _fontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            )
            ,
            // 帳戶設定區塊
            _buildSectionTitle('帳戶設定'),
            const SizedBox(height: 12),
            if (_isLoggedIn) ...[
              _buildSettingTile(
                icon: Icons.person,
                title: '個人資料',
                subtitle: '查看和編輯個人資料',
                onTap: () {
                  _showProfileDialog(context);
                },
              ),
              _buildSettingTile(
                icon: Icons.logout,
                title: '登出',
                subtitle: '登出當前帳戶',
                onTap: () {
                  setState(() {
                    _isLoggedIn = false;
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已登出')));
                },
              ),
            ] else ...[
              _buildSettingTile(
                icon: Icons.login,
                title: '登入',
                subtitle: '登入您的帳戶',
                onTap: () {
                  _showLoginDialog(context);
                },
              ),
            ],

            const SizedBox(height: 24),

            // App 設定區塊
            _buildSectionTitle('App 設定'),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.notifications,
              title: '通知',
              subtitle: '開啟或關閉推播通知',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeColor: const Color(0xFF26C6DA),
              ),
            ),
            _buildSettingTile(
              icon: Icons.dark_mode,
              title: '深色模式',
              subtitle: '使用深色主題',
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                },
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
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value;
                    });
                  },
                ),
              ),
            ),



            const Spacer(),

            // 版本資訊
            Center(
              child: Text(
                '版本 0.0.1',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
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

  void _showLoginDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text('登入', style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '手機號碼',
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
              controller: passwordController,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // 開發階段，任何輸入都可以登入
              setState(() {
                _isLoggedIn = true;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('登入成功')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            child: const Text('登入', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text('個人資料', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('用戶名: 測試用戶', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('手機號碼: 0912345678', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('註冊時間: 2024-01-01', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
            ),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
