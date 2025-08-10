import 'package:flutter/material.dart';
import '../widgets/adaptive_text.dart';

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
  void _showModalBottomSheet(BuildContext context, {String? stationName, String? stationId}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _StationInfoSheet(
          stationName: stationName ?? '台北車站',
          stationId: stationId ?? 'BL12R10',
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
  
  const _StationInfoSheet({
    this.stationName = '台北車站',
    this.stationId = 'BL12R10',
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
                onPressed: () => setState(() => selectedIndex = i),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('乘車資訊內容', style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 8),
            Text('這裡可以放乘車相關說明、路線、時刻表等。', style: TextStyle(color: Colors.grey)),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('車站資訊內容', style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 8),
            Text('這裡可以放車站設施、出口、轉乘等資訊。', style: TextStyle(color: Colors.grey)),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('站外資訊內容', style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 8),
            Text('這裡可以放周邊景點、美食、交通等資訊。', style: TextStyle(color: Colors.grey)),
          ],
        );
      default:
        return Container();
    }
  }
}
