import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/adaptive_text.dart';

class CustomizeFunctionsPage extends StatefulWidget {
  final List<FunctionItem> selectedFunctions;
  final Function(List<FunctionItem>) onFunctionsChanged;

  const CustomizeFunctionsPage({
    Key? key,
    required this.selectedFunctions,
    required this.onFunctionsChanged,
  }) : super(key: key);

  @override
  State<CustomizeFunctionsPage> createState() => _CustomizeFunctionsPageState();
}

class _CustomizeFunctionsPageState extends State<CustomizeFunctionsPage> {
  late List<FunctionItem> selectedFunctions;
  bool isEditMode = false;

  // 營運資訊功能
  final List<FunctionItem> operationalFunctions = [
    FunctionItem(
      id: 'route_info',
      name: '路線資訊',
      icon: Icons.route,
      category: 'operational',
    ),
    FunctionItem(
      id: 'schedule',
      name: '時刻表',
      icon: Icons.schedule,
      category: 'operational',
    ),
    FunctionItem(
      id: 'station_info',
      name: '車站資訊',
      icon: Icons.location_on,
      category: 'operational',
    ),
    FunctionItem(
      id: 'fare_info',
      name: '票價資訊',
      icon: Icons.attach_money,
      category: 'operational',
    ),
    FunctionItem(
      id: 'service_status',
      name: '服務狀態',
      icon: Icons.info,
      category: 'operational',
    ),
    FunctionItem(
      id: 'news',
      name: '最新消息',
      icon: Icons.newspaper,
      category: 'operational',
    ),
  ];

  // 會員專屬功能
  final List<FunctionItem> memberFunctions = [
    FunctionItem(
      id: 'member_card',
      name: '會員卡',
      icon: Icons.credit_card,
      category: 'member',
    ),
    FunctionItem(
      id: 'points',
      name: '積分查詢',
      icon: Icons.stars,
      category: 'member',
    ),
    FunctionItem(
      id: 'benefits',
      name: '專屬優惠',
      icon: Icons.local_offer,
      category: 'member',
    ),
    FunctionItem(
      id: 'history',
      name: '使用記錄',
      icon: Icons.history,
      category: 'member',
    ),
    FunctionItem(
      id: 'settings',
      name: '個人設定',
      icon: Icons.settings,
      category: 'member',
    ),
    FunctionItem(
      id: 'profile',
      name: '個人資料',
      icon: Icons.person,
      category: 'member',
    ),
  ];

  // 溫馨服務功能
  final List<FunctionItem> warmServiceFunctions = [
    FunctionItem(
      id: 'lost_found',
      name: '遺失物協尋',
      icon: Icons.search,
      category: 'warm',
    ),
    FunctionItem(
      id: 'emergency',
      name: '緊急救助',
      icon: Icons.emergency,
      category: 'warm',
    ),
    FunctionItem(
      id: 'accessibility',
      name: '無障礙服務',
      icon: Icons.accessibility,
      category: 'warm',
    ),
    FunctionItem(
      id: 'feedback',
      name: '意見回饋',
      icon: Icons.feedback,
      category: 'warm',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedFunctions = List.from(widget.selectedFunctions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header（左關閉、中標題、右編輯/儲存）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF22303C),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        '關閉',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      '自訂常用功能',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() => isEditMode = !isEditMode);
                        if (!isEditMode) _saveFunctions();
                      },
                      child: Text(
                        isEditMode ? '儲存' : '編輯',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 主要內容區域
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF22303C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 已選擇區塊
                      _buildSelectedSection(),
                      const SizedBox(height: 24),

                      // 營運資訊區塊
                      _buildFunctionSection('營運資訊', operationalFunctions),
                      const SizedBox(height: 24),

                      // 會員專屬區塊
                      _buildFunctionSection('會員專屬', memberFunctions),
                      const SizedBox(height: 24),

                      // 溫馨服務區塊
                      _buildFunctionSection('溫馨服務', warmServiceFunctions),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 已選擇區塊
  Widget _buildSelectedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '已選擇',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFF2A3A4A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF114D4D)),
          ),
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              if (index < selectedFunctions.length) {
                final function = selectedFunctions[index];
                return Container(
                  width: 86,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A4A5A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              function.icon,
                              color: const Color(0xFF26C6DA),
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              function.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isEditMode)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeFunction(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                return Container(
                  width: 86,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3A4A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF26C6DA),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Color(0xFF26C6DA), size: 24),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // 功能區塊
  Widget _buildFunctionSection(String title, List<FunctionItem> functions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.5,
          ),
          itemCount: functions.length,
          itemBuilder: (context, index) {
            final function = functions[index];
            final isSelected = selectedFunctions.any(
              (item) => item.id == function.id,
            );

            return GestureDetector(
              onTap: () {
                if (isEditMode) _toggleFunction(function);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF26C6DA).withOpacity(0.2)
                      : const Color(0xFF3A4A5A),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF26C6DA), width: 2)
                      : null,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF26C6DA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(function.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        function.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 切換功能選擇狀態
  void _toggleFunction(FunctionItem function) {
    setState(() {
      final existingIndex = selectedFunctions.indexWhere(
        (item) => item.id == function.id,
      );

      if (existingIndex != -1) {
        selectedFunctions.removeAt(existingIndex);
      } else if (selectedFunctions.length < 4) {
        selectedFunctions.add(function);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('最多只能選擇4個功能')));
      }
    });
  }

  // 移除已選擇的功能
  void _removeFunction(int index) {
    setState(() {
      selectedFunctions.removeAt(index);
    });
  }

  // 保存功能選擇
  void _saveFunctions() {
    widget.onFunctionsChanged(selectedFunctions);
    _saveToLocalStorage();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('功能設定已保存')));
  }

  // 保存到本地存儲
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final functionsJson = selectedFunctions.map((f) => f.toJson()).toList();
      await prefs.setString('selected_functions', jsonEncode(functionsJson));
    } catch (e) {
      print('保存功能設定失敗: $e');
    }
  }
}

// 功能項目模型
class FunctionItem {
  final String id;
  final String name;
  final IconData icon;
  final String category;

  FunctionItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'category': category,
    };
  }

  factory FunctionItem.fromJson(Map<String, dynamic> json) {
    return FunctionItem(
      id: json['id'],
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      category: json['category'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FunctionItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
