import 'package:flutter/material.dart';

class OthersPage extends StatelessWidget {
  const OthersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text('其他分頁', style: TextStyle(fontSize: 22, color: Colors.teal)),
      ),
    );
  }
}
