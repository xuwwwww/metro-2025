import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/adaptive_text.dart';
import '../utils/global_login_state.dart';
import 'chat_page.dart';
import 'customize_functions_page.dart';
import 'dart:async'; // Added for Timer

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 已選擇的功能
  List<FunctionItem> selectedFunctions = [];

  // 常用站點數據
  List<Map<String, dynamic>> frequentStations = [
    {
      'name': '台北車站',
      'timeToDirection1': '2分 30秒',
      'timeToDirection2': '4分 15秒',
      'destination1': '淡水',
      'destination2': '南港',
    },
    {
      'name': '西門站',
      'timeToDirection1': '5分 15秒',
      'timeToDirection2': '3分 45秒',
      'destination1': '板橋',
      'destination2': '淡水',
    },
  ];

  // 最近的站點數據
  Map<String, dynamic> nearestStation = {
    'name': '忠孝復興站',
    'timeToDirection1': '1分 45秒',
    'timeToDirection2': '3分 20秒',
    'destination1': '南港',
    'destination2': '淡水',
  };

  // 模擬到站時間計時器
  Timer? _timer;
  int _currentSecond = 0;

  // 最新消息數據
  List<Map<String, String>> newsItems = [
    {
      'title': 'Family Mart x 台北捷運',
      'content': 'Lorem ipsum dolor sit amet consectetur adipiscing elit',
      'image': 'assets/images/news1.jpg',
    },
    {
      'title': '宣導訊息',
      'content': 'Lorem ipsum dolor sit amet consectetur adipiscing elit',
      'image': 'assets/images/news2.jpg',
    },
    {
      'title': 'Family Mart x 台北捷',
      'content': 'Lorem ipsum dolor sit amet consectetur adipiscing elit',
      'image': 'assets/images/news3.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedFunctions();
    _loadDefaultFunctions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 開始計時器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSecond = (_currentSecond + 1) % 60;
        _updateStationTimes();
      });
    });
  }

  // 更新站點時間
  void _updateStationTimes() {
    // 模擬時間變化
    setState(() {
      // 更新常用站點時間
      for (int i = 0; i < frequentStations.length; i++) {
        int baseMinutes1 = i == 0 ? 2 : 5;
        int baseSeconds1 = i == 0 ? 30 : 15;
        int adjustedSeconds1 = (baseSeconds1 + _currentSecond) % 60;
        int adjustedMinutes1 =
            baseMinutes1 + ((baseSeconds1 + _currentSecond) ~/ 60);

        int baseMinutes2 = i == 0 ? 4 : 3;
        int baseSeconds2 = i == 0 ? 15 : 45;
        int adjustedSeconds2 = (baseSeconds2 + _currentSecond) % 60;
        int adjustedMinutes2 =
            baseMinutes2 + ((baseSeconds2 + _currentSecond) ~/ 60);

        frequentStations[i]['timeToDirection1'] =
            '${adjustedMinutes1}分 ${adjustedSeconds1.toString().padLeft(2, '0')}秒';
        frequentStations[i]['timeToDirection2'] =
            '${adjustedMinutes2}分 ${adjustedSeconds2.toString().padLeft(2, '0')}秒';
      }

      // 更新最近站點時間
      int baseMinutes1 = 1;
      int baseSeconds1 = 45;
      int adjustedSeconds1 = (baseSeconds1 + _currentSecond) % 60;
      int adjustedMinutes1 =
          baseMinutes1 + ((baseSeconds1 + _currentSecond) ~/ 60);

      int baseMinutes2 = 3;
      int baseSeconds2 = 20;
      int adjustedSeconds2 = (baseSeconds2 + _currentSecond) % 60;
      int adjustedMinutes2 =
          baseMinutes2 + ((baseSeconds2 + _currentSecond) ~/ 60);

      nearestStation['timeToDirection1'] =
          '${adjustedMinutes1}分 ${adjustedSeconds1.toString().padLeft(2, '0')}秒';
      nearestStation['timeToDirection2'] =
          '${adjustedMinutes2}分 ${adjustedSeconds2.toString().padLeft(2, '0')}秒';
    });
  }

  // 載入已選擇的功能
  Future<void> _loadSelectedFunctions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final functionsJson = prefs.getString('selected_functions');

      if (functionsJson != null) {
        final List<dynamic> functionsList = jsonDecode(functionsJson);
        setState(() {
          selectedFunctions = functionsList
              .map((item) => FunctionItem.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('載入已選擇功能失敗: $e');
    }
  }

  // 載入預設功能
  void _loadDefaultFunctions() {
    if (selectedFunctions.isEmpty) {
      setState(() {
        selectedFunctions = [
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
            id: 'chat',
            name: '聊天',
            icon: Icons.chat,
            category: 'member',
          ),
          FunctionItem(
            id: 'member',
            name: '會員',
            icon: Icons.person,
            category: 'member',
          ),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 頂部標題欄
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: const Color(0xFF22303C),
            child: const Center(
              child: Text(
                '台北捷運',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 主要內容區域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 常用站點區塊
                  _buildFrequentStationsSection(),

                  const SizedBox(height: 24),

                  // 常用功能區塊
                  _buildFrequentFunctionsSection(),

                  const SizedBox(height: 24),

                  // 最新消息區塊
                  _buildLatestNewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 常用站點區塊
  Widget _buildFrequentStationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '常用站點',
          style: TextStyle(
            color: Color(0xFF114D4D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Column(
          children: [
            // 前兩個常用站點
            ...frequentStations.map((station) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF22303C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF114D4D), width: 1),
                ),
                child: Row(
                  children: [
                    // 左側：車站圖標和名稱
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A4A5A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.train,
                                  color: Color(0xFF26C6DA),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                station['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26C6DA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${station['timeToDirection1']} 往 ${station['destination1']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26C6DA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${station['timeToDirection2']} 往 ${station['destination2']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 右側：目的地
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A4A5A),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '往 ${station['destination1']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A4A5A),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '往 ${station['destination2']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            // 最近的站點
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF22303C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF114D4D), width: 1),
              ),
              child: Row(
                children: [
                  // 左側：車站圖標和名稱
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A4A5A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.train,
                                color: Color(0xFF26C6DA),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              nearestStation['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF26C6DA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${nearestStation['timeToDirection1']!} 往 ${nearestStation['destination1']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF26C6DA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${nearestStation['timeToDirection2']!} 往 ${nearestStation['destination2']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 右側：目的地
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A4A5A),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '往 ${nearestStation['destination1']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A4A5A),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '往 ${nearestStation['destination2']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 常用功能區塊
  Widget _buildFrequentFunctionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '常用功能',
              style: TextStyle(
                color: Color(0xFF114D4D),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showCustomizeFunctions(),
              child: const Text(
                '更多功能',
                style: TextStyle(color: Color(0xFF26C6DA), fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 功能按鈕網格
        Row(
          children: [
            for (int i = 0; i < 4; i++)
              Expanded(
                child: i < selectedFunctions.length
                    ? _buildSelectedFunctionButton(selectedFunctions[i], i)
                    : _buildEmptyFunctionButton(),
              ),
          ],
        ),
      ],
    );
  }

  // 已選擇的功能按鈕
  Widget _buildSelectedFunctionButton(FunctionItem function, int index) {
    return GestureDetector(
      onTap: () => _handleFunctionTap(function),
      onLongPress: () => _showRemoveDialog(index),
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF22303C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF114D4D), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(function.icon, color: const Color(0xFF26C6DA), size: 24),
            const SizedBox(height: 4),
            Text(
              function.name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 空的功能按鈕
  Widget _buildEmptyFunctionButton() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCCCCCC),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Color(0xFF999999), size: 24),
      ),
    );
  }

  // 最新消息區塊
  Widget _buildLatestNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最新消息',
          style: TextStyle(
            color: Color(0xFF114D4D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: newsItems.length,
            itemBuilder: (context, index) {
              final news = newsItems[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF22303C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF114D4D), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 圖片佔位符
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A4A5A),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 40),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            news['content']!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 顯示自訂功能頁面
  void _showCustomizeFunctions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomizeFunctionsPage(
          selectedFunctions: selectedFunctions,
          onFunctionsChanged: (functions) {
            setState(() {
              selectedFunctions = functions;
            });
          },
        ),
      ),
    );
  }

  // 處理功能點擊
  void _handleFunctionTap(FunctionItem function) {
    switch (function.id) {
      case 'lost_found':
        _showLostAndFound();
        break;
      case 'emergency':
        _showEmergencyHelp();
        break;
      case 'chat':
        _openChat();
        break;
      case 'member':
        _showMemberInfo();
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${function.name} 功能開發中')));
    }
  }

  // 顯示移除對話框
  void _showRemoveDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '移除功能',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '確定要移除「${selectedFunctions[index].name}」嗎？',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                selectedFunctions.removeAt(index);
              });
              Navigator.pop(context);
              _saveSelectedFunctions();
            },
            child: const Text('確定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 保存已選擇的功能
  Future<void> _saveSelectedFunctions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final functionsJson = selectedFunctions.map((f) => f.toJson()).toList();
      await prefs.setString('selected_functions', jsonEncode(functionsJson));
    } catch (e) {
      print('保存已選擇功能失敗: $e');
    }
  }

  // 遺失物協尋
  void _showLostAndFound() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '遺失物協尋',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Text('遺失物協尋服務', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 緊急救助
  void _showEmergencyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '緊急救助',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Text('緊急救助服務', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 會員資訊
  void _showMemberInfo() {
    final userName = GlobalLoginState.userName.isNotEmpty
        ? GlobalLoginState.userName
        : '未登入';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          '會員資訊',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '顯示名稱: $userName',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 打開聊天
  void _openChat() {
    // 檢查用戶是否已登入
    if (!GlobalLoginState.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先登入後再使用聊天功能')));
      return;
    }

    // 顯示聊天室選擇對話框
    _showRoomSelectionDialog();
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
}
