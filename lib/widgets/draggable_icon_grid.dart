import 'package:flutter/material.dart';
import '../models/app_item.dart';
import 'dynamic_widget.dart';

typedef OnTap = void Function(AppItem item);
typedef OnRemove = void Function(int index);
typedef OnReorder = void Function(int from, int to);
typedef OnDragStateChanged = void Function(bool isDragging);

class DraggableIconGrid extends StatefulWidget {
  final List<AppItem> items;
  final int crossAxisCount;
  final OnTap onTap;
  final OnRemove onRemove;
  final OnReorder onReorder;
  final OnDragStateChanged? onDragStateChanged;
  final Color gridColor;
  final Color iconBgColor;

  const DraggableIconGrid({
    super.key,
    required this.items,
    required this.crossAxisCount,
    required this.onTap,
    required this.onRemove,
    required this.onReorder,
    this.onDragStateChanged,
    this.gridColor = const Color(0xFF114D4D),
    this.iconBgColor = const Color(0xFF1A2327),
  });

  @override
  State<DraggableIconGrid> createState() => _DraggableIconGridState();
}

class _DraggableIconGridState extends State<DraggableIconGrid> {
  bool isDragging = false;

  Widget _buildIcon(
    AppItem item, {
    bool dragging = false,
    int size = 1,
    required Color iconBgColor,
  }) {
    const double cellSize = 72.0;
    const double cellSpacing = 8.0;
    final Color bgColor = dragging
        ? item.color.withValues(alpha: 0.18)
        : iconBgColor;

    // 如果是 widget 類型，使用動態 widget
    if (item.type == ItemType.widget) {
      return DynamicWidget(item: item, backgroundColor: bgColor, size: size);
    }

    // 一般應用程式
    return Container(
      width: cellSize * size + cellSpacing * (size - 1),
      height: cellSize,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 36),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: TextStyle(fontSize: 14, color: item.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double cellSize = 72.0;
    const double cellSpacing = 8.0;
    final Size screenSize = MediaQuery.of(context).size;
    final double availableHeight = screenSize.height - 220; // 預留上方標題與下方 bar
    final int colCount = widget.crossAxisCount;

    // 動態計算可容納的列數，確保不超出邊界
    final int rowCount = (availableHeight / (cellSize + cellSpacing))
        .floor()
        .clamp(1, 10);
    final int gridCount = colCount * rowCount;

    // 計算整個網格的總寬度
    final double totalGridWidth =
        colCount * cellSize + (colCount - 1) * cellSpacing;

    // 計算左右邊距來實現置中
    // 使用 LayoutBuilder 來獲取實際可用寬度
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double horizontalPadding = (availableWidth - totalGridWidth) / 2;

        return SingleChildScrollView(
          child: Container(
            width: availableWidth,
            height: rowCount * (cellSize + cellSpacing) - cellSpacing,
            child: Stack(
              children: [
                // 背景網格
                ...List.generate(gridCount, (index) {
                  final int row = index ~/ colCount;
                  final int col = index % colCount;

                  // 檢查這個位置是否被多格 widget 覆蓋（非第一格）
                  bool coveredByWidget = false;
                  for (final item in widget.items) {
                    if (item.row == row &&
                        col > item.col &&
                        col < item.col + item.size &&
                        item.size > 1) {
                      coveredByWidget = true;
                      break;
                    }
                  }

                  // 如果被多格 widget 覆蓋，不顯示邊框
                  if (coveredByWidget) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    left: horizontalPadding + col * (cellSize + cellSpacing),
                    top: row * (cellSize + cellSpacing),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.gridColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.transparent,
                      ),
                    ),
                  );
                }),

                // Widget 項目
                ...widget.items.map((item) {
                  // 檢查這格是否被 widget 佔用（非第一格）
                  bool occupied = false;
                  for (final otherItem in widget.items) {
                    if (otherItem.row == item.row &&
                        item.col >= otherItem.col &&
                        item.col < otherItem.col + otherItem.size &&
                        otherItem.size > 1 &&
                        item.row == otherItem.row &&
                        otherItem.col != item.col) {
                      occupied = true;
                      break;
                    }
                  }

                  if (occupied) {
                    return const SizedBox.shrink();
                  }

                  final int itemIndex = widget.items.indexOf(item);

                  return Positioned(
                    left:
                        horizontalPadding + item.col * (cellSize + cellSpacing),
                    top: item.row * (cellSize + cellSpacing),
                    child: DragTarget<int>(
                      onAcceptWithDetails: (details) {
                        final from = details.data;
                        if (from != itemIndex) {
                          // 計算目標位置
                          final int targetRow = item.row;
                          final int targetCol = item.col;
                          final int targetIndex =
                              targetRow * colCount + targetCol;
                          widget.onReorder(from, targetIndex);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width:
                              cellSize * item.size +
                              cellSpacing * (item.size - 1),
                          height: cellSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: candidateData.isNotEmpty || isDragging
                                  ? Colors.cyanAccent.withValues(alpha: 0.9)
                                  : widget.gridColor.withValues(alpha: 0.3),
                              width: (candidateData.isNotEmpty || isDragging)
                                  ? 3
                                  : 2,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            color: candidateData.isNotEmpty || isDragging
                                ? Colors.cyanAccent.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                          child: LongPressDraggable<int>(
                            data: itemIndex,
                            onDragStarted: () {
                              setState(() {
                                isDragging = true;
                              });
                              widget.onDragStateChanged?.call(true);
                            },
                            onDragEnd: (details) {
                              setState(() {
                                isDragging = false;
                              });
                              widget.onDragStateChanged?.call(false);
                            },
                            feedback: Material(
                              color: Colors.transparent,
                              child: _buildIcon(
                                item,
                                dragging: true,
                                size: item.size,
                                iconBgColor: widget.iconBgColor,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildIcon(
                                item,
                                size: item.size,
                                iconBgColor: widget.iconBgColor,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => widget.onTap(item),
                              child: _buildIcon(
                                item,
                                size: item.size,
                                iconBgColor: widget.iconBgColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),

                // 空的 grid 位置作為拖曳目標
                ...List.generate(gridCount, (index) {
                  final int row = index ~/ colCount;
                  final int col = index % colCount;

                  // 檢查這個位置是否已經有 widget
                  bool hasWidget = false;
                  for (final item in widget.items) {
                    if (item.row == row && item.col == col) {
                      hasWidget = true;
                      break;
                    }
                  }

                  // 檢查這格是否被 widget 佔用（非第一格）
                  bool occupied = false;
                  for (final item in widget.items) {
                    if (item.row == row &&
                        col >= item.col &&
                        col < item.col + item.size &&
                        item.size > 1 &&
                        row == item.row &&
                        item.col != col) {
                      occupied = true;
                      break;
                    }
                  }

                  if (hasWidget || occupied) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    left: horizontalPadding + col * (cellSize + cellSpacing),
                    top: row * (cellSize + cellSpacing),
                    child: DragTarget<int>(
                      onAcceptWithDetails: (details) {
                        final from = details.data;
                        widget.onReorder(from, index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: candidateData.isNotEmpty
                                  ? Colors.cyanAccent.withValues(alpha: 0.7)
                                  : widget.gridColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            color: candidateData.isNotEmpty
                                ? Colors.cyanAccent.withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
