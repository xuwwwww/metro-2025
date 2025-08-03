import 'package:flutter/material.dart';

class AppItem {
  String name;
  IconData icon;
  Color color;
  int size; // 幾格寬，預設1，widget可設3
  int row;
  int col;

  AppItem({
    required this.name,
    required this.icon,
    required this.color,
    this.size = 1,
    this.row = 0,
    this.col = 0,
  });
}
