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
