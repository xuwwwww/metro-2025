import 'package:flutter/material.dart';
import '../widgets/adaptive_text.dart';

class OthersPage extends StatelessWidget {
  const OthersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: AdaptiveSubtitle('其他分頁', color: Colors.teal)),
    );
  }
}
