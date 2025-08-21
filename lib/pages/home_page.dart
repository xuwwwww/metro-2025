import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// import '../widgets/adaptive_text.dart'; // unused
import '../utils/global_login_state.dart';
import 'customize_functions_page.dart';
import 'dart:async'; // Added for Timer
import 'route_info_page.dart'
    show MetroApiService; // Reuse API service for track info
import '../utils/stations_data.dart';
import 'my_account_page.dart';
import '../main.dart';
import 'info_page.dart';
import 'favorites_page.dart';
import '../utils/behavior_tracker.dart';
// removed local upload button from home header; upload available in AI Demo
import 'ai_demo_page.dart';

// 單筆站點到站資訊（本地倒數用）
class StationArrival {
  StationArrival({
    required this.destination,
    required this.lineName,
    required this.baseSeconds,
    required this.baseTimeMs,
    required this.isArriving,
  });
  final String destination;
  final String? lineName; // 所屬路線名稱
  final int baseSeconds; // 當下 API 回傳的倒數秒數（若進站則為0）
  final int baseTimeMs; // 由 NowDateTime 解析出的毫秒時間
  final bool isArriving; // 是否為「列車進站」狀態
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 已選擇的功能
  List<FunctionItem> selectedFunctions = [];

  // 常用站點數據（在 fetch 前顯示 --:--）
  List<Map<String, dynamic>> frequentStations = [
    {
      'name': '台北車站',
      'timeToDirection1': '--:--',
      'timeToDirection2': '--:--',
      'destination1': '',
      'destination2': '',
    },
    {
      'name': '西門',
      'timeToDirection1': '--:--',
      'timeToDirection2': '--:--',
      'destination1': '',
      'destination2': '',
    },
  ];
  // 使用者自訂常用站點名單（僅名稱，用於編輯頁面）
  List<String> favoriteStationNames = ['台北車站', '西門'];

  // 最近的站點：已移除（僅保留常用站點）

  // 模擬到站時間計時器
  Timer? _timer;
  int _currentSecond = 0;
  // 30秒輪詢計時器
  Timer? _pollTimer;
  // 5分鐘預測計時器
  Timer? _predictTimer;
  // 是否已載入進站資料（可用於日後顯示loading狀態）
  // ignore: unused_field
  bool _arrivalsLoaded = false;
  // 以站名為鍵，保存兩個方向的倒數（秒）與目的地
  final Map<String, List<StationArrival>> stationArrivals = {};
  // 最近一次抓取的時間戳，用於跨頁計算（毫秒）
  // ignore: unused_field
  int _lastFetchMs = 0;
  bool _isFetching = false;
  // AI 預測 top2
  List<String> _predictedTop2 = [];

  // 最新消息數據
  List<Map<String, String>> newsItems = [
    {
      'title': 'Family Nart x 台北捷運',
      'content': 'Lorem ipsum dolor sit amet consectetur adipiscing elit',
      'image': 'assets/images/news1.jpg',
    },
    {
      'title': '宣導訊息',
      'content': 'Lorem ipsum dolor sit amet consectetur adipiscing elit',
      'image': 'assets/images/news2.jpg',
    },
    {
      'title': 'Family Nart x 台北捷運',
      'content': 'Lorem ipsum dolor sit amet consectetur adipiscing elit',
      'image': 'assets/images/news3.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Behavior tracking: demo hooks
    BehaviorTracker().init();
    _loadSelectedFunctions();
    _loadDefaultFunctions();
    _loadPredictedTop2();
    _startCountdownTimer();
    _startPollingArrivals();
    _startPredictPolling();
  }

  Future<void> _loadPredictedTop2() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('predicted_top2');
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> j = jsonDecode(raw);
        final List<dynamic> arr = (j['stations'] as List?) ?? const [];
        final List<String> list = arr
            .map((e) => (e ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          setState(() {
            _predictedTop2 = list.take(2).toList();
            // 將首頁顯示名單改為預測 top2
            frequentStations = _predictedTop2
                .map(
                  (name) => {
                    'name': name,
                    'timeToDirection1': '--:--',
                    'timeToDirection2': '--:--',
                    'destination1': '',
                    'destination2': '',
                  },
                )
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  // 會員資訊橫幅
  Widget _buildMemberBanner() {
    final bool isLoggedIn =
        GlobalLoginState.isLoggedIn && GlobalLoginState.userName.isNotEmpty;
    final String name = isLoggedIn ? GlobalLoginState.userName : '未登入';
    final String uid = GlobalLoginState.currentUid ?? '—';
    final Color border = const Color(0xFF114D4D);
    final Color bg = isLoggedIn
        ? const Color(0xFF1F3B45)
        : const Color(0xFF2A3A4A);
    final Color accent = isLoggedIn ? const Color(0xFF26C6DA) : Colors.grey;
    return InkWell(
      onTap: () {
        // 直接切換底部分頁到「我的帳戶」，並自動開啟「帳戶設定」
        final stateKey = MainScaffold.globalKey;
        final currentContext = stateKey.currentContext;
        if (currentContext != null) {
          (stateKey.currentState as dynamic).selectTab(
            4,
            openAccountDialog: true,
          );
        } else {
          // 後備：若無法取得 globalKey，退回 push
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MyAccountPage(autoOpenAccountDialog: true),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: accent.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    isLoggedIn ? '已登入' : '尚未登入',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'UID: $uid',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    _predictTimer?.cancel();
    super.dispose();
  }

  //每次抓取後會把「抓取時間戳 fetchedAt」與各站兩方向的秒數和目的地，
  //序列化成 JSON 存到 SharedPreferences 鍵 latest_arrivals。
  //其他頁面可取出 fetchedAt 與各站的 seconds，用「現在時間 - fetchedAt」
  //推算剩餘秒數（小於等於 0 視為已進站）

  // 每秒倒數計時器（本地遞減，不打API）
  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _currentSecond = (_currentSecond + 1) % 60;
        _updateStationTimes();
      });
    });
  }

  // 每30秒抓取一次最新進站資料（不阻塞首頁顯示）
  void _startPollingArrivals() {
    // 先立即抓一次，之後每30秒再抓
    _fetchArrivals();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _fetchArrivals();
    });
  }

  // 每5分鐘觸發一次預測（目前僅示意：實際呼叫可抽成服務）
  void _startPredictPolling() {
    _predictTimer?.cancel();
    _predictTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        // 這裡可加入「有移動才預測」的條件（例如比較最近樣本的距離）
        // 先讀取 SharedPreferences 是否已有預測結果；若需要可在此觸發新的預測
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('predicted_top2');
        if (raw != null && raw.isNotEmpty) {
          final Map<String, dynamic> j = jsonDecode(raw);
          final List<dynamic> arr = (j['stations'] as List?) ?? const [];
          final List<String> list = arr
              .map((e) => (e ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
          if (list.isNotEmpty) {
            setState(() {
              _predictedTop2 = list.take(2).toList();
              frequentStations = _predictedTop2
                  .map(
                    (name) => {
                      'name': name,
                      'timeToDirection1': '--:--',
                      'timeToDirection2': '--:--',
                      'destination1': '',
                      'destination2': '',
                    },
                  )
                  .toList();
            });
            // 立即刷新一次到站資料
            _fetchArrivals();
          }
        }
      } catch (_) {}
    });
  }

  // 取得所有站點的最新列車資訊並更新常用站點的兩個方向（含路線與時間基準）
  Future<void> _fetchArrivals() async {
    try {
      if (_isFetching) return;
      setState(() => _isFetching = true);
      final allTrackData = await MetroApiService.fetchTrackInfo();

      // 針對目前顯示在首頁的常用站點，更新各站兩個最近到站資訊
      final Map<String, List<StationArrival>> nextArrivalsByStation = {};
      for (final station in frequentStations) {
        final String stationName = station['name']?.toString() ?? '';
        if (stationName.isEmpty) continue;

        final filtered = MetroApiService.filterByStation(
          allTrackData,
          stationName,
        );
        // 轉換為可倒數的結構：帶上路線與 NowDateTime 作為基準
        final List<StationArrival> arrivals = filtered
            .map((e) {
              final destination = e['DestinationName']?.toString() ?? '';
              final countDown = e['CountDown']?.toString() ?? '';
              final baseSeconds = _parseCountDownToSeconds(countDown);
              if (baseSeconds == null) return null;
              final nowStr = e['NowDateTime']?.toString() ?? '';
              final baseMs = _parseNowDateTimeMs(nowStr);
              final bool isArriving = countDown.contains('進站');

              // 優先以當前站所屬線來推斷此班次的線別，避免板橋誤判成綠線
              final List<String> stationLines = StationsData.linesForStation(
                stationName,
              );
              String? inferredLine;
              for (final line in stationLines) {
                final d = StationsData.whichDirection(line, destination);
                if (d != null) {
                  inferredLine = line;
                  break;
                }
              }
              inferredLine ??= StationsData.lineForDestination(destination);
              if (inferredLine != null &&
                  stationLines.isNotEmpty &&
                  !stationLines.contains(inferredLine)) {
                // 若與本站線別不符，優先採用本站第一條線作為保守預設
                inferredLine = stationLines.first;
              }

              return StationArrival(
                destination: destination,
                lineName: inferredLine,
                baseSeconds: baseSeconds,
                baseTimeMs: baseMs,
                isArriving: isArriving,
              );
            })
            .whereType<StationArrival>()
            .toList();

        // 依路線分組，每線取前2筆，合併後最多4筆
        final Map<String, List<StationArrival>> byLine = {};
        for (final a in arrivals) {
          final key = a.lineName ?? '未知路線';
          byLine.putIfAbsent(key, () => []).add(a);
        }
        final List<StationArrival> merged = [];
        byLine.forEach((line, list) {
          list.sort((a, b) => a.baseSeconds.compareTo(b.baseSeconds));
          merged.addAll(list.take(2));
        });
        merged.sort((a, b) => a.baseSeconds.compareTo(b.baseSeconds));
        nextArrivalsByStation[stationName] = merged.take(4).toList();
      }

      // 套用至畫面資料
      final fetchMs = DateTime.now().millisecondsSinceEpoch;
      if (!mounted) return;
      setState(() {
        stationArrivals
          ..clear()
          ..addAll(nextArrivalsByStation);
        _applyArrivalsToFrequentStations();
        _arrivalsLoaded = true;
        _lastFetchMs = fetchMs;
        _isFetching = false;
      });
      await _persistArrivals(nextArrivalsByStation, fetchMs);
    } catch (e) {
      // 失敗就保持原樣，下次輪詢再試
      debugPrint('抓取進站資料失敗: $e');
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _persistArrivals(
    Map<String, List<StationArrival>> byStation,
    int fetchMs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> payload = {
      'fetchedAt': fetchMs,
      'stations': byStation.map(
        (k, v) => MapEntry(
          k,
          v
              .map(
                (a) => {
                  'destination': a.destination,
                  'line': a.lineName,
                  'baseSeconds': a.baseSeconds,
                  'baseTimeMs': a.baseTimeMs,
                },
              )
              .toList(),
        ),
      ),
    };
    await prefs.setString('latest_arrivals', jsonEncode(payload));
  }

  // 更新站點時間：根據 baseSeconds 與 NowDateTime（baseTimeMs）推算剩餘秒數
  void _updateStationTimes() {
    setState(() {
      // 常用站：使用 stationArrivals 的資料遞減
      for (int i = 0; i < frequentStations.length; i++) {
        final String stationName =
            frequentStations[i]['name']?.toString() ?? '';
        final arrivals = stationArrivals[stationName];
        if (arrivals == null || arrivals.isEmpty) continue;

        // 逐一計算前兩筆剩餘秒數
        for (int j = 0; j < arrivals.length && j < 2; j++) {
          final a = arrivals[j];
          final remaining = _remainingSeconds(a.baseSeconds, a.baseTimeMs);
          final formatted = remaining <= 0 ? '進站' : _formatSeconds(remaining);
          if (j == 0) {
            frequentStations[i]['destination1'] = a.destination;
            frequentStations[i]['timeToDirection1'] = formatted;
          } else if (j == 1) {
            frequentStations[i]['destination2'] = a.destination;
            frequentStations[i]['timeToDirection2'] = formatted;
          }
        }
      }

      // 已移除最近站點區塊，無需更新
    });
  }

  // 將最新抓取到的資料套用到 frequentStations 顯示
  void _applyArrivalsToFrequentStations() {
    for (int i = 0; i < frequentStations.length; i++) {
      final name = frequentStations[i]['name']?.toString() ?? '';
      final arrivals = stationArrivals[name] ?? const [];
      if (arrivals.isEmpty) continue;

      final first = arrivals.isNotEmpty ? arrivals[0] : null;
      final second = arrivals.length > 1 ? arrivals[1] : null;

      if (first != null) {
        final r1 = _remainingSeconds(first.baseSeconds, first.baseTimeMs);
        frequentStations[i]['destination1'] = first.destination;
        frequentStations[i]['timeToDirection1'] = r1 <= 0
            ? '進站'
            : _formatSeconds(r1);
      }
      if (second != null) {
        final r2 = _remainingSeconds(second.baseSeconds, second.baseTimeMs);
        frequentStations[i]['destination2'] = second.destination;
        frequentStations[i]['timeToDirection2'] = r2 <= 0
            ? '進站'
            : _formatSeconds(r2);
      }
    }
  }

  // 利用 NowDateTime 作為基準，計算剩餘秒數
  int _remainingSeconds(int baseSeconds, int baseMs) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsed = ((nowMs - baseMs) / 1000).floor();
    return baseSeconds - elapsed;
  }

  // 解析 NowDateTime: 'yyyy-MM-dd HH:mm:ss' -> 毫秒
  int _parseNowDateTimeMs(String now) {
    try {
      final normalized = now.replaceAll('/', '-');
      final parts = normalized.split(' ');
      if (parts.length != 2) return DateTime.now().millisecondsSinceEpoch;
      final date = parts[0].split('-');
      final time = parts[1].split(':');
      if (date.length != 3 || time.length < 2) {
        return DateTime.now().millisecondsSinceEpoch;
      }
      final year = int.parse(date[0]);
      final month = int.parse(date[1]);
      final day = int.parse(date[2]);
      final hour = int.parse(time[0]);
      final minute = int.parse(time[1]);
      final second = time.length > 2 ? int.parse(time[2]) : 0;
      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
      ).millisecondsSinceEpoch;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  // 兼容舊資料：某些熱重載下的舊物件可能沒有 isArriving 欄位
  bool _safeIsArriving(StationArrival item) {
    try {
      return item.isArriving;
    } catch (_) {
      return false;
    }
  }

  // 解析 API 提供的 CountDown 字串為秒數
  // 支援格式：'MM:SS' 或 包含 '進站' -> 視為 0 秒
  int? _parseCountDownToSeconds(String countDown) {
    if (countDown.contains('進站')) return 0;
    if (countDown.contains(':')) {
      final parts = countDown.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes * 60 + seconds;
      }
    }
    return null; // 無法解析則忽略
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '進站';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}分 ${s.toString().padLeft(2, '0')}秒';
  }

  // 載入已選擇的功能
  Future<void> _loadSelectedFunctions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final functionsJson = prefs.getString('selected_functions');
      final favStationsJson = prefs.getString('favorite_stations');

      if (functionsJson != null) {
        final List<dynamic> functionsList = jsonDecode(functionsJson);
        setState(() {
          selectedFunctions = functionsList
              .map((item) => FunctionItem.fromJson(item))
              .toList();
        });
      }

      if (favStationsJson != null) {
        final List<dynamic> favList = jsonDecode(favStationsJson);
        favoriteStationNames = favList.cast<String>();
        _rebuildFrequentStationsFromNames();
      }
    } catch (e) {
      print('載入已選擇功能失敗: $e');
    }
  }

  // 依 favoriteStationNames 重建 frequentStations（保留目前時間/目的地邏輯）
  void _rebuildFrequentStationsFromNames() {
    // 簡化：依名稱保留既有目的地，若無則給預設方向
    final List<Map<String, dynamic>> rebuilt = [];
    // 強制只保留前兩個常用站點
    favoriteStationNames = favoriteStationNames.take(2).toList();
    for (final name in favoriteStationNames) {
      final existing = frequentStations.firstWhere(
        (e) => e['name'] == name,
        orElse: () => {
          'name': name,
          'timeToDirection1': '--:--',
          'timeToDirection2': '--:--',
          'destination1': '',
          'destination2': '',
        },
      );
      rebuilt.add({...existing});
    }
    setState(() {
      frequentStations = rebuilt;
    });
  }

  Future<void> _saveFavoriteStations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'favorite_stations',
      jsonEncode(favoriteStationNames),
    );
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
          // 頂部標題欄（高度更扁，字更小，右側語言設定）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: const Color(0xFF22303C),
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'MetroTogether',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const AiDemoPage(),
                              ),
                            )
                            .then((_) async {
                              await _loadPredictedTop2();
                              await _fetchArrivals();
                            });
                      },
                      child: const Text(
                        'AI Demo',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF22303C),
                            title: const Text(
                              '語言設定',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                ListTile(
                                  title: Text(
                                    '中文',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    'English',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  '關閉',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.language,
                        color: Colors.white70,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 主要內容區域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMemberBanner(),
                  const SizedBox(height: 16),
                  // 常用站點區塊
                  _buildFrequentStationsSection(),

                  const SizedBox(height: 12),

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '預測要去的站點',
              style: TextStyle(
                color: Color(0xFF114D4D),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _isFetching ? null : _onManualRefresh,
                  icon: _isFetching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF26C6DA),
                          ),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF26C6DA)),
                  tooltip: '刷新',
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    );
                  },
                  child: const Text(
                    '最愛',
                    style: TextStyle(color: Color(0xFF26C6DA)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        Column(
          children: [
            // 顯示預測 top2（若無預測，退回目前名單的前兩個）
            ...List<Map<String, dynamic>>.from(
              frequentStations.isNotEmpty
                  ? frequentStations.take(2)
                  : <Map<String, dynamic>>[
                      if (favoriteStationNames.isNotEmpty)
                        {
                          'name': favoriteStationNames.first,
                          'timeToDirection1': '--:--',
                          'timeToDirection2': '--:--',
                          'destination1': '',
                          'destination2': '',
                        },
                      if (favoriteStationNames.length > 1)
                        {
                          'name': favoriteStationNames[1],
                          'timeToDirection1': '--:--',
                          'timeToDirection2': '--:--',
                          'destination1': '',
                          'destination2': '',
                        },
                    ],
            ).map((station) {
              // 根據站所屬線動態背景（多線時疊加漸層）
              final lines = StationsData.linesForStation(station['name']);
              final List<Color> baseColors = lines
                  .take(2)
                  .map((l) => Color(StationsData.lineColors[l] ?? 0xFF22303C))
                  .toList();
              // 棕線（文湖線）提高不透明度讓顏色更明顯
              final List<Color> bgColors = [];
              for (int i = 0; i < baseColors.length; i++) {
                final String lineName = i < lines.length ? lines[i] : '';
                final double alpha = lineName == '文湖線' ? 0.35 : 0.20;
                bgColors.add(baseColors[i].withValues(alpha: alpha));
              }
              final BoxDecoration boxDeco = bgColors.length <= 1
                  ? BoxDecoration(
                      color: bgColors.isNotEmpty
                          ? bgColors.first
                          : const Color(0xFF22303C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF114D4D),
                        width: 1,
                      ),
                    )
                  : BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: const Alignment(0.866, 0.5), // 60° 斜向
                        colors: bgColors.length == 1
                            ? [bgColors[0], bgColors[0]]
                            : [bgColors[0], bgColors[1]],
                      ),
                      color: const Color(0xFF22303C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(255, 12, 47, 77),
                        width: 1,
                      ),
                    );
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: boxDeco,
                child: Row(
                  children: [
                    // 左側：車站圖標和名稱（縮小寬度）
                    Expanded(
                      flex: 1,
                      child: Row(
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
                          Expanded(
                            child: Text(
                              station['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 右側：兩方向進站資訊（擴大寬度）
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._buildStationArrivalChips(station['name']),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
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

  // 彩色徽章樣式的進站資訊
  Widget _buildArrivalChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 依站名建立多線四方向的進站 chip（依路線上色）
  List<Widget> _buildStationArrivalChips(String stationName) {
    final List<Widget> chips = [];
    final arrivals = stationArrivals[stationName] ?? const [];

    // 先依路線將資料分組
    final Map<String, List<StationArrival>> byLine = {};
    for (final a in arrivals) {
      final line = a.lineName ?? '未知路線';
      byLine.putIfAbsent(line, () => []).add(a);
    }

    // 站名對應的固定兩線（最多兩線），若資料含更多線依最短到站優先挑兩線
    // 優先以本站實際所屬線排序，避免板橋（板南/環狀）錯誤優先綠線
    final stationLines = StationsData.linesForStation(stationName);
    List<String> candidateLines = byLine.keys.toList();
    candidateLines.sort((a, b) {
      final la = byLine[a]!
        ..sort((x, y) => x.baseSeconds.compareTo(y.baseSeconds));
      final lb = byLine[b]!
        ..sort((x, y) => x.baseSeconds.compareTo(y.baseSeconds));
      final va = (la.isNotEmpty ? la.first.baseSeconds : 1 << 30);
      final vb = (lb.isNotEmpty ? lb.first.baseSeconds : 1 << 30);
      return va.compareTo(vb);
    });
    candidateLines.sort((a, b) {
      final ia = stationLines.indexOf(a);
      final ib = stationLines.indexOf(b);
      final pa = ia == -1 ? 1 : 0;
      final pb = ib == -1 ? 1 : 0;
      if (pa != pb) return pa.compareTo(pb); // 本站線優先
      final la = byLine[a]!
        ..sort((x, y) => x.baseSeconds.compareTo(y.baseSeconds));
      final lb = byLine[b]!
        ..sort((x, y) => x.baseSeconds.compareTo(y.baseSeconds));
      final va = (la.isNotEmpty ? la.first.baseSeconds : 1 << 30);
      final vb = (lb.isNotEmpty ? lb.first.baseSeconds : 1 << 30);
      return va.compareTo(vb);
    });
    final List<String> chosenLines = candidateLines.take(2).toList();
    // 為每線固定輸出兩個方向（0/1），若缺少資料則視為「進站」佔位
    for (final line in chosenLines) {
      final list = (byLine[line] ?? [])
        ..sort((a, b) => a.baseSeconds.compareTo(b.baseSeconds));
      final color = Color(StationsData.lineColors[line] ?? 0xFF26C6DA);
      // 依方向分組
      final List<StationArrival> dir0 = [];
      final List<StationArrival> dir1 = [];
      for (final item in list) {
        final d = StationsData.whichDirection(line, item.destination);
        if (d == 0)
          dir0.add(item);
        else if (d == 1)
          dir1.add(item);
      }
      dir0.sort((a, b) => a.baseSeconds.compareTo(b.baseSeconds));
      dir1.sort((a, b) => a.baseSeconds.compareTo(b.baseSeconds));
      // 方向0
      if (dir0.isNotEmpty) {
        final item = dir0.first;
        final r = _remainingSeconds(item.baseSeconds, item.baseTimeMs);
        final arriving = (_safeIsArriving(item) || r <= 0);
        final text = arriving
            ? '往 ${item.destination} | 進站中'
            : '往 ${item.destination} | ${_formatSeconds(r)}';
        chips.add(_buildArrivalChip(text, color));
      } else {
        final dirNames = StationsData.directionsForLine(line);
        // 若本站是該線在此方向的終點站，則不顯示該方向的佔位
        final isTerminalForThisDir =
            dirNames.isNotEmpty &&
            dirNames[0].any(
              (n) =>
                  stationName.replaceAll('站', '').contains(n) ||
                  n.contains(stationName.replaceAll('站', '')),
            );
        if (!isTerminalForThisDir) {
          final fallback = dirNames.isNotEmpty && dirNames[0].isNotEmpty
              ? dirNames[0].first
              : '—';
          chips.add(_buildArrivalChip('往 $fallback | 進站中', color));
        }
      }
      chips.add(const SizedBox(height: 8));
      // 方向1
      if (dir1.isNotEmpty) {
        final item = dir1.first;
        final r = _remainingSeconds(item.baseSeconds, item.baseTimeMs);
        final arriving = (_safeIsArriving(item) || r <= 0);
        final text = arriving
            ? '往 ${item.destination} | 進站中'
            : '往 ${item.destination} | ${_formatSeconds(r)}';
        chips.add(_buildArrivalChip(text, color));
      } else {
        final dirNames = StationsData.directionsForLine(line);
        // 若本站是該線在此方向的終點站，則不顯示該方向的佔位
        final isTerminalForThisDir =
            dirNames.length > 1 &&
            dirNames[1].any(
              (n) =>
                  stationName.replaceAll('站', '').contains(n) ||
                  n.contains(stationName.replaceAll('站', '')),
            );
        if (!isTerminalForThisDir) {
          final fallback = dirNames.length > 1 && dirNames[1].isNotEmpty
              ? dirNames[1].first
              : '—';
          chips.add(_buildArrivalChip('往 $fallback | 進站中', color));
        }
      }
      chips.add(const SizedBox(height: 8));
    }

    if (chips.isNotEmpty && chips.last is SizedBox) {
      chips.removeLast();
    }
    // 若沒有資料，顯示「末班車已過」
    if (chips.isEmpty) {
      chips.add(_buildArrivalChip('末班車已過', Colors.grey));
    }
    return chips;
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

  // 手動刷新按鈕
  Future<void> _onManualRefresh() async {
    await _fetchArrivals();
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
    // 導向 資訊 > 一般 分頁，並切到「失物協尋」聊天
    MainScaffold.globalKey.currentState?.selectTab(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 切到資訊 > 一般 > 失物協尋
      final info = InfoPage.globalKey.currentState;
      if (info == null) return;
      info.setState(() {
        info.active = info.active; // 觸發重建
      });
      info.openGeneral(tab: 'lost');
    });
  }

  // 緊急救助
  void _showEmergencyHelp() {
    MainScaffold.globalKey.currentState?.selectTab(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final info = InfoPage.globalKey.currentState;
      if (info == null) return;
      info.setState(() {
        info.active = info.active;
      });
      info.openGeneral(tab: 'emergency');
    });
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
    // 直接導向 資訊 > 共乘
    final stateKey = MainScaffold.globalKey;
    stateKey.currentState?.selectTab(1); // 切到資訊
    // 開啟共乘子頁並自動選單一聊天室（若只有一個）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InfoPage.globalKey.currentState?.openRideshare();
    });
  }

  // 原本的聊天室選擇對話框已改為導向資訊>共乘

  // 編輯常用站點已移至 FavoritesPage
}
