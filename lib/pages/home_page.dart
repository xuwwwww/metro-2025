import 'package:flutter/material.dart';
import '../widgets/draggable_icon_grid.dart';
import '../widgets/item_selector.dart';
import '../models/app_item.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int crossAxisCount = 4;
  List<AppItem> items = [];
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    // 預設依序分配 row/col
    final defaultItems = [
      AppItem(name: 'App1', icon: Icons.apps, color: Colors.teal, size: 1),
      AppItem(name: 'App2', icon: Icons.star, color: Colors.blue, size: 1),
      AppItem.clock(size: 3), // 使用時鐘 widget
      AppItem(name: 'App3', icon: Icons.home, color: Colors.purple, size: 1),
    ];
    int curRow = 0, curCol = 0;
    for (var item in defaultItems) {
      if (curCol + item.size > crossAxisCount) {
        curRow++;
        curCol = 0;
      }
      item.row = curRow;
      item.col = curCol;
      curCol += item.size;
    }
    items = defaultItems;
  }

  void _addItem(AppItem item) {
    setState(() {
      // 找到第一個可用的位置
      int curRow = 0, curCol = 0;
      bool placed = false;

      while (!placed) {
        // 檢查是否有足夠空間放置
        if (curCol + item.size > crossAxisCount) {
          curRow++;
          curCol = 0;
        }

        // 檢查是否與現有項目重疊
        bool canPlace = true;
        for (final existingItem in items) {
          for (int dx = 0; dx < item.size; dx++) {
            for (int odx = 0; odx < existingItem.size; odx++) {
              if (curRow == existingItem.row &&
                  (curCol + dx) == (existingItem.col + odx)) {
                canPlace = false;
                break;
              }
            }
            if (!canPlace) break;
          }
          if (!canPlace) break;
        }

        if (canPlace) {
          item.row = curRow;
          item.col = curCol;
          items.add(item);
          placed = true;
        } else {
          curCol++;
          if (curCol >= crossAxisCount) {
            curRow++;
            curCol = 0;
          }
        }
      }
    });
  }

  void _openDetail(AppItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailPage(item: item)),
    );
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  // from: index in items, to: gridIndex
  void _onReorder(int from, int toGridIndex) {
    setState(() {
      // 計算目標 row/col
      int row = toGridIndex ~/ crossAxisCount;
      int col = toGridIndex % crossAxisCount;
      final moving = items[from];
      // 檢查是否超出邊界
      if (col + moving.size > crossAxisCount) return;
      // 檢查是否重疊
      for (var i = 0; i < items.length; i++) {
        if (i == from) continue;
        final other = items[i];
        for (int dx = 0; dx < moving.size; dx++) {
          for (int odx = 0; odx < other.size; odx++) {
            if (row == other.row && (col + dx) == (other.col + odx)) {
              return; // 有重疊
            }
          }
        }
      }
      moving.row = row;
      moving.col = col;
    });
  }

  void _onDragStateChanged(bool dragging) {
    setState(() {
      isDragging = dragging;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '主頁',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF26C6DA),
                        ),
                      ),
                      ItemSelector(onAdd: (item) => _addItem(item)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF22303C),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Color(0xFF114D4D), width: 2),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: DraggableIconGrid(
                        items: items,
                        crossAxisCount: crossAxisCount,
                        onTap: _openDetail,
                        onRemove: _removeItem,
                        onReorder: _onReorder,
                        onDragStateChanged: _onDragStateChanged,
                        gridColor: const Color(0xFF114D4D),
                        iconBgColor: const Color(0xFF1A2327),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 移除區域（顯示在 navigation bar 之前）
          if (isDragging)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DragTarget<int>(
                onAcceptWithDetails: (details) {
                  final from = details.data;
                  _removeItem(from);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    height: 80, // navigation bar 高度
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? Colors.red.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.3),
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? Colors.red
                            : Colors.red.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '拖曳到此處移除',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
