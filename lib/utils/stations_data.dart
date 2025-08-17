// 台北捷運線資料（簡化版本）
// 注意：分支線納入主線端點敘述

class StationsData {
  // 各線端點（用於顯示兩個方向）
  static const Map<String, List<String>> lineEndpoints = {
    '淡水信義線': ['淡水', '象山'],
    '松山新店線': ['松山', '新店'], // 含小碧潭支線
    '中和新蘆線': ['南勢角', '蘆洲/迴龍'],
    '板南線': ['南港展覽館', '頂埔', '昆陽', '亞東醫院'],
    '文湖線': ['南港展覽館', '動物園'],
    '環狀線': ['新北產業園區', '大坪林'],
  };

  // 各線車站（精簡常用）
  static const Map<String, List<String>> lineStations = {
    '淡水信義線': [
      '淡水',
      '紅樹林',
      '竹圍',
      '關渡',
      '忠義',
      '復興崗',
      '北投',
      '奇岩',
      '唭哩岸',
      '石牌',
      '明德',
      '芝山',
      '士林',
      '劍潭',
      '圓山',
      '民權西路',
      '雙連',
      '中山',
      '台北車站',
      '台大醫院',
      '中正紀念堂',
      '東門',
      '大安森林公園',
      '大安',
      '信義安和',
      '台北101/世貿',
      '象山',
    ],
    '松山新店線': [
      '松山',
      '南京三民',
      '台北小巨蛋',
      '南京復興',
      '松江南京',
      '中山',
      '北門',
      '西門',
      '小南門',
      '中正紀念堂',
      '古亭',
      '台電大樓',
      '公館',
      '萬隆',
      '景美',
      '大坪林',
      '七張',
      '新店區公所',
      '新店',
      '小碧潭',
    ],
    '中和新蘆線': [
      '南勢角',
      '景安',
      '永安市場',
      '頂溪',
      '古亭',
      '東門',
      '忠孝新生',
      '松江南京',
      '中山國小',
      '民權西路',
      '大橋頭',
      '台北橋',
      '菜寮',
      '三民高中',
      '徐匯中學',
      '頭前庄',
      '新莊',
      '輔大',
      '丹鳳',
      '迴龍',
      '三重國小',
      '三和國中',
      '徐匯中學',
      '三民高中',
      '蘆洲',
    ],
    '板南線': [
      '頂埔',
      '永寧',
      '土城',
      '海山',
      '亞東醫院',
      '府中',
      '板橋',
      '新埔',
      '江子翠',
      '龍山寺',
      '西門',
      '台北車站',
      '善導寺',
      '忠孝新生',
      '忠孝復興',
      '忠孝敦化',
      '國父紀念館',
      '市政府',
      '永春',
      '後山埤',
      '昆陽',
      '南港',
      '南港展覽館',
    ],
    '文湖線': [
      '動物園',
      '木柵',
      '萬芳社區',
      '萬芳醫院',
      '辛亥',
      '麟光',
      '六張犁',
      '科技大樓',
      '大安',
      '忠孝復興',
      '南京復興',
      '中山國中',
      '松山機場',
      '大直',
      '劍南路',
      '西湖',
      '港墘',
      '文德',
      '內湖',
      '大湖公園',
      '葫洲',
      '東湖',
      '南港軟體園區',
      '南港展覽館',
    ],
    '環狀線': [
      '新北產業園區',
      '幸福',
      '新北大道',
      '頭前庄',
      '先嗇宮',
      '三重',
      '三和國中',
      '徐匯中學',
      '板橋',
      '板新',
      '中原',
      '橋和',
      '中和',
      '景安',
      '景平',
      '大坪林',
    ],
  };

  // 各線代表色（ARGB）
  static const Map<String, int> lineColors = {
    '淡水信義線': 0xFFE53935, // 紅
    '松山新店線': 0xFF43A047, // 綠
    '中和新蘆線': 0xFFFB8C00, // 橘
    '板南線': 0xFF1E88E5, // 藍
    '文湖線': 0xFF8D6E63, // 棕
    '環狀線': 0xFFFDD835, // 黃
  };

  // 查詢某站所屬之所有路線（最多兩線）
  static List<String> linesForStation(String stationName) {
    final List<String> lines = [];
    lineStations.forEach((line, stations) {
      if (stations.contains(stationName)) {
        lines.add(line);
      }
    });
    return lines;
  }

  // 各線兩個方向的可能終點（包含常見回折站）
  // directions: [dirA, dirB]，每個方向是一組可能目的地（不含「站」字）
  static const Map<String, List<List<String>>> lineDirectionTerminals = {
    '淡水信義線': [
      ['淡水', '北投'],
      ['象山'],
    ],
    '松山新店線': [
      ['松山'],
      ['新店', '台電大樓', '小碧潭'],
    ],
    '中和新蘆線': [
      ['蘆洲', '迴龍'],
      ['南勢角'],
    ],
    '板南線': [
      ['南港展覽館', '昆陽'],
      ['頂埔', '亞東醫院'],
    ],
    '文湖線': [
      ['南港展覽館'],
      ['動物園'],
    ],
    '環狀線': [
      ['新北產業園區'],
      ['大坪林'],
    ],
  };

  static List<List<String>> directionsForLine(String lineName) {
    return lineDirectionTerminals[lineName] ?? const [[], []];
  }

  // 回傳目的地在該線屬於哪個方向（0 或 1）。若無法判斷回傳 null。
  static int? whichDirection(String lineName, String destination) {
    final dest = destination.replaceAll('站', '');
    final dirs = directionsForLine(lineName);
    if (dirs.isEmpty) return null;
    if (dirs[0].any((d) => dest.contains(d))) return 0;
    if (dirs.length > 1 && dirs[1].any((d) => dest.contains(d))) return 1;
    return null;
  }

  // 依據目的地判斷所屬路線（以端點為準），若無法判斷回傳 null
  static String? lineForDestination(String destination) {
    final String dest = destination.replaceAll('站', '');
    // 先以完整站名所屬線判定（可涵蓋非端點，如「亞東醫院」）
    for (final entry in lineStations.entries) {
      if (entry.value.contains(dest)) {
        return entry.key;
      }
    }
    for (final entry in lineEndpoints.entries) {
      // 端點可能以「蘆洲/迴龍」這類複合字串呈現，需拆分判斷
      final List<String> endpoints = entry.value
          .expand((raw) => raw.split('/'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (endpoints.any((end) => dest.contains(end))) {
        return entry.key;
      }
    }
    return null;
  }

  // 依據車站與目的地共同判斷路線：若目的地同時存在多條線，優先回傳包含該「車站」的那條線
  static String? lineForDestinationAtStation(
    String stationName,
    String destination,
  ) {
    final String station = stationName.replaceAll('站', '');
    final String dest = destination.replaceAll('站', '');
    // 找出所有目的地可能所屬線
    final List<String> candidateLines = [];
    for (final entry in lineStations.entries) {
      if (entry.value.contains(dest)) {
        candidateLines.add(entry.key);
      }
    }
    if (candidateLines.isEmpty) {
      for (final entry in lineEndpoints.entries) {
        final List<String> endpoints = entry.value
            .expand((raw) => raw.split('/'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (endpoints.any((end) => dest.contains(end))) {
          candidateLines.add(entry.key);
        }
      }
    }
    if (candidateLines.isEmpty) return null;

    // 以該站所在之線交集過濾，提高正確性（例如：板橋 => 板南線/環狀線，目的地「大坪林」時應選環狀線）
    final List<String> stationLines = linesForStation(station);
    final List<String> intersection = candidateLines
        .where((line) => stationLines.contains(line))
        .toList();
    if (intersection.isNotEmpty) {
      // 盡量遵循 stationLines 的順序（如有必要）
      for (final sl in stationLines) {
        if (intersection.contains(sl)) return sl;
      }
      return intersection.first;
    }
    // 若無交集，回退原先的第一個候選
    return candidateLines.first;
  }
}
