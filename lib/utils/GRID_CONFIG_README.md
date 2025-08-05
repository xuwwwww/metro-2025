# Grid Configuration System

This document explains how to use the centralized grid configuration system for easy customization of grid dimensions and widget sizes.

## Overview

The `GridConfig` class in `lib/utils/grid_config.dart` centralizes all grid-related dimensions and makes them easily adjustable. This allows you to modify grid appearance and behavior without searching through multiple files.

## Configuration Options

### Grid Cell Dimensions
- `cellSize`: Size of each grid cell (default: 72.0)
- `cellSpacing`: Spacing between grid cells (default: 8.0)

### Grid Layout
- `defaultCrossAxisCount`: Number of columns in the grid (default: 4)
- `maxRowCount`: Maximum number of rows (default: 10)
- `topReservedHeight`: Reserved height for header/bottom bar (default: 220.0)

### Icon/Widget Dimensions
- `iconSize`: Size of icons within cells (default: 36.0)
- `iconTextSize`: Font size for icon text (default: 14.0)
- `iconTextSpacing`: Spacing between icon and text (default: 8.0)

### Border and Decoration
- `borderWidth`: Width of grid borders (default: 2.0)
- `borderRadius`: Border radius for icons (default: 16.0)
- `gridBorderRadius`: Border radius for grid cells (default: 18.0)
- `shadowBlurRadius`: Shadow blur radius (default: 8.0)
- `shadowOffset`: Shadow offset (default: Offset(0, 2))

### Widget Specific Sizes
Each widget type has configurable dimensions in grid units:

```dart
static const Map<String, Map<String, int>> widgetSizes = {
  'clock': {'width': 3, 'height': 1},
  'weather': {'width': 2, 'height': 1},
  'battery': {'width': 2, 'height': 1},
  'default': {'width': 1, 'height': 1},
};
```

### Colors
- `defaultGridColor`: Default grid border color
- `defaultIconBgColor`: Default icon background color
- `shadowColor`: Shadow color for icons

## How to Use

### 1. Adjust Grid Size
To change the grid cell size, modify the `cellSize` constant:

```dart
// In lib/utils/grid_config.dart
static const double cellSize = 80.0; // Change from 72.0 to 80.0
```

### 2. Adjust Grid Spacing
To change spacing between cells:

```dart
// In lib/utils/grid_config.dart
static const double cellSpacing = 12.0; // Change from 8.0 to 12.0
```

### 3. Change Number of Columns
To change the grid layout:

```dart
// In lib/utils/grid_config.dart
static const int defaultCrossAxisCount = 5; // Change from 4 to 5
```

### 4. Adjust Widget Sizes
To change widget dimensions:

```dart
// In lib/utils/grid_config.dart
static const Map<String, Map<String, int>> widgetSizes = {
  'clock': {'width': 4, 'height': 1}, // Change clock width from 3 to 4
  'weather': {'width': 3, 'height': 1}, // Change weather width from 2 to 3
  'battery': {'width': 2, 'height': 1},
  'default': {'width': 1, 'height': 1},
};
```

### 5. Adjust Icon Sizes
To change icon appearance:

```dart
// In lib/utils/grid_config.dart
static const double iconSize = 40.0; // Change from 36.0 to 40.0
static const double iconTextSize = 16.0; // Change from 14.0 to 16.0
```

## Helper Methods

The `GridConfig` class provides helper methods for calculations:

- `calculateTotalGridWidth(colCount)`: Calculate total grid width
- `calculateAvailableRows(screenHeight)`: Calculate available rows based on screen height
- `calculateHorizontalPadding(availableWidth, colCount)`: Calculate padding to center grid
- `getWidgetDimensions(widgetType)`: Get dimensions for a specific widget type

## Example Usage

```dart
// Get widget dimensions
final clockDimensions = GridConfig.getWidgetDimensions('clock');
final clockWidth = clockDimensions['width']; // 3
final clockHeight = clockDimensions['height']; // 1

// Calculate grid layout
final totalWidth = GridConfig.calculateTotalGridWidth(4); // 4 columns
final availableRows = GridConfig.calculateAvailableRows(screenHeight);
```

## Benefits

1. **Centralized Configuration**: All grid-related settings in one place
2. **Easy Customization**: Change dimensions without searching multiple files
3. **Consistent Behavior**: All components use the same configuration
4. **Maintainable Code**: Clear separation of configuration from logic
5. **Flexible Widget Sizes**: Each widget type can have different dimensions

## Future Enhancements

The current implementation uses `const` values for performance. For dynamic configuration (e.g., user preferences), the constants could be made non-const and stored in SharedPreferences or a configuration file. 