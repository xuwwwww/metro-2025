import 'package:flutter/material.dart';
import '../models/app_item.dart';

class DetailPage extends StatelessWidget {
  final AppItem item;
  DetailPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 64),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 28,
                color: item.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('這是 ${item.name} 的詳細頁', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
