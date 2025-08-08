import 'package:flutter/material.dart';
import '../widgets/adaptive_text.dart';

class RouteInfoPage extends StatelessWidget {
  const RouteInfoPage({super.key});

  // Modal Bottom Sheet 函數
  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
              
              // 標題
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  '路線資訊',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // 內容區域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      _buildInfoTile(
                        icon: Icons.train,
                        title: '捷運路線',
                        subtitle: '台北捷運系統路線圖',
                        color: const Color(0xFF26C6DA),
                      ),
                      _buildInfoTile(
                        icon: Icons.access_time,
                        title: '營運時間',
                        subtitle: '06:00 - 24:00',
                        color: Colors.orange,
                      ),
                      _buildInfoTile(
                        icon: Icons.payment,
                        title: '票價資訊',
                        subtitle: '依距離計費，最低 20',
                        color: Colors.green,
                      ),
                      _buildInfoTile(
                        icon: Icons.phone,
                        title: '客服專線',
                        subtitle: '02-218-12345',
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 20),
                      
                      // 關閉按鈕
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26C6DA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '關閉',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 資訊項目小工具
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
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
                // 地圖區域
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: InteractiveViewer(
                    constrained: false, // 允許圖片超出邊界，支援自由滑動
                    // minScale: 0.5, // 最小縮放比例 - 暫時註解
                    // maxScale: 5.0, // 最大縮放比例 - 暫時註解
                    boundaryMargin: const EdgeInsets.all(0), // 無邊界限制
                    panEnabled: true, // 允許拖拽 - 支援多方向滑動
                    scaleEnabled: false, // 禁用縮放，只允許滑動
                    child: Image.asset(
                      'lib/imgs/routemap2023n.png',
                      fit: BoxFit.none, // 保持原始大小，允許滑動查看
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
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
                  ),
                ),
                
                // 浮動按鈕 - 觸發 Bottom Sheet
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () => _showModalBottomSheet(context),
                    backgroundColor: const Color(0xFF26C6DA),
                    child: const Icon(
                      Icons.info,
                      color: Colors.white,
                    ),
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
