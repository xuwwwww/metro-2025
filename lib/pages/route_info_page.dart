import 'package:flutter/material.dart';
import '../widgets/adaptive_text.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// === 台北捷運 API 服務 ===
class MetroApiService {
  static const String endpoint = 'https://api.metro.taipei/metroapi/TrackInfo.asmx';
  // === YouBike 端點 ===
  static const String ubikeEndpoint = 'https://api.metro.taipei/MetroAPI/UBike.asmx';
  static const Map<String, String> headers = {
    'Content-Type': 'text/xml; charset=utf-8'
  };

  // 模擬帳號密碼 - 實際使用時請從環境變數或安全配置讀取
  static const String username = 'MetroTaipeiHackathon2025';  // TODO: 替換為實際帳號
  static const String password = 'bZ0dQG96N';  // TODO: 替換為實際密碼

  static Future<List<Map<String, dynamic>>> fetchTrackInfo() async {
    final body = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <getTrackInfo xmlns="http://tempuri.org/">
      <userName>$username</userName>
      <passWord>$password</passWord>
    </getTrackInfo>
  </soap:Body>
</soap:Envelope>''';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: utf8.encode(body),
      );

      if (response.statusCode == 200) {
        String responseText = utf8.decode(response.bodyBytes);
        print('原始回應長度: ${responseText.length}');
        
        // 提取 JSON 部分（在 XML 之前）
        String jsonPart = '';
        if (responseText.startsWith('[')) {
          // 找到 JSON 陣列的結束位置
          int xmlStartIndex = responseText.indexOf('<?xml');
          if (xmlStartIndex != -1) {
            jsonPart = responseText.substring(0, xmlStartIndex).trim();
          } else {
            jsonPart = responseText.trim();
          }
        } else {
          // 如果不是以 [ 開頭，可能是純 XML 回應，返回空陣列
          print('回應不是以 JSON 陣列開頭，可能是錯誤回應');
          return _getMockData();
        }
        
        print('提取的 JSON 長度: ${jsonPart.length}');
        print('JSON 前100字元: ${jsonPart.substring(0, jsonPart.length > 100 ? 100 : jsonPart.length)}');
        
        final dynamic parsed = json.decode(jsonPart);
        if (parsed is List) {
          return parsed.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('API 呼叫錯誤: $e');
      // 返回模擬資料用於測試
      return _getMockData();
    }
  }

  // 模擬資料（用於測試，當 API 呼叫失敗時使用）
  static List<Map<String, dynamic>> _getMockData() {
    return [
      {
        "TrainNumber": "104",
        "StationName": "台北車站",
        "DestinationName": "淡水站",
        "CountDown": "00:41",
        "NowDateTime": "2025-08-10 21:00:22"
      },
      {
        "TrainNumber": "105",
        "StationName": "台北車站",
        "DestinationName": "象山站",
        "CountDown": "02:15",
        "NowDateTime": "2025-08-10 21:00:22"
      },
      {
        "TrainNumber": "",
        "StationName": "松江南京站",
        "DestinationName": "新店站",
        "CountDown": "列車進站",
        "NowDateTime": "2025-08-10 21:00:22"
      }
    ];
  }

  // 過濾特定站點的資料
  static List<Map<String, dynamic>> filterByStation(
    List<Map<String, dynamic>> data, 
    String stationName
  ) {
    return data.where((item) => 
      item['StationName']?.toString().contains(stationName.replaceAll('站', '')) ?? false
    ).toList();
  }

  // 取得全部周邊 YouBike（不帶站名）
  static Future<List<Map<String, dynamic>>> fetchYouBikeAll() async {
    const String body = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <getYourBikeNearBy xmlns="http://tempuri.org/">
      <userName>$username</userName>
      <passWord>$password</passWord>
    </getYourBikeNearBy>
  </soap:Body>
</soap:Envelope>''';
    return _postSoapAndExtractJson(ubikeEndpoint, body);
  }

  // 依「車站名稱」取得周邊 YouBike
  // 注意：文件參數是 SationName（少一個 t），要照文件拼法送出
  static Future<List<Map<String, dynamic>>> fetchYouBikeByStation(String stationName) async {
    final safeName = stationName.replaceAll('站', '');
    final String body = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <getYourBikeNearByName xmlns="http://tempuri.org/">
      <userName>$username</userName>
      <passWord>$password</passWord>
      <SationName>$safeName</SationName>
    </getYourBikeNearByName>
  </soap:Body>
</soap:Envelope>''';
    return _postSoapAndExtractJson(ubikeEndpoint, body);
  }

  // 共用：送 SOAP，並把「JSON + XML」的回應切掉 XML，只 parse 前段 JSON
  static Future<List<Map<String, dynamic>>> _postSoapAndExtractJson(String url, String body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers, // 'Content-Type': 'text/xml; charset=utf-8'
        body: utf8.encode(body),
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      final text = utf8.decode(response.bodyBytes);

      String jsonPart = '';
      if (text.startsWith('[') || text.startsWith('{')) {
        final idx = text.indexOf('<?xml');
        jsonPart = (idx >= 0) ? text.substring(0, idx).trim() : text.trim();
      } else {
        throw Exception('Unexpected response (no leading JSON)');
      }

      final parsed = json.decode(jsonPart);
      if (parsed is List) return parsed.cast<Map<String, dynamic>>();
      if (parsed is Map) return [parsed.cast<String, dynamic>()];
      throw Exception('Unexpected JSON format');
    } catch (e) {
      print('YouBike API 錯誤: $e');
      return const [];
    }
  }
}

class RouteInfoPage extends StatelessWidget {
  const RouteInfoPage({super.key});

  // === 地圖原始像素大小 ===
  static const double kMapW = 960;
  static const double kMapH = 1280;

  // 站點資料（相對座標 0~1）。先放幾筆示範，之後可用「座標擷取模式」補齊
  static final List<StationPin> stationPins = [
    StationPin(id: 'R11', title: '台北101/世貿', fx: 0.74, fy: 0.65),
    // StationPin(id: 'G03', title: '松山機場', fx: 0.85, fy: 0.35),
    StationPin(id: 'BL12R10',  title: '松江南京',  fx: 0.51, fy: 0.52),
    StationPin(id: 'BL14O07',  title: '忠孝新生',  fx: 0.51, fy: 0.58),
    StationPin(id: 'BL13',  title: '善導寺',  fx: 0.465, fy: 0.58),
    StationPin(id: 'BL12R10',  title: '台北車站',  fx: 0.41, fy: 0.58),
    StationPin(id: 'G14R11',  title: '中山',  fx: 0.41, fy: 0.52),
    StationPin(id: 'BL11G12',  title: '西門',  fx: 0.345, fy: 0.58),
    StationPin(id: 'G10R08',  title: '中正紀念堂',  fx: 0.41, fy: 0.65),
    StationPin(id: 'G11',  title: '小南門',  fx: 0.345, fy: 0.645),
  ];

  // Modal Bottom Sheet 函數
  void _showModalBottomSheet(BuildContext context, {String? stationName, String? stationId}) async {
    // 當開啟 Bottom Sheet 時呼叫 API 並顯示結果到 console
    print('🚇 點擊站點: $stationName (ID: $stationId)');
    print('📡 開始呼叫台北捷運 API...');
    
    List<Map<String, dynamic>> stationTrackData = [];
    
    try {
      final trackData = await MetroApiService.fetchTrackInfo();
      print('✅ API 呼叫成功，共獲得 ${trackData.length} 筆資料');
      
      // 過濾出與當前站點相關的資料
      stationTrackData = MetroApiService.filterByStation(trackData, stationName ?? '台北車站');
      print('🎯 與 $stationName 相關的資料: ${stationTrackData.length} 筆');
      
      // 詳細顯示相關資料
      for (int i = 0; i < stationTrackData.length; i++) {
        final item = stationTrackData[i];
        print('  ${i + 1}. 車次: ${item['TrainNumber'] ?? '無'} | '
              '終點: ${item['DestinationName']} | '
              '倒數: ${item['CountDown']} | '
              '時間: ${item['NowDateTime']}');
      }
      
      // 如果沒有找到相關資料，顯示所有資料的前5筆作為參考
      if (stationTrackData.isEmpty && trackData.isNotEmpty) {
        print('ℹ️  未找到 $stationName 的資料，顯示前5筆作為參考:');
        final sampleData = trackData.take(5).toList();
        for (int i = 0; i < sampleData.length; i++) {
          final item = sampleData[i];
          print('  ${i + 1}. 站名: ${item['StationName']} | '
                '車次: ${item['TrainNumber'] ?? '無'} | '
                '終點: ${item['DestinationName']} | '
                '倒數: ${item['CountDown']}');
        }
      }
    } catch (e) {
      print('❌ API 呼叫失敗: $e');
    }
    
    print('─' * 50);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _StationInfoSheet(
          stationName: stationName ?? '台北車站',
          stationId: stationId ?? 'BL12R10',
          trackData: stationTrackData, // 傳遞列車資料
        );
      },
    );
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

          // 頁面標題
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF2A3A4A),
            child: const Center(
              child: Text(
                '查詢乘車資訊',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 主要內容區域 - 地圖佔滿整個頁面
          Expanded(
            child: Stack(
              children: [
                // === 關鍵：把 Stack 放進 InteractiveViewer，讓點位跟地圖一起拖動 ===
                InteractiveViewer(
                  constrained: false, // 允許圖片超出邊界，支援自由滑動
                  // minScale: 0.5, // 最小縮放比例 - 暫時註解
                  // maxScale: 5.0, // 最大縮放比例 - 暫時註解
                  boundaryMargin: const EdgeInsets.all(0), // 無邊界限制
                  panEnabled: true, // 允許拖拽 - 支援多方向滑動
                  scaleEnabled: false, // 禁用縮放，只允許滑動
                  child: SizedBox(
                    width: kMapW,
                    height: kMapH,
                    child: Stack(
                      children: [
                        // 地圖圖層
                        Image.asset(
                          'lib/assets/routemap2023n.png',
                          fit: BoxFit.none, // 保持原始大小，允許滑動查看
                          width: kMapW,
                          height: kMapH,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: kMapW,
                              height: kMapH,
                              color: const Color(0xFF1A2327),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '無法載入路線圖',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // 站點 pins
                        for (final pin in stationPins)
                          _PinWidget(
                            pin: pin,
                            onTap: () => _showModalBottomSheet(context, stationName: pin.title, stationId: pin.id),
                          ),
                      ],
                    ),
                  ),
                ),

                // 浮動按鈕 - 觸發 Bottom Sheet
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () => _showModalBottomSheet(context),
                    backgroundColor: const Color(0xFF26C6DA),
                    child: const Icon(Icons.info, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === 資料模型：相對座標 (fx, fy) ===
class StationPin {
  final String id;     // 例如 "BL12R10"
  final String title;  // 顯示名稱
  final double fx;     // 相對 X（0~1）
  final double fy;     // 相對 Y（0~1）
  const StationPin({
    required this.id,
    required this.title,
    required this.fx,
    required this.fy,
  });
}

// === 出口資料模型 ===
class StationExit {
  final String code;       // M1, M2...
  final String desc;       // 地面定位描述
  final bool escalator;    // 電扶梯
  final bool stairs;       // 樓梯
  final bool elevator;     // 電梯
  final bool accessible;   // 無障礙(含電梯)
  const StationExit({
    required this.code,
    required this.desc,
    this.escalator = false,
    this.stairs = false,
    this.elevator = false,
    this.accessible = false,
  });
}

// === 靜態 dummy 資料 ===
class StationStaticData {
  static const String taipeiMainId = 'BL12R10'; // 台北車站 ID
  static const String taipeiMainName = '台北車站';

  static const Map<String, List<StationExit>> exits = {
    taipeiMainId: [
      StationExit(code: 'M1', desc: '台鐵台北車站北一門旁', escalator: true, stairs: true),
      StationExit(code: 'M2', desc: '市民大道一段 209 號對面，近國父史蹟紀念館', elevator: true, accessible: true, escalator: true, stairs: true),
      StationExit(code: 'M3', desc: '忠孝西路一段 45 號', escalator: true),
      StationExit(code: 'M4', desc: '忠孝西路一段 38 號對面', elevator: true, accessible: true, escalator: true),
      StationExit(code: 'M5', desc: '忠孝西路一段 66 號對面', escalator: true),
      StationExit(code: 'M6', desc: '忠孝西路一段 38 號', stairs: true),
      StationExit(code: 'M7', desc: '忠孝西路一段 33 號', stairs: true),
      StationExit(code: 'M8', desc: '公園路 13 號', escalator: true),
    ],
  };

  // 允許用 stationId 或 stationName 查
  static List<StationExit> exitsBy(String idOrName) {
    if (idOrName.contains(taipeiMainName)) return exits[taipeiMainId] ?? const [];
    return exits[idOrName] ?? const [];
  }
}

// === 設施資料模型 ===
class FacilityEntry {
  final String title;        // 群組標題：詢問處、廁所...
  final IconData icon;       // Icons.info_outline / Icons.wc / Icons.family_restroom...
  final List<String> lines;  // 子彈點描述（多行）
  const FacilityEntry({
    required this.title, 
    required this.icon, 
    required this.lines
  });
}

// === 車站設施靜態資料 ===
class StationFacilities {
  static const String taipeiMainId = 'BL12R10';
  static const String taipeiMainName = '台北車站';

  static final Map<String, List<FacilityEntry>> data = {
    taipeiMainId: [
      FacilityEntry(
        title: '詢問處',
        icon: Icons.info_outline,
        lines: [
          '近出口 M3／M7／M8，近忠孝西路',
          '近出口 M4／M5／M6，近忠孝西路',
          '近出口 M1／M2，近市民大道',
        ],
      ),
      FacilityEntry(
        title: '廁所',
        icon: Icons.wc,
        lines: [
          '非付費區：近出口 M1／M2',
          '付費區（板南線）',
          '付費區（淡水信義線）',
        ],
      ),
      FacilityEntry(
        title: '親子無障礙廁所',
        icon: Icons.family_restroom,
        lines: [
          '非付費區：近出口 M1／M2',
          '付費區（板南線）',
          '付費區（淡水信義線）',
        ],
      ),
      FacilityEntry(
        title: '哺集乳室',
        icon: Icons.child_friendly,
        lines: ['板南線：付費區，B2 大廳層'],
      ),
      FacilityEntry(
        title: '嬰兒尿布臺',
        icon: Icons.baby_changing_station,
        lines: [
          '淡水信義線：親子無障礙廁所／男、女廁',
          '板南線：付費區（哺集乳室／親子無障礙廁所／男、女廁）',
        ],
      ),
    ],
  };

  static List<FacilityEntry> of(String idOrName) {
    if (idOrName.contains(taipeiMainName)) return data[taipeiMainId] ?? const [];
    return data[idOrName] ?? const [];
  }
}

// === 公車轉乘資料模型 ===
class BusTransferItem {
  final String route;   // 路線編號：0東、14、1610...
  final String stop;    // 站名：台北車站、台北轉運站...
  final String exit;    // 對應出口：M1、M5、M7...
  const BusTransferItem({required this.route, required this.stop, required this.exit});
}

// === 台北車站（BL12R10）— 公車轉乘假資料 ===
class StationBusDummy {
  static const String taipeiMainId = 'BL12R10';
  static const String taipeiMainName = '台北車站';

  static final Map<String, List<BusTransferItem>> data = {
    taipeiMainId: [
      BusTransferItem(route: '0東',  stop: '台北車站',   exit: 'M5'),
      BusTransferItem(route: '14',   stop: '台北車站',   exit: 'M1'),
      BusTransferItem(route: '14',   stop: '蘆洲',       exit: 'M7'),
      BusTransferItem(route: '1610', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1610', stop: '建國客運站', exit: 'M1'),
      BusTransferItem(route: '1611', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1611', stop: '臺南轉運站', exit: 'M1'),
      BusTransferItem(route: '1613', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1613', stop: '屏東轉運站', exit: 'M1'),
      BusTransferItem(route: '1615', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1615', stop: '彰化站',     exit: 'M1'),
      BusTransferItem(route: '1616', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1616', stop: '員林轉運站', exit: 'M1'),
      BusTransferItem(route: '1617', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1617', stop: '東勢站',     exit: 'M1'),
      BusTransferItem(route: '1618', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1618', stop: '嘉義市轉運中心', exit: 'M1'),
      BusTransferItem(route: '1619', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1619', stop: '國軍英雄館', exit: 'M1'),
    ],
  };

  static List<BusTransferItem> of(String idOrName) {
    if (idOrName.contains(taipeiMainName)) return data[taipeiMainId] ?? const [];
    return data[idOrName] ?? const [];
  }
}

// === 單一 pin 的呈現（可切換為隱形 hit area）===
class _PinWidget extends StatelessWidget {
  const _PinWidget({required this.pin, required this.onTap});
  final StationPin pin;
  final VoidCallback onTap;

  static const double _hit = 28;   // 觸控熱區大小
  static const double _dot = 10;   // 中心圓點（debug用，可隱藏）

  @override
  Widget build(BuildContext context) {
    // 由相對座標轉像素位置
    const mapW = RouteInfoPage.kMapW;
    const mapH = RouteInfoPage.kMapH;
    final left = pin.fx * mapW - _hit / 2;
    final top  = pin.fy * mapH - _hit / 2;

    return Positioned(
      left: left,
      top: top,
      width: _hit,
      height: _hit,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_hit / 2),
        child: Center(
          // 想要「隱形按鈕」就把這顆小方形拿掉
          child: Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.9),
              shape: BoxShape.rectangle, // 改為方形
              borderRadius: BorderRadius.circular(2), // 添加一點圓角
              boxShadow: const [BoxShadow(blurRadius: 4, spreadRadius: 1)],
            ),
          ),
        ),
      ),
    );
  }
}

class _StationInfoSheet extends StatefulWidget {
  final String stationName;
  final String stationId;
  final List<Map<String, dynamic>> trackData; // 新增列車資料參數
  
  const _StationInfoSheet({
    this.stationName = '台北車站',
    this.stationId = 'BL12R10',
    this.trackData = const [], // 預設為空陣列
  });

  @override
  State<_StationInfoSheet> createState() => _StationInfoSheetState();
}

class _StationInfoSheetState extends State<_StationInfoSheet> with TickerProviderStateMixin {
  int selectedIndex = 0;
  final List<String> tabTitles = ['乘車資訊', '車站資訊', '站外資訊'];
  bool isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // YouBike 相關狀態
  List<Map<String, dynamic>> youBikeStations = [];
  bool isLoadingYouBike = false;
  
  // 公車排序狀態
  int busSortIndex = 1; // 0=依出口排序、1=依公車排序（預設如截圖為「依公車排序」）

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    
    // 播放動畫
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _onSelectTab(int i) async {
    setState(() => selectedIndex = i);
    if (i != 2) return; // 只在「站外資訊」時呼叫

    setState(() => isLoadingYouBike = true);
    
    print('🚲 呼叫 YouBike API（依站名）: ${widget.stationName}');
    try {
      // 也可改為 fetchYouBikeAll() 看全部
      final bikes = await MetroApiService.fetchYouBikeByStation(widget.stationName);
      print('✅ YouBike 筆數: ${bikes.length}');
      for (int i = 0; i < bikes.length; i++) {
        final it = bikes[i];
        final name = (it['StationName'] ?? it['name'] ?? it['sna'] ?? '').toString();
        final lat  = (it['Latitude'] ?? it['lat'] ?? it['LAT'] ?? '').toString();
        final lng  = (it['Longitude'] ?? it['lng'] ?? it['LNG'] ?? '').toString();
        if (name.isNotEmpty || (lat.isNotEmpty && lng.isNotEmpty)) {
          print('  ${i + 1}. $name  ($lat, $lng)');
        } else {
          print('  ${i + 1}. ${jsonEncode(it)}');
        }
      }
      setState(() {
        youBikeStations = bikes;
        isLoadingYouBike = false;
      });
    } catch (e) {
      print('❌ YouBike 呼叫失敗: $e');
      setState(() {
        youBikeStations = [];
        isLoadingYouBike = false;
      });
    }
    print('─' * 50);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF22303C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 拖拉指示器
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 第一行：車站名稱
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.stationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isFavorite),
                            color: isFavorite ? Colors.red : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // 第二行：三個按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => _onSelectTab(i),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedIndex == i ? const Color(0xFF26C6DA) : const Color(0xFF2A3A4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(tabTitles[i]),
              ),
            )),
          ),
          const SizedBox(height: 12),
          // 下方內容區域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTabContent(selectedIndex),
            ),
          ),
          const SizedBox(height: 12),
          // 關閉按鈕
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26C6DA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('關閉', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildTrainInfo(); // 顯示列車資訊
      case 1:
        return _buildStationInfo(); // 顯示出口清單
      case 2:
        return _buildOutsideInfo(); // YouBike + 公車（假資料）
      default:
        return Container();
    }
  }

  // 站外資訊（YouBike + 公車）
  Widget _buildOutsideInfo() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        _buildYouBikeBlock(),   // 既有的 YouBike 視覺（改為非 Expanded 版）
        const SizedBox(height: 16),
        _buildBusSection(),     // 新增：公車轉乘（假資料）
      ],
    );
  }

  // 新增：建構 YouBike 區塊（固定高度版本）
  Widget _buildYouBikeBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.directions_bike, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '${widget.stationName} 周邊 YouBike',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isLoadingYouBike) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (isLoadingYouBike)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
              ),
            ),
          )
        else if (youBikeStations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '未找到 YouBike 站點資料',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _YouBikeMapWidget(
                  stations: youBikeStations,
                  currentStationName: widget.stationName,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 新增：公車轉乘區塊
  Widget _buildBusSection() {
    final items = List<BusTransferItem>.from(
      StationBusDummy.of(widget.stationId.isNotEmpty ? widget.stationId : widget.stationName),
    );

    // 排序
    if (busSortIndex == 0) {
      items.sort((a, b) => a.exit.compareTo(b.exit));            // 出口排序
    } else {
      // 公車排序：先 route，再 stop
      items.sort((a, b) => a.route == b.route 
          ? a.stop.compareTo(b.stop) 
          : a.route.compareTo(b.route));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: const [
                Icon(Icons.directions_bus, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('公車轉乘', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // 分段切換（依出口／依公車）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _segBtn('依出口排序', selected: busSortIndex == 0, onTap: () => setState(() => busSortIndex = 0)),
                const SizedBox(width: 8),
                _segBtn('依公車排序', selected: busSortIndex == 1, onTap: () => setState(() => busSortIndex = 1)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // 列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
            itemBuilder: (context, i) {
              final it = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(it.route, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text(it.stop, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    _ExitBadge(it.exit),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 分段按鈕樣式（左灰右藍，對應你的截圖）
  Widget _segBtn(String text, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E77B8) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.transparent : Colors.white30),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // 新增：建構列車資訊的 Widget
  Widget _buildTrainInfo() {
    if (widget.trackData.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('乘車資訊', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 8),
          Text('目前沒有列車進站資訊', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    // 對列車資料進行時間排序，最接近的時間在前面
    List<Map<String, dynamic>> sortedTrackData = List.from(widget.trackData);
    sortedTrackData.sort((a, b) {
      String countDownA = a['CountDown']?.toString() ?? '';
      String countDownB = b['CountDown']?.toString() ?? '';
      
      int secondsA = _parseCountDownToSeconds(countDownA);
      int secondsB = _parseCountDownToSeconds(countDownB);
      
      return secondsA.compareTo(secondsB); // 升序排列，最小的（最接近）在前
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '即時列車進站資訊',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: sortedTrackData.length,
            itemBuilder: (context, index) {
              final train = sortedTrackData[index];
              return _buildTrainCard(train);
            },
          ),
        ),
      ],
    );
  }

  // 新增：建構車站資訊的 Widget
  Widget _buildStationInfo() {
    final exits = StationStaticData.exitsBy(widget.stationId.isNotEmpty ? widget.stationId : widget.stationName);
    final facilities = StationFacilities.of(widget.stationId.isNotEmpty ? widget.stationId : widget.stationName);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 出口資訊區段
          const Text('出口資訊', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (exits.isNotEmpty) ...[
            // 圖例
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: const [
                _Legend(icon: Icons.escalator, label: '電扶梯'),
                _Legend(icon: Icons.stairs, label: '樓梯'),
                _Legend(icon: Icons.elevator, label: '電梯'),
                _Legend(icon: Icons.accessible, label: '無障礙'),
              ],
            ),
            const SizedBox(height: 16),
            // 出口清單
            ...exits.map((exit) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4A),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF26C6DA),
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26C6DA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exit.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exit.desc,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (exit.accessible) const _MiniIcon(icon: Icons.accessible, label: '無障礙'),
                      if (exit.elevator) const _MiniIcon(icon: Icons.elevator, label: '電梯'),
                      if (exit.escalator) const _MiniIcon(icon: Icons.escalator, label: '電扶梯'),
                      if (exit.stairs) const _MiniIcon(icon: Icons.stairs, label: '樓梯'),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ] else ...[
            const Text('目前尚無此站的出口資料', style: TextStyle(color: Colors.grey)),
          ],
          
          const SizedBox(height: 20),
          
          // 設施資訊區段
          const Text('其他設施／設備', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (facilities.isNotEmpty) ...[
            ...facilities.map((facility) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    facility.icon, 
                    size: 28, 
                    color: Colors.white70,
                    semanticLabel: facility.title,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.title, 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...facility.lines.map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $line', 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 13, 
                              height: 1.4,
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ] else ...[
            const Text('目前尚無該站的設施資料', style: TextStyle(color: Colors.grey)),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 新增：解析倒數時間為秒數，用於排序
  int _parseCountDownToSeconds(String countDown) {
    if (countDown.contains('進站')) {
      return 0; // 進站中的列車優先級最高
    } else if (countDown.contains(':')) {
      // 解析 MM:SS 格式
      final parts = countDown.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes * 60 + seconds;
      }
    }
    return 999999; // 無法解析的時間放在最後
  }

  // 新增：建構單筆列車資訊卡片
  Widget _buildTrainCard(Map<String, dynamic> train) {
    final countDown = train['CountDown']?.toString() ?? '';
    final destination = train['DestinationName']?.toString() ?? '';
    final trainNumber = train['TrainNumber']?.toString() ?? '';
    final updateTime = train['NowDateTime']?.toString() ?? '';

    // 判斷倒數時間的顏色
    Color countDownColor = Colors.white;
    IconData statusIcon = Icons.train;
    
    if (countDown.contains('進站')) {
      countDownColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (countDown.contains(':')) {
      // 解析時間，如果小於1分鐘顯示橙色
      final parts = countDown.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        if (minutes == 0) {
          countDownColor = Colors.orange;
          statusIcon = Icons.schedule;
        } else {
          countDownColor = Colors.green;
          statusIcon = Icons.train;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: countDownColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: countDownColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$countDown 往 $destination',
                  style: TextStyle(
                    color: countDownColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (trainNumber.isNotEmpty) ...[
                      Text(
                        '車次: $trainNumber',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      '更新: ${updateTime.split(' ').length > 1 ? updateTime.split(' ')[1] : updateTime}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 新增：建構YouBike地圖的 Widget
  Widget _buildYouBikeMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.directions_bike, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '${widget.stationName} 周邊 YouBike',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isLoadingYouBike) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (isLoadingYouBike)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
              ),
            ),
          )
        else if (youBikeStations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '未找到 YouBike 站點資料',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _YouBikeMapWidget(
                  stations: youBikeStations,
                  currentStationName: widget.stationName,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// 小型圖示 + 字
class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniIcon({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// 圖例
class _Legend extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Legend({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[300]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// YouBike地圖Widget
class _YouBikeMapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stations;
  final String currentStationName;

  const _YouBikeMapWidget({
    required this.stations,
    required this.currentStationName,
  });

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const Center(
        child: Text(
          '沒有YouBike站點資料',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 計算地圖邊界
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    List<YouBikeStation> validStations = [];

    for (final station in stations) {
      final latStr = (station['Latitude'] ?? station['lat'] ?? station['LAT'] ?? '').toString();
      final lngStr = (station['Longitude'] ?? station['lng'] ?? station['LNG'] ?? '').toString();
      final name = (station['StationName'] ?? station['name'] ?? station['sna'] ?? '').toString();
      final available = (station['AvailableBikes'] ?? station['available'] ?? 0).toString();
      final capacity = (station['TotalSlots'] ?? station['capacity'] ?? 0).toString();

      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);

      // 更嚴格的座標驗證
      if (lat != null && lng != null && 
          !lat.isNaN && !lng.isNaN && 
          !lat.isInfinite && !lng.isInfinite &&
          lat != 0.0 && lng != 0.0 &&
          lat >= -90 && lat <= 90 && // 有效緯度範圍
          lng >= -180 && lng <= 180) { // 有效經度範圍
        
        validStations.add(YouBikeStation(
          name: name.isNotEmpty ? name : '未知站點',
          lat: lat,
          lng: lng,
          available: int.tryParse(available) ?? 0,
          capacity: int.tryParse(capacity) ?? 0,
        ));

        // 更新邊界值
        if (minLat.isInfinite || lat < minLat) minLat = lat;
        if (maxLat.isInfinite || lat > maxLat) maxLat = lat;
        if (minLng.isInfinite || lng < minLng) minLng = lng;
        if (maxLng.isInfinite || lng > maxLng) maxLng = lng;
      }
    }

    if (validStations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            '無法解析YouBike站點座標',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 檢查邊界值是否有效
    if (minLat.isInfinite || maxLat.isInfinite || 
        minLng.isInfinite || maxLng.isInfinite ||
        minLat.isNaN || maxLat.isNaN || 
        minLng.isNaN || maxLng.isNaN) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            '座標邊界計算錯誤',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 確保最小邊界範圍，避免除以零
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    
    if (latRange < 0.0001) { // 如果範圍太小，設定最小範圍
      final center = (minLat + maxLat) / 2;
      minLat = center - 0.0001;
      maxLat = center + 0.0001;
    }
    
    if (lngRange < 0.0001) {
      final center = (minLng + maxLng) / 2;
      minLng = center - 0.0001;
      maxLng = center + 0.0001;
    }

    return Column(
      children: [
        // 地圖標題和統計資訊
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1A2327),
          child: Row(
            children: [
              const Icon(Icons.map, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                '找到 ${validStations.length} 個 YouBike 站點',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.info_outline, color: Colors.grey, size: 16),
            ],
          ),
        ),
        // 簡化版地圖顯示
        Expanded(
          child: Container(
            color: const Color(0xFF1A2327),
            child: CustomPaint(
              painter: YouBikeMapPainter(
                stations: validStations,
                minLat: minLat,
                maxLat: maxLat,
                minLng: minLng,
                maxLng: maxLng,
              ),
              child: Container(),
            ),
          ),
        ),
        // 站點清單
        Container(
          height: 120,
          color: const Color(0xFF1A2327),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: validStations.length,
            itemBuilder: (context, index) {
              final station = validStations[index];
              final availabilityRatio = station.capacity > 0 
                  ? station.available / station.capacity 
                  : 0.0;
              
              Color statusColor = Colors.red;
              if (availabilityRatio > 0.3) statusColor = Colors.orange;
              if (availabilityRatio > 0.6) statusColor = Colors.green;

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3A4A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: statusColor, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name.length > 15 
                          ? '${station.name.substring(0, 15)}...'
                          : station.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_bike, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${station.available}/${station.capacity}',
                          style: TextStyle(color: statusColor, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${station.lat.toStringAsFixed(4)}, ${station.lng.toStringAsFixed(4)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
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
}

// YouBike站點資料模型
class YouBikeStation {
  final String name;
  final double lat;
  final double lng;
  final int available;
  final int capacity;

  const YouBikeStation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.available,
    required this.capacity,
  });
}

// 簡化版地圖畫筆
class YouBikeMapPainter extends CustomPainter {
  final List<YouBikeStation> stations;
  final double minLat, maxLat, minLng, maxLng;

  YouBikeMapPainter({
    required this.stations,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    final backgroundPaint = Paint()..color = const Color(0xFF0D1B1F);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 網格線
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final x = (size.width / 5) * i;
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 檢查座標範圍是否有效
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    
    // 避免除以零或無效範圍
    if (latRange <= 0 || lngRange <= 0 || 
        latRange.isNaN || lngRange.isNaN ||
        latRange.isInfinite || lngRange.isInfinite) {
      // 繪製錯誤訊息
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '座標資料無效',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ));
      return;
    }

    // 繪製YouBike站點
    for (final station in stations) {
      // 檢查站點座標是否有效
      if (station.lat.isNaN || station.lng.isNaN ||
          station.lat.isInfinite || station.lng.isInfinite) {
        continue; // 跳過無效座標
      }

      // 計算相對位置（0-1範圍）
      final relativeX = (station.lng - minLng) / lngRange;
      final relativeY = (station.lat - minLat) / latRange;
      
      // 檢查相對位置是否有效
      if (relativeX.isNaN || relativeY.isNaN ||
          relativeX.isInfinite || relativeY.isInfinite) {
        continue; // 跳過無效計算結果
      }

      // 轉換為畫布座標
      final x = relativeX * size.width;
      final y = size.height - (relativeY * size.height); // Y軸翻轉
      
      // 最終檢查畫布座標
      if (x.isNaN || y.isNaN || x.isInfinite || y.isInfinite) {
        continue; // 跳過無效的畫布座標
      }

      // 確保座標在畫布範圍內
      if (x < 0 || x > size.width || y < 0 || y > size.height) {
        continue; // 跳過超出範圍的座標
      }

      final availabilityRatio = station.capacity > 0 
          ? station.available / station.capacity 
          : 0.0;
      
      Color statusColor = Colors.red;
      if (availabilityRatio > 0.3) statusColor = Colors.orange;
      if (availabilityRatio > 0.6) statusColor = Colors.green;

      // 站點圓圈
      final stationPaint = Paint()
        ..color = statusColor
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(Offset(x, y), 6, stationPaint);
      canvas.drawCircle(Offset(x, y), 6, borderPaint);

      // 站點編號或可用數量指示
      if (station.available < 10) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: station.available.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final textX = x - textPainter.width / 2;
        final textY = y - textPainter.height / 2;
        
        // 檢查文字座標是否有效
        if (!textX.isNaN && !textY.isNaN && 
            !textX.isInfinite && !textY.isInfinite) {
          textPainter.paint(canvas, Offset(textX, textY));
        }
      }
    }

    // 圖例
    final legendY = size.height - 30;
    const legendItems = [
      {'color': Colors.green, 'text': '充足'},
      {'color': Colors.orange, 'text': '普通'},
      {'color': Colors.red, 'text': '稀少'},
    ];

    double legendX = 10;
    for (final item in legendItems) {
      final paint = Paint()..color = item['color'] as Color;
      canvas.drawCircle(Offset(legendX + 6, legendY), 4, paint);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: item['text'] as String,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 15, legendY - 5));
      legendX += textPainter.width + 30;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 小黃角「M1/M5/M7」徽章
class _ExitBadge extends StatelessWidget {
  final String code;
  const _ExitBadge(this.code);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F), // 黃色
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(code, style: const TextStyle(color: Color(0xFF114488), fontWeight: FontWeight.w900)),
    );
  }
}
