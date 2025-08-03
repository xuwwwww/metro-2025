import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'pages/others_page.dart';
import 'pages/settings_page.dart';

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
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const OthersPage(),
    HomePage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.shifting,
        selectedFontSize: 14,
        unselectedFontSize: 0,
        iconSize: 34,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.widgets_outlined, size: 34),
            label: '其他',
            backgroundColor: Color(0xFF22303C),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 34),
            label: '主頁',
            backgroundColor: Color(0xFF22303C),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 34),
            label: '設定',
            backgroundColor: Color(0xFF22303C),
          ),
        ],
        showUnselectedLabels: false,
      ),
    );
  }
}
