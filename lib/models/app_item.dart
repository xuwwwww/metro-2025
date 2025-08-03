import 'package:flutter/material.dart';

enum ItemType {
  app, // 一般應用程式
  widget, // 動態 widget
}

class AppItem {
  String name;
  IconData icon;
  Color color;
  int size; // 幾格寬，預設1，widget可設3
  int row;
  int col;
  ItemType type;
  String? widgetType; // 用於識別 widget 類型，如 'clock', 'weather' 等

  AppItem({
    required this.name,
    required this.icon,
    required this.color,
    this.size = 1,
    this.row = 0,
    this.col = 0,
    this.type = ItemType.app,
    this.widgetType,
  });

  // 創建時鐘 widget 的工廠方法
  factory AppItem.clock({int size = 3, int row = 0, int col = 0}) {
    return AppItem(
      name: '時鐘',
      icon: Icons.access_time,
      color: Colors.orange,
      size: size,
      row: row,
      col: col,
      type: ItemType.widget,
      widgetType: 'clock',
    );
  }

  // 創建天氣 widget 的工廠方法
  factory AppItem.weather({int size = 2, int row = 0, int col = 0}) {
    return AppItem(
      name: '天氣',
      icon: Icons.wb_sunny,
      color: Colors.blue,
      size: size,
      row: row,
      col: col,
      type: ItemType.widget,
      widgetType: 'weather',
    );
  }

  // 創建電池 widget 的工廠方法
  factory AppItem.battery({int size = 2, int row = 0, int col = 0}) {
    return AppItem(
      name: '電池',
      icon: Icons.battery_full,
      color: Colors.green,
      size: size,
      row: row,
      col: col,
      type: ItemType.widget,
      widgetType: 'battery',
    );
  }
}
