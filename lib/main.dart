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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 過濾掉 Google Play Services 的錯誤訊息
  FlutterError.onError = (FlutterErrorDetails details) {
    if (!details.toString().contains('GoogleApiManager')) {
      FlutterError.presentError(details);
    }
  };

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
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF114D4D),
          onPrimary: Colors.white,
          secondary: Color(0xFF0A2E36),
          onSecondary: Colors.white,
          error: Colors.red.shade400,
          onError: Colors.white,
          background: Color(0xFF1A2327),
          onBackground: Colors.white,
          surface: Color(0xFF22303C),
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

  void selectTab(int index, {bool openAccountDialog = false}) {
    setState(() {
      _selectedIndex = index;
      _myAccountAutoOpen = openAccountDialog && index == 4;
    });
  }

  // 在應用啟動時檢查版本
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionCheckWrapper.checkVersionOnStartup(context);
    });
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
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (_selectedIndex != 4) {
              _myAccountAutoOpen = false;
            }
          });
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
}
