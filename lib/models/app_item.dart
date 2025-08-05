import 'package:flutter/material.dart';
import '../utils/grid_config.dart';

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
  factory AppItem.clock({int? size, int row = 0, int col = 0}) {
    final dimensions = GridConfig.getWidgetDimensions('clock');
    return AppItem(
      name: '時鐘',
      icon: Icons.access_time,
      color: Colors.orange,
      size: size ?? dimensions['width']!,
      row: row,
      col: col,
      type: ItemType.widget,
      widgetType: 'clock',
    );
  }

  // 創建天氣 widget 的工廠方法
  factory AppItem.weather({int? size, int row = 0, int col = 0}) {
    final dimensions = GridConfig.getWidgetDimensions('weather');
    return AppItem(
      name: '天氣',
      icon: Icons.wb_sunny,
      color: Colors.blue,
      size: size ?? dimensions['width']!,
      row: row,
      col: col,
      type: ItemType.widget,
      widgetType: 'weather',
    );
  }

  // 創建電池 widget 的工廠方法
  factory AppItem.battery({int? size, int row = 0, int col = 0}) {
    final dimensions = GridConfig.getWidgetDimensions('battery');
    return AppItem(
      name: '電池',
      icon: Icons.battery_full,
      color: Colors.green,
      size: size ?? dimensions['width']!,
      row: row,
      col: col,
      type: ItemType.widget,
      widgetType: 'battery',
    );
  }

  // 創建捷運 widget 的工廠方法
  factory AppItem.mrt({int? size, int row = 0, int col = 0}) {
    final dimensions = GridConfig.getWidgetDimensions('mrt');
    return AppItem(
      name: '捷運',
      icon: Icons.train,
      color: Colors.blue,
      size: size ?? dimensions['width']!,
      row: row,
      col: col,
      type: ItemType.widget,
      widgetType: 'mrt',
    );
  }

  // 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'size': size,
      'row': row,
      'col': col,
      'type': type.index,
      'widgetType': widgetType,
    };
  }

  // 從 JSON 創建 AppItem
  factory AppItem.fromJson(Map<String, dynamic> json) {
    final icon = IconData(
      json['iconCodePoint'] as int,
      fontFamily: json['iconFontFamily'] as String?,
      fontPackage: json['iconFontPackage'] as String?,
    );

    final color = Color(json['colorValue'] as int);
    final type = ItemType.values[json['type'] as int];

    // 檢查是否為特殊 widget 類型
    final widgetType = json['widgetType'] as String?;
    if (widgetType == 'clock') {
      return AppItem.clock(
        size: json['size'] as int,
        row: json['row'] as int,
        col: json['col'] as int,
      );
    } else if (widgetType == 'weather') {
      return AppItem.weather(
        size: json['size'] as int,
        row: json['row'] as int,
        col: json['col'] as int,
      );
    } else if (widgetType == 'battery') {
      return AppItem.battery(
        size: json['size'] as int,
        row: json['row'] as int,
        col: json['col'] as int,
      );
    } else if (widgetType == 'mrt') {
      return AppItem.mrt(
        size: json['size'] as int,
        row: json['row'] as int,
        col: json['col'] as int,
      );
    }

    // 一般 AppItem
    return AppItem(
      name: json['name'] as String,
      icon: icon,
      color: color,
      size: json['size'] as int,
      row: json['row'] as int,
      col: json['col'] as int,
      type: type,
      widgetType: widgetType,
    );
  }
}
