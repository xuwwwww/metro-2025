import 'package:flutter/material.dart';

class SimpleColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  const SimpleColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Color> colors = [
    Colors.teal,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.amber,
    Colors.cyan,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
    Colors.lime,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color == selectedColor
                    ? Colors.black
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
