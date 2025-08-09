import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

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
                '資訊',
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側圓形功能列
                Container(
                  width: 68,
                  color: const Color(0xFF1A1A1A),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _bubble(icon: Icons.directions_transit, label: 'LOGO'),
                      const SizedBox(height: 12),
                      _bubble(icon: Icons.info, label: '一般'),
                      const SizedBox(height: 12),
                      _bubble(icon: Icons.emoji_events, label: '共襄'),
                      const SizedBox(height: 12),
                      _bubble(icon: Icons.chat_bubble_outline, label: '開聊'),
                      const SizedBox(height: 12),
                      _bubble(
                        icon: Icons.music_note,
                        label: '音樂',
                        active: true,
                      ),
                      const Spacer(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // 右側內容卡
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '幸運兒點歌',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '參與抽獎贏取點歌機會！',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '抽獎倒數：xx:xx',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '已有000人參加！',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 卡片
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A4A5A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // tabs
                                Row(
                                  children: [
                                    _pill('抽獎參與', active: true),
                                    const SizedBox(width: 8),
                                    _pill('前往兌獎'),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  '抽獎規則',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 140,
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A3A4A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '這裡放抽獎規則文字，支持多行段落，內容僅示意。\n' * 4,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // CTA 按鈕
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE0E0E0),
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Text('我要參與抽獎！'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '8/8 6:00am 於官網公告抽獎結果',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({
    required IconData icon,
    required String label,
    bool active = false,
  }) {
    final Color base = active ? const Color(0xFF26C6DA) : Colors.white24;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: base.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: base, width: 2),
          ),
          child: Icon(icon, color: base, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _pill(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF22303C) : const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFF26C6DA) : Colors.white24,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xFF26C6DA) : Colors.white70,
        ),
      ),
    );
  }
}
