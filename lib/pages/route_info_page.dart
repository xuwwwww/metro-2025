import 'package:flutter/material.dart';
import '../widgets/adaptive_text.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// === 台北捷運 API 服務 ===
class MetroApiService {
  static const String endpoint =
      'https://api.metro.taipei/metroapi/TrackInfo.asmx';
  // === YouBike 端點 ===
  static const String ubikeEndpoint =
      'https://api.metro.taipei/MetroAPI/UBike.asmx';
  static const Map<String, String> headers = {
    'Content-Type': 'text/xml; charset=utf-8',
  };

  // 模擬帳號密碼 - 實際使用時請從環境變數或安全配置讀取
  static const String username = 'MetroTaipeiHackathon2025';
  static const String password = 'bZ0dQG96N';

  static Future<List<Map<String, dynamic>>> fetchTrackInfo() async {
    final body =
        '''<?xml version="1.0" encoding="utf-8"?>
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
        // print('JSON 前100字元: ${jsonPart.substring(0, jsonPart.length > 100 ? 100 : jsonPart.length)}');

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
        "NowDateTime": "2025-08-10 21:00:22",
      },
      {
        "TrainNumber": "105",
        "StationName": "台北車站",
        "DestinationName": "象山站",
        "CountDown": "02:15",
        "NowDateTime": "2025-08-10 21:00:22",
      },
      {
        "TrainNumber": "",
        "StationName": "松江南京站",
        "DestinationName": "新店站",
        "CountDown": "列車進站",
        "NowDateTime": "2025-08-10 21:00:22",
      },
    ];
  }

  // 過濾特定站點的資料
  static List<Map<String, dynamic>> filterByStation(
    List<Map<String, dynamic>> data,
    String stationName,
  ) {
    return data
        .where(
          (item) =>
              item['StationName']?.toString().contains(
                stationName.replaceAll('站', ''),
              ) ??
              false,
        )
        .toList();
  }

  // 取得全部周邊 YouBike（不帶站名）
  static Future<List<Map<String, dynamic>>> fetchYouBikeAll() async {
    const String body =
        '''<?xml version="1.0" encoding="utf-8"?>
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
  static Future<List<Map<String, dynamic>>> fetchYouBikeByStation(
    String stationName,
  ) async {
    final safeName = stationName.replaceAll('站', '');
    final String body =
        '''<?xml version="1.0" encoding="utf-8"?>
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
  static Future<List<Map<String, dynamic>>> _postSoapAndExtractJson(
    String url,
    String body,
  ) async {
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


class RouteInfoPage extends StatefulWidget {
  const RouteInfoPage({super.key});

  @override
  State<RouteInfoPage> createState() => _RouteInfoPageState();
}

class _RouteInfoPageState extends State<RouteInfoPage> {
  // === 地圖原始像素大小 ===
  static const double kMapW = 960;
  static const double kMapH = 1280;

  // 選中的站點狀態
  StationPin? startStation;
  StationPin? endStation;

  // 站點資料（相對座標 0~1）。先放幾筆示範，之後可用「座標擷取模式」補齊
  static final List<StationPin> stationPins = [
    StationPin(id: 'R11', title: '台北101/世貿', fx: 0.74, fy: 0.65),
    // StationPin(id: 'G03', title: '松山機場', fx: 0.85, fy: 0.35),
    StationPin(id: 'G15R12', title: '松江南京', fx: 0.51, fy: 0.52), // 修正：松江南京站的正確 ID
    StationPin(id: 'BL14O07', title: '忠孝新生', fx: 0.51, fy: 0.58),
    StationPin(id: 'BL13', title: '善導寺', fx: 0.465, fy: 0.58),
    StationPin(id: 'BL12R10', title: '台北車站', fx: 0.41, fy: 0.58), // 台北車站保持原 ID
    StationPin(id: 'G14R11', title: '中山', fx: 0.41, fy: 0.52),
    StationPin(id: 'BL11G12', title: '西門', fx: 0.345, fy: 0.58),
    StationPin(id: 'G10R08', title: '中正紀念堂', fx: 0.41, fy: 0.65),
    StationPin(id: 'G11', title: '小南門', fx: 0.345, fy: 0.645),
    StationPin(id: 'BL15BR10', title: '忠孝復興', fx: 0.615, fy: 0.58),
    StationPin(id: 'G16BR11', title: '南京復興', fx: 0.615, fy: 0.52),
    StationPin(id: 'R05BR09', title: '大安', fx: 0.615, fy:  0.65),
  ];

  // === 站點選擇處理邏輯 ===
  // 這個方法負責處理用戶點擊地圖上站點的邏輯
  // 實現起點→終點的選擇流程，並在選擇完成後自動顯示終點站資訊
  void _onStationSelected(StationPin selectedPin) {
    setState(() {
      if (startStation == null) {
        // 第一次點擊：設置起點
        startStation = selectedPin;
        endStation = null; // 清除終點
      } else if (startStation!.id == selectedPin.id) {
        // 點擊同一個站點：取消選擇
        startStation = null;
        endStation = null;
      } else if (endStation == null) {
        // 第二次點擊不同站點：設置終點，並自動顯示終點站資訊
        endStation = selectedPin;
        _showModalBottomSheet(
          context,
          startStation: startStation!,
          endStation: endStation!,
        );
      } else {
        // 重新選擇：重新設置起點
        startStation = selectedPin;
        endStation = null;
      }
    });
  }

  // Modal Bottom Sheet 函數 - 修改為接受起點和終點
  void _showModalBottomSheet(
    BuildContext context, {
    StationPin? startStation,
    StationPin? endStation,
    String? stationName,
    String? stationId,
  }) async {
    // 如果有起終點，顯示終點站的詳細資訊
    if (startStation != null && endStation != null) {
      print('🚇 顯示終點站資訊: ${endStation.title} (起點: ${startStation.title})');
      print('📡 開始呼叫台北捷運 API...');

      List<Map<String, dynamic>> endStationTrackData = [];

      try {
        final trackData = await MetroApiService.fetchTrackInfo();
        print('✅ API 呼叫成功，共獲得 ${trackData.length} 筆資料');

        // 只過濾終點站的資料
        endStationTrackData = MetroApiService.filterByStation(
          trackData,
          endStation.title,
        );
        print('🎯 終點站 ${endStation.title} 相關資料: ${endStationTrackData.length} 筆');

        // 詳細顯示終點站資料
        for (int i = 0; i < endStationTrackData.length; i++) {
          final item = endStationTrackData[i];
          print(
            '  ${i + 1}. 車次: ${item['TrainNumber'] ?? '無'} | '
            '站名: ${item['StationName']} | '
            '終點: ${item['DestinationName']} | '
            '倒數: ${item['CountDown']} | '
            '時間: ${item['NowDateTime']}',
          );
        }
      } catch (e) {
        print('❌ API 呼叫失敗: $e');
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return _StationInfoSheet(
            stationName: endStation.title,
            stationId: endStation.id,
            startStation: startStation, // 傳遞起點資訊作為參考
            endStation: endStation,     // 傳遞終點資訊
            trackData: endStationTrackData, // 顯示終點站的列車資料
          );
        },
      );
    } else {
      // 原有的單站查詢邏輯
      print('🚇 點擊站點: $stationName (ID: $stationId)');
      print('📡 開始呼叫台北捷運 API...');

      List<Map<String, dynamic>> stationTrackData = [];

      try {
        final trackData = await MetroApiService.fetchTrackInfo();
        print('✅ API 呼叫成功，共獲得 ${trackData.length} 筆資料');

        // 過濾出與當前站點相關的資料
        stationTrackData = MetroApiService.filterByStation(
          trackData,
          stationName ?? '台北車站',
        );
        print('🎯 與 $stationName 相關的資料: ${stationTrackData.length} 筆');

        // 詳細顯示相關資料
        for (int i = 0; i < stationTrackData.length; i++) {
          final item = stationTrackData[i];
          print(
            '  ${i + 1}. 車次: ${item['TrainNumber'] ?? '無'} | '
            '終點: ${item['DestinationName']} | '
            '倒數: ${item['CountDown']} | '
            '時間: ${item['NowDateTime']}',
          );
        }

        // 如果沒有找到相關資料，顯示所有資料的前5筆作為參考
        if (stationTrackData.isEmpty && trackData.isNotEmpty) {
          print('ℹ️  未找到 $stationName 的資料，顯示前5筆作為參考:');
          final sampleData = trackData.take(5).toList();
          for (int i = 0; i < sampleData.length; i++) {
            final item = sampleData[i];
            print(
              '  ${i + 1}. 站名: ${item['StationName']} | '
              '車次: ${item['TrainNumber'] ?? '無'} | '
              '終點: ${item['DestinationName']} | '
              '倒數: ${item['CountDown']}',
            );
          }
        }
      } catch (e) {
        print('❌ API 呼叫失敗: $e');
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return _StationInfoSheet(
            stationName: stationName ?? '台北車站',
            stationId: stationId ?? 'BL12R10',
            trackData: stationTrackData,
          );
        },
      );
    }

    print('─' * 50);
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

          // === 動態狀態指示區塊 ===
          // 這個區塊顯示當前的選擇狀態和使用指引
          // 會根據用戶的選擇動態更新顯示內容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF2A3A4A),
            child: Column(
              children: [
                const Text(
                  '查詢乘車資訊',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // === 選擇狀態顯示 ===
                if (startStation != null || endStation != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 起點標籤（綠色）
                      if (startStation != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '起點: ${startStation!.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // 終點標籤（紅色）或提示文字
                      if (endStation != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '終點: ${endStation!.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (startStation != null) ...[
                        // 只有起點時的提示
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '請選擇終點',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  // 初始狀態的使用指引
                  const SizedBox(height: 8),
                  const Text(
                    '請點選兩個站點進行路線規劃',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
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

                        // === 地圖站點顯示區塊 ===
                        // 這個區塊負責在地圖上渲染所有可點擊的捷運站點
                        // 每個站點會根據選擇狀態顯示不同的顏色和標籤
                        for (final pin in stationPins)
                          _PinWidget(
                            pin: pin,
                            isSelected: startStation?.id == pin.id || endStation?.id == pin.id,
                            isStartStation: startStation?.id == pin.id,     // 綠色標籤
                            isEndStation: endStation?.id == pin.id,         // 紅色標籤
                            onTap: () => _onStationSelected(pin),            // 點擊處理
                          ),
                      ],
                    ),
                  ),
                ),

                // === 浮動按鈕組區塊 ===
                // 這個區塊負責顯示地圖右下角的浮動按鈕
                // 包含重置選擇按鈕，用於清除已選擇的起點和終點
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // === 重置選擇按鈕 ===
                      // 當用戶已選擇起點或終點時顯示，點擊可清除所有選擇
                      if (startStation != null || endStation != null)
                        FloatingActionButton(
                          heroTag: "reset", // 避免多個 FloatingActionButton 衝突
                          onPressed: () {
                            setState(() {
                              startStation = null; // 清除起點
                              endStation = null;   // 清除終點
                            });
                          },
                          backgroundColor: Colors.grey[700],
                          child: const Icon(Icons.clear, color: Colors.white),
                        ),
                      
                      // === 藍色 Info 按鈕（已隱藏）===
                      // 原本用於手動觸發 Bottom Sheet 的按鈕
                      // 現在改為自動觸發（選擇兩個站點後自動顯示），因此隱藏此按鈕
                      /* 
                      if (startStation != null || endStation != null)
                        const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: "info",
                        onPressed: () => _showModalBottomSheet(context),
                        backgroundColor: const Color(0xFF26C6DA),
                        child: const Icon(Icons.info, color: Colors.white),
                      ),
                      */
                    ],
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
  final String id; // 例如 "BL12R10"
  final String title; // 顯示名稱
  final double fx; // 相對 X（0~1）
  final double fy; // 相對 Y（0~1）
  const StationPin({
    required this.id,
    required this.title,
    required this.fx,
    required this.fy,
  });
}

// === 出口資料模型 ===
class StationExit {
  final String code; // M1, M2...
  final String desc; // 地面定位描述
  final bool escalator; // 電扶梯
  final bool stairs; // 樓梯
  final bool elevator; // 電梯
  final bool accessible; // 無障礙(含電梯)
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
      StationExit(
        code: 'M1',
        desc: '台鐵台北車站北一門旁',
        escalator: true,
        stairs: true,
      ),
      StationExit(
        code: 'M2',
        desc: '市民大道一段 209 號對面，近國父史蹟紀念館',
        elevator: true,
        accessible: true,
        escalator: true,
        stairs: true,
      ),
      StationExit(code: 'M3', desc: '忠孝西路一段 45 號', escalator: true),
      StationExit(
        code: 'M4',
        desc: '忠孝西路一段 38 號對面',
        elevator: true,
        accessible: true,
        escalator: true,
      ),
      StationExit(code: 'M5', desc: '忠孝西路一段 66 號對面', escalator: true),
      StationExit(code: 'M6', desc: '忠孝西路一段 38 號', stairs: true),
      StationExit(code: 'M7', desc: '忠孝西路一段 33 號', stairs: true),
      StationExit(code: 'M8', desc: '公園路 13 號', escalator: true),
    ],
  };

  // 允許用 stationId 或 stationName 查
  static List<StationExit> exitsBy(String idOrName) {
    if (idOrName.contains(taipeiMainName))
      return exits[taipeiMainId] ?? const [];
    return exits[idOrName] ?? const [];
  }
}

// === 設施資料模型 ===
class FacilityEntry {
  final String title; // 群組標題：詢問處、廁所...
  final IconData
  icon; // Icons.info_outline / Icons.wc / Icons.family_restroom...
  final List<String> lines; // 子彈點描述（多行）
  const FacilityEntry({
    required this.title,
    required this.icon,
    required this.lines,
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
        lines: ['近出口 M3／M7／M8，近忠孝西路', '近出口 M4／M5／M6，近忠孝西路', '近出口 M1／M2，近市民大道'],
      ),
      FacilityEntry(
        title: '廁所',
        icon: Icons.wc,
        lines: ['非付費區：近出口 M1／M2', '付費區（板南線）', '付費區（淡水信義線）'],
      ),
      FacilityEntry(
        title: '親子無障礙廁所',
        icon: Icons.family_restroom,
        lines: ['非付費區：近出口 M1／M2', '付費區（板南線）', '付費區（淡水信義線）'],
      ),
      FacilityEntry(
        title: '哺集乳室',
        icon: Icons.child_friendly,
        lines: ['板南線：付費區，B2 大廳層'],
      ),
      FacilityEntry(
        title: '嬰兒尿布臺',
        icon: Icons.baby_changing_station,
        lines: ['淡水信義線：親子無障礙廁所／男、女廁', '板南線：付費區（哺集乳室／親子無障礙廁所／男、女廁）'],
      ),
    ],
  };

  static List<FacilityEntry> of(String idOrName) {
    if (idOrName.contains(taipeiMainName))
      return data[taipeiMainId] ?? const [];
    return data[idOrName] ?? const [];
  }
}

// === 公車轉乘資料模型 ===
class BusTransferItem {
  final String route; // 路線編號：0東、14、1610...
  final String stop; // 站名：台北車站、台北轉運站...
  final String exit; // 對應出口：M1、M5、M7...
  const BusTransferItem({
    required this.route,
    required this.stop,
    required this.exit,
  });
}

// === 台北車站（BL12R10）— 公車轉乘假資料 ===
class StationBusDummy {
  static const String taipeiMainId = 'BL12R10';
  static const String taipeiMainName = '台北車站';

  static final Map<String, List<BusTransferItem>> data = {
    taipeiMainId: [
      BusTransferItem(route: '0東', stop: '台北車站', exit: 'M5'),
      BusTransferItem(route: '14', stop: '台北車站', exit: 'M1'),
      BusTransferItem(route: '14', stop: '蘆洲', exit: 'M7'),
      BusTransferItem(route: '1610', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1610', stop: '建國客運站', exit: 'M1'),
      BusTransferItem(route: '1611', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1611', stop: '臺南轉運站', exit: 'M1'),
      BusTransferItem(route: '1613', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1613', stop: '屏東轉運站', exit: 'M1'),
      BusTransferItem(route: '1615', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1615', stop: '彰化站', exit: 'M1'),
      BusTransferItem(route: '1616', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1616', stop: '員林轉運站', exit: 'M1'),
      BusTransferItem(route: '1617', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1617', stop: '東勢站', exit: 'M1'),
      BusTransferItem(route: '1618', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1618', stop: '嘉義市轉運中心', exit: 'M1'),
      BusTransferItem(route: '1619', stop: '台北轉運站', exit: 'M1'),
      BusTransferItem(route: '1619', stop: '國軍英雄館', exit: 'M1'),
    ],
  };

  static List<BusTransferItem> of(String idOrName) {
    if (idOrName.contains(taipeiMainName))
      return data[taipeiMainId] ?? const [];
    return data[idOrName] ?? const [];
  }
}

// === 單一 pin 的呈現（可切換為隱形 hit area）===
class _PinWidget extends StatelessWidget {
  const _PinWidget({
    required this.pin, 
    required this.onTap,
    this.isSelected = false,
    this.isStartStation = false,
    this.isEndStation = false,
  });
  final StationPin pin;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isStartStation;
  final bool isEndStation;

  static const double _hit = 28; // 觸控熱區大小
  static const double _dot = 10; // 中心圓點（debug用，可隱藏）

  @override
  Widget build(BuildContext context) {
    // 由相對座標轉像素位置
    const mapW = _RouteInfoPageState.kMapW;
    const mapH = _RouteInfoPageState.kMapH;
    final left = pin.fx * mapW - _hit / 2;
    final top = pin.fy * mapH - _hit / 2;

    Color pinColor = Colors.cyanAccent.withOpacity(0.9);
    if (isStartStation) {
      pinColor = Colors.green;
    } else if (isEndStation) {
      pinColor = Colors.red;
    } else if (isSelected) {
      pinColor = Colors.orange;
    }

    return Positioned(
      left: left,
      top: top,
      width: _hit,
      height: _hit,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 觸控區域
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_hit / 2),
            child: Center(
              child: Container(
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(
                  color: pinColor,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [BoxShadow(blurRadius: 4, spreadRadius: 1)],
                ),
              ),
            ),
          ),
          // 起終點標籤
          if (isStartStation || isEndStation)
            Positioned(
              top: -25,
              left: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isStartStation ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  isStartStation ? '起點' : '終點',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StationInfoSheet extends StatefulWidget {
  final String? stationName;
  final String? stationId;
  final StationPin? startStation;
  final StationPin? endStation;
  final List<Map<String, dynamic>> trackData; // 列車資料參數

  const _StationInfoSheet({
    this.stationName,
    this.stationId,
    this.startStation,
    this.endStation,
    this.trackData = const [], // 預設為空陣列
  });

  @override
  State<_StationInfoSheet> createState() => _StationInfoSheetState();
}

class _StationInfoSheetState extends State<_StationInfoSheet>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  final List<String> tabTitles = ['乘車資訊', '車站資訊', '站外資訊'];
  bool isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // YouBike 相關狀態
  List<Map<String, dynamic>> youBikeStations = [];
  bool isLoadingYouBike = false;

  // 公車查詢狀態
  final TextEditingController _busSearchController = TextEditingController();
  String busSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _busSearchController.dispose();
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

    // 優先使用終點站，如果沒有終點站則使用起點站或一般站名
    final currentStationName = widget.endStation?.title ?? 
                              widget.startStation?.title ?? 
                              widget.stationName ?? 
                              '台北車站';

    print('🚲 呼叫 YouBike API（依站名）: $currentStationName');
    try {
      // 也可改為 fetchYouBikeAll() 看全部
      final bikes = await MetroApiService.fetchYouBikeByStation(
        currentStationName,
      );
      print('✅ YouBike 筆數: ${bikes.length}');
      for (int i = 0; i < bikes.length; i++) {
        final it = bikes[i];
        final name = (it['StationName'] ?? it['name'] ?? it['sna'] ?? '')
            .toString();
        final lat = (it['Latitude'] ?? it['lat'] ?? it['LAT'] ?? '').toString();
        final lng = (it['Longitude'] ?? it['lng'] ?? it['LNG'] ?? '')
            .toString();
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
          // === Bottom Sheet 標題顯示區塊 ===
          // 顯示選擇的路線資訊，簡化為「起點 → 終點」格式
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: widget.startStation != null && widget.endStation != null
                      ? 
                      // === 路線標示：起點 → 終點 ===
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 起點標籤（綠色）
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.startStation!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // 箭頭
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          // 終點標籤（紅色）
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.endStation!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                      /* === 註解：原本複雜的車站名稱或路線資訊顯示 ===
                      ? Column(
                          children: [
                            Text(
                              widget.endStation!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.startStation!.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.grey,
                                    size: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.endStation!.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      */
                      // === 單站顯示（當沒有選擇路線時）===
                      : Text(
                          widget.stationName ?? '台北車站',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
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
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: () => _onSelectTab(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedIndex == i
                        ? const Color(0xFF26C6DA)
                        : const Color(0xFF2A3A4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(tabTitles[i]),
                ),
              ),
            ),
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
        _buildBusSection(), // 新增：公車轉乘（假資料）
        const SizedBox(height: 16),
        _buildYouBikeBlock(), // 既有的 YouBike 視覺（改為非 Expanded 版）
      ],
    );
  }

  // 新增：建構 YouBike 區塊（固定高度版本）
  Widget _buildYouBikeBlock() {
    final currentStationName = widget.endStation?.title ?? 
                              widget.startStation?.title ?? 
                              widget.stationName ?? 
                              '台北車站';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.directions_bike, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '$currentStationName 周邊 YouBike',
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
                  Icon(Icons.location_off, size: 48, color: Colors.grey),
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
                  currentStationName: currentStationName,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 新增：公車轉乘區塊
  Widget _buildBusSection() {
    final currentStationId = widget.endStation?.id ?? 
                            widget.startStation?.id ?? 
                            widget.stationId ?? 
                            'BL12R10';
    final currentStationName = widget.endStation?.title ?? 
                              widget.startStation?.title ?? 
                              widget.stationName ?? 
                              '台北車站';

    final items = List<BusTransferItem>.from(
      StationBusDummy.of(
        currentStationId.isNotEmpty ? currentStationId : currentStationName,
      ),
    );

    // 預設依公車號碼排序
    items.sort(
      (a, b) => a.route == b.route
          ? a.stop.compareTo(b.stop)
          : a.route.compareTo(b.route),
    );

    // 根據搜尋條件過濾公車路線
    final filteredItems = busSearchQuery.isEmpty
        ? items
        : items.where((item) => 
            item.route.toLowerCase().contains(busSearchQuery.toLowerCase()) ||
            item.stop.toLowerCase().contains(busSearchQuery.toLowerCase())
          ).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 公車標題區塊
          Container(
            width: double.infinity,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF2A3A4A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Center(
              child: Text(
                '公車',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Noto Sans TC',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // 搜尋輸入區域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                // 搜尋輸入框
                Expanded(
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFF646466),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _busSearchController,
                      onChanged: (value) {
                        setState(() {
                          busSearchQuery = value;
                        });
                      },
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        hintText: '輸入公車號碼',
                        hintStyle: const TextStyle(
                          color: Color(0xFF959595),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(left: 8, right: 4),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(
                                    width: 2,
                                    color: Color(0xFF959595),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '依公車號碼排序',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // 搜尋結果提示
          if (busSearchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                filteredItems.isEmpty 
                  ? '未找到符合「$busSearchQuery」的公車路線'
                  : '找到 ${filteredItems.length} 條符合「$busSearchQuery」的公車路線',
                style: TextStyle(
                  color: filteredItems.isEmpty ? Colors.orange : Colors.green,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          // 公車資訊列表標題行
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: const [
                SizedBox(
                  width: 84.64,
                  child: Text(
                    '公車號碼',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '往',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Spacer(),
                Text(
                  '出口',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 20),
              ],
            ),
          ),
          // 公車路線資訊列表
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredItems.length,
            itemBuilder: (context, i) {
              final it = filteredItems[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // 公車號碼
                    SizedBox(
                      width: 84.64,
                      child: Text(
                        it.route,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 往字
                    const Text(
                      '往',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 目的地
                    Expanded(
                      child: Text(
                        it.stop,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 出口標籤
                    _ExitBadge(
                      it.exit,
                      style: ExitBadgeStyle.flag,
                      height: 22,
                    ),
                    const SizedBox(width: 8),
                    // 箭頭
                    const Text(
                      '>',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // 新增：建構列車資訊的 Widget
  Widget _buildTrainInfo() {
    if (widget.trackData.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 列車進站標題區塊
            _buildTrainInfoHeader(updateTime: '沒有資料'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.train, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      '目前沒有列車進站資訊',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

    // 取得最新更新時間（假設所有列車的更新時間相同，取第一筆）
    final latestUpdateTime = sortedTrackData.isNotEmpty 
        ? _extractSecondsFromUpdateTime(sortedTrackData.first['NowDateTime']?.toString() ?? '')
        : '0';

    // 檢查是否為台北車站終點的列車
    final currentStationName = widget.endStation?.title ?? 
                              widget.startStation?.title ?? 
                              widget.stationName ?? 
                              '';
    final showTaipeiStationLayout = currentStationName.contains('台北車站');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列車進站標題區塊
          _buildTrainInfoHeader(updateTime: latestUpdateTime),
          const SizedBox(height: 5),
          // 列車資訊清單
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedTrackData.length,
            separatorBuilder: (context, index) => Container(
              width: double.infinity,
              height: 0.5,
              color: const Color(0xFFE0E0E0), // 淺灰色分隔線，在白色背景下更明顯
              margin: const EdgeInsets.symmetric(horizontal: 15),
            ),
            itemBuilder: (context, index) {
              final train = sortedTrackData[index];
              return _buildTrainCard(train, isFirst: index == 0);
            },
          ),
          const SizedBox(height: 16),

          // === 台北車站月台配置圖片（僅在台北車站顯示）===
          if (showTaipeiStationLayout) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, // 白底背景
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'lib/assets/metro-station-001.png', // 圖片路徑
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.white,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '台北車站月台配置圖載入失敗',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '請確認 metro-platform-layout.png 已放入 assets 資料夾',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // === 首末班車時刻表（僅在台北車站顯示）===
          if (showTaipeiStationLayout) ...[
            // 直接顯示首末班車時刻表，不包邊框
            const TaipeiMainStationSchedule(),
          ],
          
          
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 新增：建構車站資訊的 Widget
  Widget _buildStationInfo() {
    final currentStationId = widget.endStation?.id ?? 
                            widget.startStation?.id ?? 
                            widget.stationId ?? 
                            'BL12R10';
    final currentStationName = widget.endStation?.title ?? 
                              widget.startStation?.title ?? 
                              widget.stationName ?? 
                              '台北車站';

    final exits = StationStaticData.exitsBy(
      currentStationId.isNotEmpty ? currentStationId : currentStationName,
    );
    final facilities = StationFacilities.of(
      currentStationId.isNotEmpty ? currentStationId : currentStationName,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 車站位置圖（只在台北車站顯示）
          if (currentStationName.contains('台北車站')) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.map, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '台北車站位置圖',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Image.asset(
                      'lib/assets/metro-map-001.jpg',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: const Color(0xFF1A2327),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '台北車站位置圖載入失敗',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '請確認 metro-map-001.jpg 已放入 assets 資料夾',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 出口資訊區段
          const Text(
            '出口資訊',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
            ...exits
                .map(
                  (exit) => Container(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
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
                            if (exit.accessible)
                              const _MiniIcon(
                                icon: Icons.accessible,
                                label: '無障礙',
                              ),
                            if (exit.elevator)
                              const _MiniIcon(
                                icon: Icons.elevator,
                                label: '電梯',
                              ),
                            if (exit.escalator)
                              const _MiniIcon(
                                icon: Icons.escalator,
                                label: '電扶梯',
                              ),
                            if (exit.stairs)
                              const _MiniIcon(icon: Icons.stairs, label: '樓梯'),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ] else ...[
            const Text('目前尚無此站的出口資料', style: TextStyle(color: Colors.grey)),
          ],

          const SizedBox(height: 20),

          // 設施資訊區段
          const Text(
            '其他設施／設備',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (facilities.isNotEmpty) ...[
            ...facilities
                .map(
                  (facility) => Container(
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
                              ...facility.lines
                                  .map(
                                    (line) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $line',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
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

  // 新增：從更新時間中提取秒數（用於顯示"X秒前更新"）
  String _extractSecondsFromUpdateTime(String updateTime) {
    if (updateTime.isEmpty) return '0';
    
    try {
      // 假設更新時間格式為 "2024-01-01 12:34:56"，計算與當前時間的差異
      final now = DateTime.now();
      
      // 簡單的邏輯：返回一個隨機的秒數（實際應用中應該計算真實的時間差）
      // 這裡使用模擬數據
      final random = updateTime.hashCode % 60;
      return random.abs().toString();
    } catch (e) {
      return '0';
    }
  }

  // 新增：建構列車進站標題區塊
  Widget _buildTrainInfoHeader({required String updateTime}) {
    return Container(
      width: double.infinity,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFFE1F3F8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Stack(
        children: [
          // 標題文字 "列車進站"
          const Positioned(
            left: 0,
            right: 0,
            top: 8.67,
            child: Text(
              '列車進站',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Noto Sans TC',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // 更新時間顯示
          Positioned(
            right: 10,
            top: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    updateTime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF646466),
                      fontSize: 10,
                      fontFamily: 'Noto Sans TC',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Text(
                  '秒前更新',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF646466),
                    fontSize: 10,
                    fontFamily: 'Noto Sans TC',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 新增：建構單筆列車資訊卡片（新版面）
  Widget _buildTrainCard(Map<String, dynamic> train, {bool isFirst = false}) {
    final countDown = train['CountDown']?.toString() ?? '';
    final destination = train['DestinationName']?.toString() ?? '';
    final trainNumber = train['TrainNumber']?.toString() ?? '';

    // 判斷路線顏色和線路資訊
    Color lineColor = const Color(0xFF008659); // 預設綠線顏色
    String lineCode = '00';
    String lineText = 'R';
    
    // 根據目的地判斷路線（這裡可以擴展更多邏輯）
    if (destination.contains('淡水') || destination.contains('象山')) {
      lineColor = const Color(0xFFE3002C); // 紅線
      lineCode = '02';
      lineText = 'R';
    } else if (destination.contains('蘆洲') || destination.contains('南勢角')) {
      lineColor = const Color(0xFFF79500); // 橘線
      lineCode = '03';
      lineText = 'O';
    } else if (destination.contains('大坪林') || destination.contains('板橋')) {
      lineColor = const Color(0xFF0070BD); // 藍線
      lineCode = '01';
      lineText = 'B';
    }

    return Container(
      width: double.infinity,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white, // 白色背景
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左側：車次和目的地資訊
            SizedBox(
              width: 140,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 路線標籤
                  Container(
                    width: 23.84,
                    height: 28.26,
                    decoration: BoxDecoration(
                      color: lineColor,
                      border: Border.all(
                        width: 1,
                        color: lineColor,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lineText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontFamily: 'Noto Sans TC',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          lineCode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontFamily: 'Noto Sans TC',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 車次號碼（如果有的話）
                  if (trainNumber.isNotEmpty) ...[
                    Text(
                      trainNumber.length > 4 ? trainNumber.substring(0, 4) : trainNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontFamily: 'Noto Sans TC',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // // 目的地站名
                  // Expanded(
                  //   child: Text(
                  //     destination,
                  //     textAlign: TextAlign.left,
                  //     style: const TextStyle(
                  //       color: Colors.black,
                  //       fontSize: 14,
                  //       fontFamily: 'Noto Sans TC',
                  //       fontWeight: FontWeight.w700,
                  //     ),
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  // ),
                ],
              ),
            ),
            // 中間：往字和目的地
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '往',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Noto Sans TC',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      destination,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Noto Sans TC',
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 右側：倒數時間
            SizedBox(
              width: 80,
              child: _buildCountDownDisplay(countDown),
            ),
          ],
        ),
      );
  }

  // 新增：建構倒數時間顯示
  Widget _buildCountDownDisplay(String countDown) {
    if (countDown.contains('進站')) {
      return const Text(
        '進站中',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFD32F2F), // 更深的紅色，在白色背景下更清楚
          fontSize: 16,
          fontFamily: 'Noto Sans TC',
          fontWeight: FontWeight.w900,
        ),
      );
    } else if (countDown.contains(':')) {
      // 解析 MM:SS 格式
      final parts = countDown.split(':');
      if (parts.length == 2) {
        final minutes = parts[0].padLeft(2, '0');
        final seconds = parts[1].padLeft(2, '0');
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 分鐘
            Text(
              minutes,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontFamily: 'Noto Sans TC',
                fontWeight: FontWeight.w900,
              ),
            ),
            // 冒號
            const Text(
              ':',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'Noto Sans TC',
                fontWeight: FontWeight.w900,
              ),
            ),
            // 秒數
            Text(
              seconds,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontFamily: 'Noto Sans TC',
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );
      }
    }
    
    // 其他情況直接顯示原始文字
    return Text(
      countDown,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'Noto Sans TC',
        fontWeight: FontWeight.w700,
      ),
    );
  }

}

// === 台北車站月台視覺化佈局 ===
class TaipeiMainStationLayout extends StatelessWidget {
  const TaipeiMainStationLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 355,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === 標題列：三個欄位並排 ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 76,
                    height: 38,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE1F3F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '鄰近出口',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Noto Sans TC',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 38,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE1F3F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '電/手扶梯',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Noto Sans TC',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 38,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE1F3F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '轉乘方向',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Noto Sans TC',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // === 內容區域：三欄對應內容 ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  
                  
                  // === 第一欄：出口編號 ===
                  Container(
                    width: 82,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 15,
                      children: [
                        Container(width: double.infinity, height: 80),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 1,
                            children: [
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M3',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M4',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 1,
                            children: [
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M3',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M4',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: double.infinity, height: 80),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 1,
                            runSpacing: 1,
                            children: [
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M1',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M2',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 1,
                            children: [
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M1',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                height: 25.33,
                                child: Text(
                                  'M2',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF005EBD),
                                    fontSize: 20,
                                    fontFamily: 'Noto Sans TC',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              
                  // === 第二欄：設施圖示 ===
                  Container(
                    width: 85,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 15,
                      children: [
                        Container(width: double.infinity, height: 80),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(),
                              ),
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 10.21,
                                      top: 4,
                                      child: Container(
                                        width: 4.34,
                                        height: 4.34,
                                        decoration: ShapeDecoration(
                                          color: Colors.black,
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(),
                              ),
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 10.21,
                                      top: 4,
                                      child: Container(
                                        width: 4.34,
                                        height: 4.34,
                                        decoration: ShapeDecoration(
                                          color: Colors.black,
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(),
                              ),
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 10.21,
                                      top: 4,
                                      child: Container(
                                        width: 4.34,
                                        height: 4.34,
                                        decoration: ShapeDecoration(
                                          color: Colors.black,
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 80,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              Container(
                                width: 39,
                                height: 32,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 7.18,
                                      top: 4,
                                      child: Container(
                                        width: 5.65,
                                        height: 5.65,
                                        decoration: ShapeDecoration(
                                          color: Colors.black,
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 22.10,
                                      top: 4,
                                      child: Container(
                                        width: 5.09,
                                        height: 5.09,
                                        decoration: ShapeDecoration(
                                          color: Colors.black,
                                          shape: OvalBorder(side: BorderSide(width: 1)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === 第三欄：轉乘方向 ===
                  Container(

                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // === 底部分隔線 ===
              ...List.generate(5, (index) => Container(
                width: 342,
                height: 1,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignCenter,
                      color: const Color(0xFF646466),
                    ),
                  ),
                ),
              )),
            ],
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
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
          Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
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
        child: Text('沒有YouBike站點資料', style: TextStyle(color: Colors.grey)),
      );
    }

    // 計算地圖邊界
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    List<YouBikeStation> validStations = [];

    for (final station in stations) {
      final latStr =
          (station['Latitude'] ?? station['lat'] ?? station['LAT'] ?? '')
              .toString();
      final lngStr =
          (station['Longitude'] ?? station['lng'] ?? station['LNG'] ?? '')
              .toString();
      final name =
          (station['StationName'] ?? station['name'] ?? station['sna'] ?? '')
              .toString();
      final available = (station['AvailableBikes'] ?? station['available'] ?? 0)
          .toString();
      final capacity = (station['TotalSlots'] ?? station['capacity'] ?? 0)
          .toString();

      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);

      // 更嚴格的座標驗證
      if (lat != null &&
          lng != null &&
          !lat.isNaN &&
          !lng.isNaN &&
          !lat.isInfinite &&
          !lng.isInfinite &&
          lat != 0.0 &&
          lng != 0.0 &&
          lat >= -90 &&
          lat <= 90 && // 有效緯度範圍
          lng >= -180 &&
          lng <= 180) {
        // 有效經度範圍

        validStations.add(
          YouBikeStation(
            name: name.isNotEmpty ? name : '未知站點',
            lat: lat,
            lng: lng,
            available: int.tryParse(available) ?? 0,
            capacity: int.tryParse(capacity) ?? 0,
          ),
        );

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
          child: Text('無法解析YouBike站點座標', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // 檢查邊界值是否有效
    if (minLat.isInfinite ||
        maxLat.isInfinite ||
        minLng.isInfinite ||
        maxLng.isInfinite ||
        minLat.isNaN ||
        maxLat.isNaN ||
        minLng.isNaN ||
        maxLng.isNaN) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('座標邊界計算錯誤', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // 確保最小邊界範圍，避免除以零
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    if (latRange < 0.0001) {
      // 如果範圍太小，設定最小範圍
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
                        Icon(
                          Icons.directions_bike,
                          color: statusColor,
                          size: 14,
                        ),
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

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
    if (latRange <= 0 ||
        lngRange <= 0 ||
        latRange.isNaN ||
        lngRange.isNaN ||
        latRange.isInfinite ||
        lngRange.isInfinite) {
      // 繪製錯誤訊息
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '座標資料無效',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2,
        ),
      );
      return;
    }

    // 繪製YouBike站點
    for (final station in stations) {
      // 檢查站點座標是否有效
      if (station.lat.isNaN ||
          station.lng.isNaN ||
          station.lat.isInfinite ||
          station.lng.isInfinite) {
        continue; // 跳過無效座標
      }

      // 計算相對位置（0-1範圍）
      final relativeX = (station.lng - minLng) / lngRange;
      final relativeY = (station.lat - minLat) / latRange;

      // 檢查相對位置是否有效
      if (relativeX.isNaN ||
          relativeY.isNaN ||
          relativeX.isInfinite ||
          relativeY.isInfinite) {
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
        if (!textX.isNaN &&
            !textY.isNaN &&
            !textX.isInfinite &&
            !textY.isInfinite) {
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

// === 出口徽章樣式枚舉 ===
enum ExitBadgeStyle { flag, square }

// === 小黃角「M1/M5/M7」徽章 - 升級版 ===
class _ExitBadge extends StatelessWidget {
  const _ExitBadge(
    this.code, {
    this.style = ExitBadgeStyle.flag,
    this.height = 28,        // 旗標版高度
    this.squareSize = 40,    // 方塊版邊長
    this.elevation = 3,      // 投影深度（旗標版）
  });

  final String code;
  final ExitBadgeStyle style;
  final double height;
  final double squareSize;
  final double elevation;

  static const Color _yellow = Color(0xFFFFD54F);
  static const Color _blue = Color(0xFF005FBD);

  @override
  Widget build(BuildContext context) {
    if (style == ExitBadgeStyle.square) {
      // === 方塊版：對應 HTML 視覺 ===
      return SizedBox(
        width: squareSize,
        height: squareSize,
        child: Stack(
          children: [
            // 文字靠下置中（對齊 HTML 樣式）
            Positioned(
              left: 6,
              right: 4,
              top: 5,
              bottom: 5,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _OutlinedText(
                  code,
                  fontSize: squareSize * 0.5,   // 40px -> 約 20px 字號
                  fillColor: _blue,
                  strokeColor: Colors.white,
                  strokeWidth: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // === 旗標版：小黃角旗 ===
    final width = height * 1.8; // 視覺上略寬
    return CustomPaint(
      painter: _FlagPainter(
        color: _yellow,
        elevation: elevation,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: _OutlinedText(
            code,
            fontSize: height * 0.6,
            fillColor: _blue,
            strokeColor: Colors.white,
            strokeWidth: 3,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// === 白色外框 + 實心字 ===
class _OutlinedText extends StatelessWidget {
  const _OutlinedText(
    this.text, {
    required this.fontSize,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    this.fontWeight = FontWeight.w700,
  });

  final String text;
  final double fontSize;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 外框描邊
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        // 實心文字
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

/// === 畫小黃角旗（左下角缺口）===
class _FlagPainter extends CustomPainter {
  _FlagPainter({required this.color, this.elevation = 3});
  final Color color;
  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    final notch = size.height * 0.3; // 左下角缺口
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(0, size.height - notch)
      ..close();

    // 陰影效果
    canvas.drawShadow(path, Colors.black.withOpacity(0.4), elevation, true);

    // 旗面
    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.elevation != elevation;
  }
}

// === 台北車站首末班車時刻表 ===
class TaipeiMainStationSchedule extends StatelessWidget {
  const TaipeiMainStationSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // 淺灰背景色
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題區塊
          Container(
            width: double.infinity,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE1F3F8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Center(
              child: Text(
                '首末班車時刻',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Noto Sans TC',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          
          // 標題列
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderColumn('目的地'),
                _buildHeaderColumn('首班'),
                _buildHeaderColumn('末班'),
                _buildHeaderColumn('時刻表'),
              ],
            ),
          ),
          const SizedBox(height: 11),
          
          // 分隔線
          Container(
            width: 342,
            height: 0.5,
            color: const Color(0xFF646466),
          ),
          const SizedBox(height: 8),
          
          // 路線資料
          _buildScheduleRow(
            lineColor: const Color(0xFF0070BD), // 藍線
            lineCode: '01',
            lineText: 'B',
            destination: '新店',
            firstTrain: '06:03',
            lastTrain: '00:50',
            timetable: '查看',
          ),
          const SizedBox(height: 8),
          
          _buildScheduleRow(
            lineColor: const Color(0xFFE3002C), // 紅線
            lineCode: '02', 
            lineText: 'R',
            destination: '淡水',
            firstTrain: '06:00',
            lastTrain: '00:31',
            timetable: '查看',
          ),
          const SizedBox(height: 8),
          
          _buildScheduleRow(
            lineColor: const Color(0xFFE3002C), // 紅線
            lineCode: '02',
            lineText: 'R', 
            destination: '象山',
            firstTrain: '06:06',
            lastTrain: '00:45',
            timetable: '查看',
          ),
          const SizedBox(height: 8),
          
          _buildScheduleRow(
            lineColor: const Color(0xFF008659), // 綠線
            lineCode: '03',
            lineText: 'G',
            destination: '松山',
            firstTrain: '06:03',
            lastTrain: '00:23',
            timetable: '查看',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn(String title) {
    return Container(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Noto Sans TC',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            height: 2,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required Color lineColor,
    required String lineCode,
    required String lineText,
    required String destination,
    required String firstTrain,
    required String lastTrain,
    required String timetable,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 目的地欄位
          SizedBox(
            width: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: ShapeDecoration(
                    color: lineColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lineText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontFamily: 'Noto Sans TC',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        lineCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 6,
                          fontFamily: 'Noto Sans TC',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    destination,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Noto Sans TC',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 首班時間
          SizedBox(
            width: 54,
            child: Text(
              firstTrain,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Noto Sans TC',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          
          // 末班時間
          SizedBox(
            width: 54,
            child: Text(
              lastTrain,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Noto Sans TC',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          
          // 時刻表連結
          SizedBox(
            width: 54,
            child: GestureDetector(
              onTap: () {
                // 這裡可以添加時刻表查看功能
                print('查看 $destination 線時刻表');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF26C6DA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  timetable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Noto Sans TC',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
