import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/stations_data.dart';
import '../utils/global_login_state.dart';
import 'chat_page.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

enum _InfoSection { general, rideshare, chat, music }

enum _GeneralSubTab { emergency, lost, support }

class _InfoPageState extends State<InfoPage> {
  _InfoSection active = _InfoSection.general;
  String search = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Set<String> _userPermissions = {};

  // 進入資訊頁的轉場
  bool _showTransition = true;
  double _transitionOpacity = 0.0; // 從0淡入
  int _gifDurationMs = 1800; // 可依不同檔案調整

  // 一般分頁子選單
  _GeneralSubTab _generalTab = _GeneralSubTab.emergency;

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _emergencyMsgs = [];
  final List<Map<String, String>> _lostMsgs = [];
  final List<Map<String, String>> _supportMsgs = [];

  @override
  void initState() {
    super.initState();
    _loadPermissionsIfLoggedIn();
    _startTransition();
    // 初始化展示訊息
    _emergencyMsgs.addAll([
      {'from': '客服', 'text': '您好，這裡是緊急求助。請簡述位置與狀況。'},
    ]);
    _lostMsgs.addAll([
      {'from': '客服', 'text': '請提供遺失物品、時間與車站，我們協助您查詢。'},
    ]);
    _supportMsgs.addAll([
      {'from': '客服', 'text': '您好，請問需要什麼協助？'},
    ]);
  }

  Future<void> _loadPermissionsIfLoggedIn() async {
    if (!GlobalLoginState.isLoggedIn || GlobalLoginState.currentUid == null)
      return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(GlobalLoginState.currentUid)
          .get();
      final perms = List<String>.from(doc.data()?['permissions'] ?? []);
      setState(() => _userPermissions = perms.toSet());
    } catch (_) {}
  }

  void _startTransition() async {
    // 根據日夜調整預估時長
    final isDay = DateTime.now().hour >= 6 && DateTime.now().hour < 18;
    _gifDurationMs = isDay ? 1800 : 1800; // 需要時可調整
    // 先淡入
    setState(() => _transitionOpacity = 1.0);
    await Future.delayed(Duration(milliseconds: _gifDurationMs - 400));
    if (!mounted) return;
    // 再淡出
    setState(() => _transitionOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showTransition = false);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // 頂部：logo + app名稱 + 所在位置 + 圓形分頁
        Container(
          color: const Color(0xFF22303C),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(
                        child: Text(
                          'LOGO',
                          style: TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '歡迎來到 MetroTogether',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Text(
                      '所在位置  ',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      '【車站名稱】',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 圓形分頁列
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _topCircleTab('一般', _InfoSection.general, Icons.circle),
                    _topCircleTab('共乘', _InfoSection.rideshare, Icons.circle),
                    _topCircleTab('開聊', _InfoSection.chat, Icons.circle),
                    _topCircleTab('音樂', _InfoSection.music, Icons.circle),
                    _addTab(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 主體（不再有左側垂直導航）
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 0,
                ),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 12),
                      Expanded(child: _buildContentBody()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    return SafeArea(
      child: Stack(
        children: [
          content,
          if (_showTransition)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _transitionOpacity,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF22303C),
                  alignment: Alignment.center,
                  child: Image.asset(_transitionAsset(), fit: BoxFit.contain),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _transitionAsset() {
    final hour = DateTime.now().hour;
    final bool isDay = hour >= 6 && hour < 18;
    final String day = 'lib/assets/transition.gif';
    final String night = 'lib/assets/transitionD.gif';
    return isDay ? day : night;
  }

  Widget _topCircleTab(String label, _InfoSection section, IconData icon) {
    final bool isActive = active == section;
    final Color base = isActive ? const Color(0xFF26C6DA) : Colors.white24;
    return InkWell(
      onTap: () => setState(() => active = section),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: base.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: base, width: 2),
            ),
            child: Icon(icon, color: base, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _addTab() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white24.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.white24, size: 18),
        ),
        const SizedBox(height: 4),
        const Text('新增', style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // Title per section
  Widget _buildTitle() {
    switch (active) {
      case _InfoSection.general:
        return const Text(
          '歡迎來到 MetroTogether',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      case _InfoSection.rideshare:
        return const Text(
          '共乘板塊',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      case _InfoSection.chat:
        return const Text(
          '開聊板塊  XX車站',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      case _InfoSection.music:
        return const Text(
          '幸運兒點歌',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }

  Widget _buildContentBody() {
    switch (active) {
      case _InfoSection.general:
        return _generalBody();
      case _InfoSection.rideshare:
        return _rideshareCard();
      case _InfoSection.chat:
        return _chatCard();
      case _InfoSection.music:
        return _musicCard();
    }
  }

  Widget _generalBody() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A4A5A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pill(
                '緊急求助',
                active: _generalTab == _GeneralSubTab.emergency,
                onTap: () =>
                    setState(() => _generalTab = _GeneralSubTab.emergency),
              ),
              const SizedBox(width: 8),
              _pill(
                '失物協尋',
                active: _generalTab == _GeneralSubTab.lost,
                onTap: () => setState(() => _generalTab = _GeneralSubTab.lost),
              ),
              const SizedBox(width: 8),
              _pill(
                '一般客服',
                active: _generalTab == _GeneralSubTab.support,
                onTap: () =>
                    setState(() => _generalTab = _GeneralSubTab.support),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 聊天內容填滿卡片高度
          Expanded(child: _buildGeneralChatList()),
          // 貼齊底部 SafeArea 輸入列
          _buildGeneralInputRow(),
        ],
      ),
    );
  }

  Widget _buildGeneralChatList() {
    final List<Map<String, String>> msgs =
        _generalTab == _GeneralSubTab.emergency
        ? _emergencyMsgs
        : _generalTab == _GeneralSubTab.lost
        ? _lostMsgs
        : _supportMsgs;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: msgs.length,
        itemBuilder: (context, index) {
          final m = msgs[index];
          final isYou = m['from'] == 'You';
          return Align(
            alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxWidth: 240),
              decoration: BoxDecoration(
                color: isYou
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF3A4A5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                m['text'] ?? '',
                style: TextStyle(
                  color: isYou ? Colors.black87 : Colors.white70,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneralInputRow() {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A33),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '發送訊息',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sendGeneralMessage,
                      icon: const Icon(Icons.send, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A33),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.mic, color: Colors.white60, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _sendGeneralMessage() {
    final txt = _chatController.text.trim();
    if (txt.isEmpty) return;
    final list = _generalTab == _GeneralSubTab.emergency
        ? _emergencyMsgs
        : _generalTab == _GeneralSubTab.lost
        ? _lostMsgs
        : _supportMsgs;
    setState(() {
      list.add({'from': 'You', 'text': txt});
      _chatController.clear();
    });
  }

  Widget _rideshareCard() {
    final lines = StationsData.lineStations.keys.toList();
    final filtered = search.isEmpty
        ? lines
        : lines.where((e) => e.contains(search)).toList();
    final joined = filtered.where((l) => _userPermissions.contains(l)).toList();
    final available = filtered
        .where((l) => !_userPermissions.contains(l))
        .toList();
    return _cardWrapper(
      children: [
        _navHeader(title: '加入對話'),
        const SizedBox(height: 8),
        if (joined.isNotEmpty) ...[
          const Text('已加入', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          ...joined.map((e) => _chatroomJoinTile(e)).toList(),
          const SizedBox(height: 12),
        ],
        if (available.isNotEmpty) ...[
          const Text('可加入', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          ...available.map((e) => _chatroomJoinTile(e)).toList(),
        ],
      ],
    );
  }

  Widget _chatCard() {
    final cats = ['上班族', '學生', '星座/運勢'];
    final filtered = search.isEmpty
        ? cats
        : cats.where((e) => e.contains(search)).toList();
    return _cardWrapper(
      children: [
        _navHeader(title: '文字導航'),
        const SizedBox(height: 8),
        ...filtered.map((e) => _navItem(e)).toList(),
      ],
    );
  }

  Widget _musicCard() {
    // 取自先前實作的音樂卡內容（簡化）
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A4A5A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _pill('抽獎參與', active: true),
                const SizedBox(width: 8),
                _pill('前往兌獎'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '抽獎規則',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '這裡放抽獎規則文字，支持多行段落，內容僅示意。\n'
                '這裡放抽獎規則文字，支持多行段落，內容僅示意。',
                style: TextStyle(color: Colors.white70, height: 1.3),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('我要參與抽獎！'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '8/8 6:00am 於官網公告抽獎結果',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardWrapper({required List<Widget> children, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A4A5A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _navHeader({String title = '文字導航'}) {
    return Row(
      children: [
        const Icon(Icons.expand_more, color: Colors.white70, size: 20),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _navItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 22),
          const Icon(Icons.circle, size: 6, color: Colors.white54),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _chatroomJoinTile(String lineName) {
    final bool hasPerm = _userPermissions.contains(lineName);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 22),
              const Icon(Icons.circle, size: 6, color: Colors.white54),
              const SizedBox(width: 8),
              Text(lineName, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          TextButton(
            onPressed: () =>
                hasPerm ? _enterChatRoom(lineName) : _joinChatRoom(lineName),
            child: Text(
              hasPerm ? '進入' : '加入',
              style: const TextStyle(color: Color(0xFF26C6DA)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinChatRoom(String lineName) async {
    if (!GlobalLoginState.isLoggedIn || GlobalLoginState.currentUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }
    final uid = GlobalLoginState.currentUid!;
    try {
      // 確保聊天室存在
      final roomRef = _firestore.collection('chatRooms').doc(lineName);
      await roomRef.set({
        'name': lineName,
        'createdBy': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // 加入 members 子集合
      await roomRef.collection('members').doc(uid).set({
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // 更新使用者 permissions
      await _firestore.collection('users').doc(uid).update({
        'permissions': FieldValue.arrayUnion([lineName]),
      });
      setState(() => _userPermissions.add(lineName));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已加入 $lineName')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加入失敗: $e')));
    }
  }

  void _enterChatRoom(String lineName) {
    if (!GlobalLoginState.isLoggedIn || GlobalLoginState.currentUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          currentUid: GlobalLoginState.currentUid!,
          roomId: lineName,
          profile: {'displayName': GlobalLoginState.userName, 'avatarUrl': ''},
        ),
      ),
    );
  }

  Widget _pill(String text, {bool active = false, VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF22303C) : const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFF26C6DA) : Colors.white24,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: active ? const Color(0xFF26C6DA) : Colors.white70,
          ),
        ),
      ),
    );
  }
}
