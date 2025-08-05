import 'package:flutter/material.dart';

/// Grid configuration class for managing all grid-related dimensions
class GridConfig {
  // Grid cell dimensions
  static const double cellSize = 72.0;
  static const double cellSpacing = 8.0;

  // Grid layout
  static const int defaultCrossAxisCount = 4;
  static const int maxRowCount = 10;
  static const double topReservedHeight = 220.0; // 預留上方標題與下方 bar

  // Icon/Widget dimensions
  static const double iconSize = 36.0;
  static const double iconTextSize = 14.0;
  static const double iconTextSpacing = 8.0;

  // Border and decoration
  static const double borderWidth = 2.0;
  static const double borderRadius = 16.0;
  static const double gridBorderRadius = 18.0;
  static const double shadowBlurRadius = 8.0;
  static const Offset shadowOffset = Offset(0, 2);

  // Widget specific sizes (in grid units)
  static const Map<String, Map<String, int>> widgetSizes = {
    'clock': {'width': 4, 'height': 1},
    'weather': {'width': 2, 'height': 1},
    'battery': {'width': 2, 'height': 1},
    'default': {'width': 1, 'height': 1},
  };

  // Colors
  static const Color defaultGridColor = Color(0xFF114D4D);
  static const Color defaultIconBgColor = Color(0xFF1A2327);
  static const Color shadowColor = Colors.black26;

  /// Get widget dimensions by type
  static Map<String, int> getWidgetDimensions(String widgetType) {
    return widgetSizes[widgetType] ?? widgetSizes['default']!;
  }

  /// Calculate total grid width for given column count
  static double calculateTotalGridWidth(int colCount) {
    return colCount * cellSize + (colCount - 1) * cellSpacing;
  }

  /// Calculate available rows based on screen height
  static int calculateAvailableRows(double screenHeight) {
    final double availableHeight = screenHeight - topReservedHeight;
    return (availableHeight / (cellSize + cellSpacing)).floor().clamp(
      1,
      maxRowCount,
    );
  }

  /// Calculate horizontal padding to center the grid
  static double calculateHorizontalPadding(
    double availableWidth,
    int colCount,
  ) {
    final double totalGridWidth = calculateTotalGridWidth(colCount);
    return (availableWidth - totalGridWidth) / 2;
  }

  /// Update grid cell size (affects all grid calculations)
  static void updateCellSize(double newCellSize) {
    // Note: This would require making the constants non-const
    // For now, this is a placeholder for future dynamic configuration
    print('Cell size updated to: $newCellSize');
  }

  /// Update grid spacing (affects all grid calculations)
  static void updateCellSpacing(double newCellSpacing) {
    // Note: This would require making the constants non-const
    // For now, this is a placeholder for future dynamic configuration
    print('Cell spacing updated to: $newCellSpacing');
  }

  /// Update widget dimensions for a specific type
  static void updateWidgetDimensions(String widgetType, int width, int height) {
    // Note: This would require making the map non-const
    // For now, this is a placeholder for future dynamic configuration
    print('Widget $widgetType dimensions updated to: ${width}x$height');
  }
}
