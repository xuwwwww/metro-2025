import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text('設定分頁', style: TextStyle(fontSize: 22, color: Colors.teal)),
      ),
    );
  }
}
