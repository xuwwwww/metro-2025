import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import '../utils/stations_data.dart';
import '../utils/global_login_state.dart';
// import 'chat_page.dart'; // 不再跳頁使用
// import 'info/general_section.dart';
// import 'info/rideshare_section.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});
  static final GlobalKey<_InfoPageState> globalKey =
      GlobalKey<_InfoPageState>();

  @override
  State<InfoPage> createState() => _InfoPageState();
}

enum _InfoSection { general, rideshare, chat, music }

enum _GeneralSubTab { emergency, lost, support }

class _InfoPageState extends State<InfoPage> {
  static const double _inputBarHeight = 64; // 輸入列固定高度
  static const double _gapToNav = 0; // 與底部 navigation bar 的距離（貼齊上緣）
  _InfoSection active = _InfoSection.general;
  String search = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Set<String> _userPermissions = {};

  // 進入資訊頁的轉場
  bool _showTransition = true;
  double _transitionOpacity = 0.0; // 從0淡入
  int _gifDurationMs = 200; // 可依不同檔案調整

  // 一般分頁子選單（預設一般客服）
  _GeneralSubTab _generalTab = _GeneralSubTab.support;

  final TextEditingController _chatController = TextEditingController();
  // 一般分頁的共用對話訊息（三個選項共用同一串）
  final List<Map<String, String>> _generalMsgs = [];
  bool _isOnline = true;
  Timer? _netTimer;
  String? _activeRideRoom;
  final TextEditingController _rideController = TextEditingController();
  // 語音輸入
  // 延後載入避免未安裝套件時編譯失敗
  late final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  bool _isListening = false;
  final PageController _ridePageController = PageController();
  // 一般分頁滑動
  final PageController _generalPageController = PageController();
  // 閒聊分頁
  final List<String> _chatCategories = ['一般', '上班族', '學生'];
  int _activeChatIndex = 0;
  final PageController _chatPageController = PageController();
  final TextEditingController _freeChatController = TextEditingController();
  final List<Map<String, String>> _freeChatMsgs = [];

  @override
  void initState() {
    super.initState();
    _loadPermissionsIfLoggedIn();
    _startTransition();
    _initSpeech();
    // 預設顯示一般客服的問候
    _generalMsgs.add({'from': '一般客服BOT', 'text': '您好，請問需要什麼協助？'});
    _startOnlineProbe();
  }

  Future<void> _initSpeech() async {
    try {
      _sttAvailable = await _stt.initialize(onStatus: (s) {}, onError: (e) {});
    } catch (_) {
      _sttAvailable = false;
    }
  }

  // 對外：打開一般分頁並切換子膠囊（'emergency'|'lost'|'support'）
  void openGeneral({String? tab}) {
    setState(() => active = _InfoSection.general);
    if (tab == null) return;
    switch (tab) {
      case 'emergency':
        _switchGeneralTab(_GeneralSubTab.emergency);
        _generalPageController.jumpToPage(0);
        break;
      case 'lost':
        _switchGeneralTab(_GeneralSubTab.lost);
        _generalPageController.jumpToPage(1);
        break;
      case 'support':
        _switchGeneralTab(_GeneralSubTab.support);
        _generalPageController.jumpToPage(2);
        break;
    }
  }

  void _startOnlineProbe() {
    _netTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final r = await InternetAddress.lookup('example.com');
        if (!mounted) return;
        setState(() => _isOnline = r.isNotEmpty);
      } catch (_) {
        if (!mounted) return;
        setState(() => _isOnline = false);
      }
    });
  }

  Future<void> _loadPermissionsIfLoggedIn() async {
    if (!GlobalLoginState.isLoggedIn || GlobalLoginState.currentUid == null) {
      return;
    }
    try {
      final doc = await _firestore
          .collection('users')
          .doc(GlobalLoginState.currentUid)
          .get();
      final perms = List<String>.from(doc.data()?['permissions'] ?? []);
      setState(() => _userPermissions = perms.toSet());
      if (active == _InfoSection.rideshare && _activeRideRoom == null) {
        final joined = _userPermissions.toList();
        if (joined.length == 1) {
          _activeRideRoom = joined.first;
        }
      }
    } catch (_) {}
  }

  void _startTransition() async {
    setState(() => _transitionOpacity = 1.0);
    await Future.delayed(Duration(milliseconds: _gifDurationMs - 200));
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
          color: Colors.transparent,
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

        // 主體：一般/共乘/閒聊/音樂 改為撐滿
        Expanded(
          child:
              (active == _InfoSection.general ||
                  active == _InfoSection.rideshare ||
                  active == _InfoSection.chat ||
                  active == _InfoSection.music)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: active == _InfoSection.general
                            ? _generalCard()
                            : active == _InfoSection.rideshare
                            ? _rideshareCard()
                            : active == _InfoSection.chat
                            ? _chatCard()
                            : _musicCard(),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
    final double sysBottom = MediaQuery.of(context).padding.bottom;
    final double gap = sysBottom + _gapToNav;

    return SafeArea(
      top: true,
      bottom: false,
      child: Stack(
        children: [
          // 一般分頁僅保留 gap，其它分頁保留輸入列高度 + gap
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: content,
          ),
          if (active == _InfoSection.general)
            Positioned(
              left: 0,
              right: 0,
              bottom: gap,
              child: _buildGeneralInputRow(),
            ),
          if (active == _InfoSection.rideshare)
            Positioned(
              left: 0,
              right: 0,
              bottom: gap,
              child: _buildRideshareInputRow(),
            ),
          if (active == _InfoSection.chat)
            Positioned(
              left: 0,
              right: 0,
              bottom: gap,
              child: _buildChatInputRow(),
            ),
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
    final Color baseColor = isActive ? const Color(0xFF26C6DA) : Colors.white24;
    final Color backgroundColor = isActive
        ? const Color(0xFF26C6DA).withAlpha(38)
        : Colors.white24.withAlpha(38); // 0.15 * 255 = 38.25 -> 38
    return InkWell(
      onTap: () => setState(() => active = section),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: baseColor, width: 2),
            ),
            child: Icon(icon, color: baseColor, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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
            color: Colors.white24.withAlpha(38), // 0.15 * 255 = 38.25 -> 38
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.white24, size: 16),
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
        return const SizedBox.shrink();
      case _InfoSection.rideshare:
        return const SizedBox.shrink();
      case _InfoSection.chat:
        return const SizedBox.shrink();
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

  Widget _buildContentCard() {
    switch (active) {
      case _InfoSection.general:
        return _generalCard();
      case _InfoSection.rideshare:
        return _rideshareCard();
      case _InfoSection.chat:
        return _chatCard();
      case _InfoSection.music:
        return _musicCard();
    }
  }

  Widget _generalCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF3A4A5A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(100, 70),
          topRight: Radius.elliptical(100, 70),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pill(
                  '緊急求助',
                  active: _generalTab == _GeneralSubTab.emergency,
                  onTap: () {
                    _switchGeneralTab(_GeneralSubTab.emergency);
                    _generalPageController.jumpToPage(0);
                  },
                ),
                _pill(
                  '失物協尋',
                  active: _generalTab == _GeneralSubTab.lost,
                  onTap: () {
                    _switchGeneralTab(_GeneralSubTab.lost);
                    _generalPageController.jumpToPage(1);
                  },
                ),
                _pill(
                  '一般客服',
                  active: _generalTab == _GeneralSubTab.support,
                  onTap: () {
                    _switchGeneralTab(_GeneralSubTab.support);
                    _generalPageController.jumpToPage(2);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent,
                  color: Color(0xFF26C6DA),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _tabLabel(_generalTab),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                if (_isOnline)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _generalPageController,
                onPageChanged: (idx) {
                  setState(() {
                    _generalTab = idx == 0
                        ? _GeneralSubTab.emergency
                        : idx == 1
                        ? _GeneralSubTab.lost
                        : _GeneralSubTab.support;
                    // 切換時清空歷史訊息並插入提示
                    _generalMsgs
                      ..clear()
                      ..add({
                        'from': '${_tabLabel(_generalTab)}BOT',
                        'text': _tabGreeting(_generalTab),
                      });
                  });
                },
                children: [
                  _buildGeneralChatList(false),
                  _buildGeneralChatList(false),
                  _buildGeneralChatList(false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralChatList([bool wrapDecoration = true]) {
    // 顯示聊天訊息區域 + 送出列
    final List<Map<String, String>> msgs = _generalMsgs;

    final list = ListView.builder(
      padding: EdgeInsets.only(
        // 讓清單剛好到輸入列上緣，再加一點視覺緩衝
        bottom:
            _inputBarHeight +
            MediaQuery.of(context).padding.bottom +
            _gapToNav +
            6,
      ),
      itemCount: msgs.length,
      itemBuilder: (context, index) {
        final m = msgs[index];
        final isYou = m['from'] == 'You';
        return Row(
          mainAxisAlignment: isYou
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isYou) ...[
              // 營運方頭像使用灰色 Metro Logo
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'lib/assets/Taipei_Metro_Logo.png',
                  width: 28,
                  height: 28,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
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
            ),
            if (isYou) ...[
              const SizedBox(width: 6),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF26C6DA),
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ],
          ],
        );
      },
    );

    if (!wrapDecoration) return list;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: list,
    );
  }

  Widget _buildFreeChatPane() {
    final list = ListView.builder(
      padding: EdgeInsets.only(
        bottom:
            _inputBarHeight +
            MediaQuery.of(context).padding.bottom +
            _gapToNav +
            6,
      ),
      itemCount: _freeChatMsgs.length,
      itemBuilder: (context, index) {
        final m = _freeChatMsgs[index];
        final isYou = m['from'] == 'You';
        return Row(
          mainAxisAlignment: isYou
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isYou) ...[
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'lib/assets/Taipei_Metro_Logo.png',
                  width: 28,
                  height: 28,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
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
            ),
            if (isYou) ...[
              const SizedBox(width: 6),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF26C6DA),
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ],
          ],
        );
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: list,
    );
  }

  @override
  void dispose() {
    _netTimer?.cancel();
    _chatController.dispose();
    _rideController.dispose();
    _ridePageController.dispose();
    _generalPageController.dispose();
    _chatPageController.dispose();
    _freeChatController.dispose();
    super.dispose();
  }

  Widget _buildGeneralInputRow() {
    return SafeArea(
      top: false,
      bottom: false,
      minimum: EdgeInsets.zero,
      child: SizedBox(
        height: _inputBarHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A33),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // 左側 Taipei_Metro_Logo 灰色
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'lib/assets/Taipei_Metro_Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white),
                          textAlignVertical: TextAlignVertical.center,
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
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        iconSize: 20,
                        alignment: Alignment.center,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: const Color(0xFF1E2A33),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _sttAvailable ? _startChatVoiceInput : null,
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white60,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendGeneralMessage() {
    final txt = _chatController.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _generalMsgs.add({'from': 'You', 'text': txt});
      _chatController.clear();
    });
  }

  // 語音輸入（一般）
  Future<void> _startChatVoiceInput() async {
    if (!_sttAvailable) return;
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _stt.listen(
      onResult: (r) {
        setState(() => _chatController.text = r.recognizedWords);
      },
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      localeId: Platform.localeName,
    );
  }

  // 切換一般分頁的對話對象（三選一）
  void _switchGeneralTab(_GeneralSubTab tab) {
    if (_generalTab == tab) return;
    setState(() {
      _generalTab = tab;
      // 切換時清空歷史訊息，重新插入對應提示
      _generalMsgs
        ..clear()
        ..add({'from': '${_tabLabel(tab)}BOT', 'text': _tabGreeting(tab)});
    });
  }

  String _tabLabel(_GeneralSubTab tab) {
    switch (tab) {
      case _GeneralSubTab.emergency:
        return '緊急求助';
      case _GeneralSubTab.lost:
        return '失物協尋';
      case _GeneralSubTab.support:
        return '一般客服';
    }
  }

  String _tabGreeting(_GeneralSubTab tab) {
    switch (tab) {
      case _GeneralSubTab.emergency:
        return '您好，這裡是緊急求助。請簡述位置與狀況。';
      case _GeneralSubTab.lost:
        return '請提供遺失物品、時間與車站，我們協助您查詢。';
      case _GeneralSubTab.support:
        return '您好，請問需要什麼協助？';
    }
  }

  Widget _rideshareCard() {
    // 取用戶所有已加入聊天室（用 permissions）
    final List<String> joinedRooms = _userPermissions.toList()..sort();
    return Container(
      decoration: BoxDecoration(
        color: _resolveLineOverlayColor(_activeRideRoom).withAlpha(28),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(100, 70),
          topRight: Radius.elliptical(100, 70),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.elliptical(100, 70),
          topRight: Radius.elliptical(100, 70),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 頂部：多膠囊（每個代表一個聊天室）
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: joinedRooms.isNotEmpty
                      ? [
                          ...joinedRooms.map(
                            (room) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _pill(
                                room,
                                active: room == _activeRideRoom,
                                onTap: () {
                                  setState(() {
                                    active = _InfoSection.rideshare;
                                    _activeRideRoom = room;
                                  });
                                  final idx = joinedRooms.indexOf(room);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (idx >= 0 &&
                                        _ridePageController.hasClients) {
                                      _ridePageController.jumpToPage(idx);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _pill('加入聊天室', onTap: _openJoinRoomsPage),
                          const SizedBox(width: 10),
                        ]
                      : [
                          _pill('尚未加入聊天室', active: true),
                          const SizedBox(width: 8),
                          _pill('加入聊天室', onTap: _openJoinRoomsPage),
                          const SizedBox(width: 10),
                        ],
                ),
              ),
              const SizedBox(height: 12),
              // 對話區（依據當前聊天室顯示串流）填滿卡片剩餘空間
              Expanded(
                child: _activeRideRoom == null
                    ? Center(
                        child: Text(
                          joinedRooms.isEmpty ? '尚未加入聊天室，請先加入' : '請在上方選擇聊天室',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : PageView.builder(
                        controller: _ridePageController,
                        onPageChanged: (index) {
                          if (index >= 0 && index < joinedRooms.length) {
                            setState(
                              () => _activeRideRoom = joinedRooms[index],
                            );
                          }
                        },
                        itemCount: joinedRooms.length,
                        itemBuilder: (context, index) {
                          final roomId = joinedRooms[index];
                          return _buildRideChatList(roomId);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 共乘聊天室串流清單
  Widget _buildRideChatList(String roomId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('載入失敗', style: TextStyle(color: Colors.redAccent)),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF26C6DA)),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              '還沒有訊息，開始聊天吧！',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        final double bottomPad =
            _inputBarHeight +
            MediaQuery.of(context).padding.bottom +
            _gapToNav +
            6;
        const double avatarSize = 42; // 放大 1.5 倍（原約 28）
        const double avatarLift = avatarSize / 2 - 26; // 再往下偏移40

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8, 6, 8, bottomPad),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final bool isMe = data['senderUid'] == GlobalLoginState.currentUid;
            final String content = (data['content'] as String?) ?? '';
            final Map<String, dynamic>? senderProfile =
                data['senderProfile'] as Map<String, dynamic>?;
            final String displayName =
                (senderProfile?['displayName'] as String?) ??
                (isMe ? '我' : '未知用戶');
            final dynamic ts = data['timestamp'];
            String timeStr = '';
            if (ts is Timestamp) {
              final dt = ts.toDate().toLocal();
              timeStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }

            final Widget avatar = CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: const Color(0xFF26C6DA),
              child: const Icon(Icons.person, color: Colors.white),
            );

            final Widget bubble = Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE0E0E0) : const Color(0xFF3A4A5A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: TextStyle(
                      color: isMe ? Colors.black87 : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isMe ? Colors.black45 : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );

            if (!isMe) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: Offset(0, -avatarLift),
                    child: avatar,
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: bubble),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: bubble),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: Offset(0, -avatarLift),
                  child: avatar,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _resolveLineOverlayColor(String? roomId) {
    if (roomId == null) return Colors.transparent;
    final dynamic v = StationsData.lineColors[roomId];
    if (v is Color) return v.withAlpha(18);
    if (v is int) return Color(v).withAlpha(18);
    return const Color(0xFF2A3A4A).withAlpha(18);
  }

  // 共乘輸入列（固定底部）
  Widget _buildRideshareInputRow() {
    return SafeArea(
      top: false,
      bottom: false,
      minimum: EdgeInsets.zero,
      child: SizedBox(
        height: _inputBarHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A33),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'lib/assets/Taipei_Metro_Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _rideController,
                          enabled: _activeRideRoom != null,
                          style: const TextStyle(color: Colors.white),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: _activeRideRoom == null
                                ? '請先選擇聊天室'
                                : '發送訊息',
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendRideMessage(),
                        ),
                      ),
                      IconButton(
                        onPressed: _sendRideMessage,
                        icon: const Icon(Icons.send, color: Colors.white70),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        iconSize: 20,
                        alignment: Alignment.center,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: const Color(0xFF1E2A33),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _sttAvailable ? _startRideVoiceInput : null,
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white60,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendRideMessage() async {
    final text = _rideController.text.trim();
    final roomId = _activeRideRoom;
    if (text.isEmpty || roomId == null) return;
    try {
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .add({
            'senderUid': GlobalLoginState.currentUid,
            'senderProfile': {
              'displayName': GlobalLoginState.userName,
              'avatarUrl': '',
            },
            'content': text,
            'timestamp': FieldValue.serverTimestamp(),
            'expireAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 10)),
            ),
          });
      _rideController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('發送失敗')));
      }
    }
  }

  // 語音輸入（共乘）
  Future<void> _startRideVoiceInput() async {
    if (!_sttAvailable) return;
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _stt.listen(
      onResult: (r) {
        setState(() => _rideController.text = r.recognizedWords);
      },
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      localeId: Platform.localeName,
    );
  }

  Widget _buildChatInputRow() {
    return SafeArea(
      top: false,
      bottom: false,
      minimum: EdgeInsets.zero,
      child: SizedBox(
        height: _inputBarHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A33),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'lib/assets/Taipei_Metro_Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _freeChatController,
                          style: const TextStyle(color: Colors.white),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            hintText: '發送訊息',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) {
                            final t = _freeChatController.text.trim();
                            if (t.isEmpty) return;
                            setState(() {
                              _freeChatMsgs.add({'from': 'You', 'text': t});
                              _freeChatController.clear();
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final t = _freeChatController.text.trim();
                          if (t.isEmpty) return;
                          setState(() {
                            _freeChatMsgs.add({'from': 'You', 'text': t});
                            _freeChatController.clear();
                          });
                        },
                        icon: const Icon(Icons.send, color: Colors.white70),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        iconSize: 20,
                        alignment: Alignment.center,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A33),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.mic, color: Colors.white60, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveChatRoom(String lineName) async {
    if (!GlobalLoginState.isLoggedIn || GlobalLoginState.currentUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }
    final uid = GlobalLoginState.currentUid!;
    try {
      final roomRef = _firestore.collection('chatRooms').doc(lineName);
      await roomRef.collection('members').doc(uid).delete();
      await _firestore.collection('users').doc(uid).update({
        'permissions': FieldValue.arrayRemove([lineName]),
      });
      setState(() {
        _userPermissions.remove(lineName);
        if (_activeRideRoom == lineName) {
          _activeRideRoom = null;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已退出 $lineName')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('退出失敗: $e')));
    }
  }

  // 從外部開啟共乘分頁，並可指定聊天室
  void openRideshare({String? roomId}) {
    setState(() => active = _InfoSection.rideshare);
    if (roomId != null) {
      setState(() => _activeRideRoom = roomId);
      return;
    }
    final joined = _userPermissions.toList();
    if (_activeRideRoom == null && joined.length == 1) {
      setState(() => _activeRideRoom = joined.first);
    }
  }

  void _openJoinRoomsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF22303C),
          appBar: AppBar(title: const Text('加入新的聊天室')),
          body: _buildJoinRoomsBody(),
        ),
      ),
    );
  }

  Widget _buildJoinRoomsBody() {
    if (!GlobalLoginState.isLoggedIn || GlobalLoginState.currentUid == null) {
      return const Center(
        child: Text('請先登入', style: TextStyle(color: Colors.white70)),
      );
    }
    final String uid = GlobalLoginState.currentUid!;
    final allLines = StationsData.lineStations.keys.toList();
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final currentPerms = List<String>.from(data?['permissions'] ?? []);
        final filtered = search.isEmpty
            ? allLines
            : allLines.where((e) => e.contains(search)).toList();
        final joined = filtered.where((l) => currentPerms.contains(l)).toList();
        final available = filtered
            .where((l) => !currentPerms.contains(l))
            .toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          ),
        );
      },
    );
  }

  Widget _chatCard() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3A4A5A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(100, 70),
          topRight: Radius.elliptical(100, 70),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _chatCategories.length + 1,
                itemBuilder: (context, index) {
                  if (index == _chatCategories.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _pill('加入聊天室', onTap: () {}),
                    );
                  }
                  final label = _chatCategories[index];
                  final active = index == _activeChatIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _pill(
                      label,
                      active: active,
                      onTap: () {
                        setState(() => _activeChatIndex = index);
                        _chatPageController.jumpToPage(index);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView.builder(
                controller: _chatPageController,
                onPageChanged: (idx) => setState(() => _activeChatIndex = idx),
                itemCount: _chatCategories.length,
                itemBuilder: (context, idx) {
                  return _buildFreeChatPane();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _musicCard() {
    // 依照提供的設計重建
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3A4A5A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(100, 70),
          topRight: Radius.elliptical(100, 70),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題與右上角資訊
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '幸運兒點歌',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      'X X : X X',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '今日登錄人數 X X 人',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('參與抽獎點歌機會！', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            // 抽獎規則卡
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '抽獎規則\n\n'
                '• 需登入 App。\n'
                '• 每日有三位幸運兒，分別在 8:30/15:30/18:30 三個時段揭曉。\n'
                '  例：\n'
                '  6:30-8:30 報名者，可抽隔日 8:30/15:30/18:30 三個時段。\n'
                '  8:31-15:30 報名者，可抽隔日 15:30/18:30 兩個時段。\n'
                '  15:31-18:30 報名者，可抽隔日 18:30 一個時段。\n'
                '• 每日 20:00 公布隔日點歌人選。\n'
                '• 中獎者於成員中夾帶關鍵字或發歌單即示意，逾時失效。\n'
                '• 歌曲的投稿連結於點歌者在的連連貼內播放。',
                style: TextStyle(color: Colors.white70, height: 1.35),
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
                    horizontal: 22,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('我要參與抽獎！'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '8/8 6:00am 於官網公告抽獎結果',
              style: TextStyle(color: Colors.white70, fontSize: 12),
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
          Row(
            children: [
              TextButton(
                onPressed: () => hasPerm
                    ? _enterChatRoom(lineName)
                    : _joinChatRoom(lineName),
                child: Text(
                  hasPerm ? '進入' : '加入',
                  style: const TextStyle(color: Color(0xFF26C6DA)),
                ),
              ),
              if (hasPerm)
                TextButton(
                  onPressed: () => _leaveChatRoom(lineName),
                  child: const Text(
                    '退出',
                    style: TextStyle(color: Color(0xFFEF9A9A)),
                  ),
                ),
            ],
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
    setState(() {
      active = _InfoSection.rideshare;
      _activeRideRoom = lineName;
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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
