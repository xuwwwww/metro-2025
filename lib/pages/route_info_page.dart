import 'package:flutter/material.dart';
import '../widgets/adaptive_text.dart';

class RouteInfoPage extends StatelessWidget {
  const RouteInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 頂部標題欄
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: const Color(0xFF22303C),
            child: const Center(
              child: Text(
                '台北捷運',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 頁面標題
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF2A3A4A),
            child: const Center(
              child: Text(
                '查詢乘車資訊',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 主要內容區域
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_subway,
                    size: 80,
                    color: const Color(0xFF26C6DA),
                  ),
                  const SizedBox(height: 16),
                  const AdaptiveSubtitle('乘車資訊查詢', color: Color(0xFF26C6DA)),
                  const SizedBox(height: 8),
                  const AdaptiveSmallText('路線、時刻表、票價資訊', color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
