import 'package:flutter/material.dart';

class IconPicker extends StatelessWidget {
  final IconData selectedIcon;
  final ValueChanged<IconData> onIconSelected;
  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  static const List<IconData> icons = [
    Icons.apps,
    Icons.star,
    Icons.favorite,
    Icons.alarm,
    Icons.book,
    Icons.cake,
    Icons.camera_alt,
    Icons.directions_bus,
    Icons.email,
    Icons.home,
    Icons.music_note,
    Icons.phone,
    Icons.shopping_cart,
    Icons.work,
    Icons.wifi,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: icons.map((icon) {
        return GestureDetector(
          onTap: () => onIconSelected(icon),
          child: Container(
            decoration: BoxDecoration(
              color: icon == selectedIcon
                  ? Colors.teal.withValues(alpha: 0.2)
                  : Colors.white,
              border: Border.all(
                color: icon == selectedIcon
                    ? Colors.teal
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.teal, size: 32),
          ),
        );
      }).toList(),
    );
  }
}
