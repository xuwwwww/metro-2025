import 'package:flutter/material.dart';
import '../models/app_item.dart';
import '../widgets/adaptive_text.dart';

class ItemSelector extends StatelessWidget {
  final Function(AppItem) onAdd;

  const ItemSelector({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showItemSelector(context),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF26C6DA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  void _showItemSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF22303C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdaptiveTitle('新增項目'),
              const SizedBox(height: 20),

              // 應用程式區塊
              const AdaptiveSubtitle('應用程式', color: Color(0xFF26C6DA)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildAppItem(
                    context: context,
                    name: '相機',
                    icon: Icons.camera_alt,
                    color: Colors.purple,
                  ),
                  _buildAppItem(
                    context: context,
                    name: '音樂',
                    icon: Icons.music_note,
                    color: Colors.pink,
                  ),
                  _buildAppItem(
                    context: context,
                    name: '設定',
                    icon: Icons.settings,
                    color: Colors.grey,
                  ),
                  _buildAppItem(
                    context: context,
                    name: '訊息',
                    icon: Icons.message,
                    color: Colors.green,
                  ),
                  _buildAppItem(
                    context: context,
                    name: '電話',
                    icon: Icons.phone,
                    color: Colors.blue,
                  ),
                  _buildAppItem(
                    context: context,
                    name: '郵件',
                    icon: Icons.email,
                    color: Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Widget 區塊
              const AdaptiveSubtitle('Widget', color: Color(0xFF26C6DA)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildWidgetItem(
                    context: context,
                    name: '時鐘',
                    icon: Icons.access_time,
                    color: Colors.orange,
                    size: 3,
                    widgetType: 'clock',
                  ),
                  _buildWidgetItem(
                    context: context,
                    name: '天氣',
                    icon: Icons.wb_sunny,
                    color: Colors.blue,
                    size: 2,
                    widgetType: 'weather',
                  ),
                  _buildWidgetItem(
                    context: context,
                    name: '電池',
                    icon: Icons.battery_full,
                    color: Colors.green,
                    size: 2,
                    widgetType: 'battery',
                  ),
                  _buildWidgetItem(
                    context: context,
                    name: '日曆',
                    icon: Icons.calendar_today,
                    color: Colors.red,
                    size: 2,
                    widgetType: 'calendar',
                  ),
                  _buildWidgetItem(
                    context: context,
                    name: '計步器',
                    icon: Icons.directions_walk,
                    color: Colors.teal,
                    size: 2,
                    widgetType: 'pedometer',
                  ),
                  _buildWidgetItem(
                    context: context,
                    name: '鬧鐘',
                    icon: Icons.alarm,
                    color: Colors.indigo,
                    size: 2,
                    widgetType: 'alarm',
                  ),
                  _buildWidgetItem(
                    context: context,
                    name: '捷運',
                    icon: Icons.train,
                    color: Colors.blue,
                    size: 4,
                    widgetType: 'mrt',
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppItem({
    required BuildContext context,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onAdd(
          AppItem(
            name: name,
            icon: icon,
            color: color,
            size: 1,
            type: ItemType.app,
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2327),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            AdaptiveSmallText(name, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetItem({
    required BuildContext context,
    required String name,
    required IconData icon,
    required Color color,
    required int size,
    required String widgetType,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onAdd(
          AppItem(
            name: name,
            icon: icon,
            color: color,
            size: size,
            type: ItemType.widget,
            widgetType: widgetType,
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2327),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            AdaptiveSmallText(name, color: color),
            AdaptiveSmallText('${size}格', color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
