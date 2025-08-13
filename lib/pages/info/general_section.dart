import 'package:flutter/material.dart';

class GeneralSection extends StatelessWidget {
  const GeneralSection({
    super.key,
    required this.isOnline,
    required this.activeIndex,
    required this.onSelectIndex,
    required this.titleText,
    required this.pageController,
    required this.onPageChanged,
    required this.pages,
  });

  final bool isOnline;
  final int activeIndex;
  final void Function(int) onSelectIndex;
  final String titleText;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3A4A5A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(100, 70),
          topRight: Radius.elliptical(100, 70),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pill(
                  '緊急求助',
                  active: activeIndex == 0,
                  onTap: () => onSelectIndex(0),
                ),
                _pill(
                  '失物協尋',
                  active: activeIndex == 1,
                  onTap: () => onSelectIndex(1),
                ),
                _pill(
                  '一般客服',
                  active: activeIndex == 2,
                  onTap: () => onSelectIndex(2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent,
                  color: Color(0xFF26C6DA),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  titleText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                if (isOnline)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: onPageChanged,
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {bool active = false, VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF22303C) : const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFF26C6DA) : Colors.white24,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: active ? const Color(0xFF26C6DA) : Colors.white70,
          ),
        ),
      ),
    );
  }
}
