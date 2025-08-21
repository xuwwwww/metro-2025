import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'pages/route_info_page.dart';
import 'pages/info_page.dart';
import 'pages/go_benefits_page.dart';
import 'pages/my_account_page.dart';
import 'utils/version_check_wrapper.dart';
import 'utils/font_size_manager.dart';
import 'utils/global_login_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/behavior_tracker.dart';
import 'utils/location_tracking.dart';
import 'services/behavior_uploader.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 過濾掉 Google Play Services 的錯誤訊息
  FlutterError.onError = (FlutterErrorDetails details) {
    if (!details.toString().contains('GoogleApiManager')) {
      FlutterError.presentError(details);
    }
  };

  await Hive.initFlutter();
  await Firebase.initializeApp();

  // 初始化全局登入狀態
  await GlobalLoginState.initialize();

  // 初始化字體大小管理器
  await FontSizeManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metro App',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF114D4D),
            ).copyWith(
              primary: const Color(0xFF114D4D),
              onPrimary: Colors.white,
              secondary: const Color(0xFF0A2E36),
              onSecondary: Colors.white,
              error: Colors.red.shade400,
              onError: Colors.white,
              background: const Color(0xFF1A2327),
              surface: const Color(0xFF22303C),
              onSurface: Colors.white,
            ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A2327),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF114D4D),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF22303C),
          selectedItemColor: Color(0xFF26C6DA),
          unselectedItemColor: Color(0xFF607D8B),
          showUnselectedLabels: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: MainScaffold(key: MainScaffold.globalKey),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  // 提供全域控制切換分頁
  static final GlobalKey<_MainScaffoldState> globalKey =
      GlobalKey<_MainScaffoldState>();

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 2; // 主頁在中間位置
  bool _myAccountAutoOpen = false;
  DateTime _tabEnterUtc = DateTime.now().toUtc();
  String _currentScreen = 'Home';
  final BehaviorTracker _behavior = BehaviorTracker();
  final LocationTrackingService _tracking = LocationTrackingService();
  Timer? _dailyUploadTimer;

  void selectTab(int index, {bool openAccountDialog = false}) {
    _onTabWillChange(index, openAccountDialog: openAccountDialog);
  }

  // 在應用啟動時檢查版本
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionCheckWrapper.checkVersionOnStartup(context);
    });
    // 初始化行為追蹤器（Hive 已在 main() 初始化）
    _behavior.init();
    // 啟動定位追蹤（供 predict 用）
    _tracking.init().then((_) => _tracking.startForegroundStream());
    _scheduleDailyUpload();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const RouteInfoPage(),
      InfoPage(key: InfoPage.globalKey),
      HomePage(),
      const GoBenefitsPage(),
      MyAccountPage(autoOpenAccountDialog: _myAccountAutoOpen),
    ];
    return Scaffold(
      body: Stack(
        children: [
          pages[_selectedIndex],
          // 移除懸浮 AI Demo，統一改為主頁頂部入口
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _onTabWillChange(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_subway),
            label: '查詢乘車資訊',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: '資訊'),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '主頁'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'GO優惠'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的帳戶'),
        ],
      ),
    );
  }

  // 將追蹤邏輯保留為私有成員方法，避免擴充造成 linter 警告
  void _onTabWillChange(int toIndex, {bool openAccountDialog = false}) {
    // 1) 結算上一個 tab 的停留時間
    final now = DateTime.now().toUtc();
    final duration = now.difference(_tabEnterUtc).inSeconds;
    _behavior.logScreenView(_currentScreen, durationSec: duration);

    // 2) 切換狀態
    setState(() {
      _selectedIndex = toIndex;
      _myAccountAutoOpen = openAccountDialog && toIndex == 4;
      _tabEnterUtc = now;
      _currentScreen = _screenNameForIndex(toIndex);
    });

    // 3) 進入新 tab 的曝光（duration 先不填，由下次切換時結算）
    _behavior.logScreenView(_currentScreen);
  }

  String _screenNameForIndex(int i) {
    switch (i) {
      case 0:
        return 'RouteInfoPage';
      case 1:
        return 'InfoPage';
      case 2:
        return 'Home';
      case 3:
        return 'GoBenefitsPage';
      case 4:
        return 'MyAccountPage';
      default:
        return 'Unknown';
    }
  }

  // 每天 01:00 自動上傳前一日行為資料
  void _scheduleDailyUpload() {
    _dailyUploadTimer?.cancel();
    final now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, 1, 0);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    final wait = next.difference(now);
    _dailyUploadTimer = Timer(wait, () async {
      try {
        final uid = GlobalLoginState.currentUid ?? 'anonymous';
        final y = DateTime.now().subtract(const Duration(days: 1));
        final ymd =
            '${y.year.toString().padLeft(4, '0')}${y.month.toString().padLeft(2, '0')}${y.day.toString().padLeft(2, '0')}';
        await BehaviorUploader().flushDay(uid, ymd);
      } catch (_) {}
      // 重新排程下一次
      _scheduleDailyUpload();
    });
  }
}
