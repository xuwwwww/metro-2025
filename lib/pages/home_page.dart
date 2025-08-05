import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/draggable_icon_grid.dart';
import '../widgets/item_selector.dart';
import '../models/app_item.dart';
import '../utils/grid_config.dart';
import '../widgets/adaptive_text.dart';
import 'detail_page.dart';
import 'chat_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int crossAxisCount = GridConfig.defaultCrossAxisCount;
  List<AppItem> items = [];
  bool isDragging = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedLayout();
  }

  // 載入保存的佈局
  Future<void> _loadSavedLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLayout = prefs.getString('home_page_layout');

      if (savedLayout != null) {
        final List<dynamic> savedItems = jsonDecode(savedLayout);
        setState(() {
          items = savedItems.map((item) => AppItem.fromJson(item)).toList();
        });
      } else {
        // 如果沒有保存的佈局，使用預設佈局
        _loadDefaultLayout();
      }
    } catch (e) {
      print('載入佈局失敗: $e');
      _loadDefaultLayout();
    }
  }

  // 載入預設佈局
  void _loadDefaultLayout() {
    final defaultItems = [
      AppItem(name: 'App1', icon: Icons.apps, color: Colors.teal, size: 1),
      AppItem(name: '聊天', icon: Icons.chat, color: Colors.green, size: 1),
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
    setState(() {
      items = defaultItems;
    });
  }

  // 保存佈局到本地存儲
  Future<void> _saveLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutJson = jsonEncode(
        items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('home_page_layout', layoutJson);
    } catch (e) {
      print('保存佈局失敗: $e');
    }
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
    // 保存佈局
    _saveLayout();
  }

  void _openDetail(AppItem item) {
    // 如果是聊天圖標，打開聊天頁面
    if (item.name == '聊天') {
      // 檢查用戶是否已登入
      if (!GlobalLoginState.isLoggedIn) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('請先登入後再使用聊天功能')));
        return;
      }

      // 顯示聊天室選擇對話框
      _showRoomSelectionDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailPage(item: item)),
      );
    }
  }

  // 顯示聊天室選擇對話框
  void _showRoomSelectionDialog() async {
    try {
      // 獲取用戶有權限的聊天室
      final userDoc = await _firestore
          .collection('users')
          .doc(GlobalLoginState.currentUid)
          .get();
      final permissions = List<String>.from(
        userDoc.data()?['permissions'] ?? [],
      );

      if (permissions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('您還沒有加入任何聊天室，請先在設定中選擇聊天室')),
        );
        return;
      }

      // 顯示聊天室選擇對話框
      final selectedRoom = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF22303C),
          title: const Text(
            '選擇聊天室',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: permissions.length,
              itemBuilder: (context, index) {
                final roomId = permissions[index];
                return ListTile(
                  title: Text(
                    roomId,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(roomId),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );

      if (selectedRoom != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              currentUid: GlobalLoginState.currentUid!,
              roomId: selectedRoom,
              profile: {
                'displayName': GlobalLoginState.userName,
                'avatarUrl': '',
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('載入聊天室失敗: $e')));
    }
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
    // 保存佈局
    _saveLayout();
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
    // 保存佈局
    _saveLayout();
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
                      const AdaptiveTitle('主頁'),
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
                        gridColor: GridConfig.defaultGridColor,
                        iconBgColor: GridConfig.defaultIconBgColor,
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
                      child: AdaptiveText(
                        '拖曳到此處移除',
                        fontSizeMultiplier: 1.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
