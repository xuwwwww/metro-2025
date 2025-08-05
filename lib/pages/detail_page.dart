import 'package:flutter/material.dart';
import '../models/app_item.dart';
import '../widgets/adaptive_text.dart';

class DetailPage extends StatelessWidget {
  final AppItem item;
  DetailPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AdaptiveBodyText(item.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 64),
            const SizedBox(height: 16),
            AdaptiveTitle(item.name, color: item.color),
            const SizedBox(height: 16),
            AdaptiveSubtitle('這是 ${item.name} 的詳細頁'),
          ],
        ),
      ),
    );
  }
}
