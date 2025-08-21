import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/stations_data.dart';
import 'route_info_page.dart' show MetroApiService;
import 'edit_favorite_stations_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class StationArrivalFav {
  StationArrivalFav({
    required this.destination,
    required this.lineName,
    required this.baseSeconds,
    required this.baseTimeMs,
    required this.isArriving,
  });
  final String destination;
  final String? lineName;
  final int baseSeconds;
  final int baseTimeMs;
  final bool isArriving;
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> favoriteStationNames = [];
  List<Map<String, dynamic>> stations = [];
  final Map<String, List<StationArrivalFav>> stationArrivals = {};
  Timer? _timer;
  Timer? _pollTimer;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favJson = prefs.getString('favorite_stations');
    setState(() {
      favoriteStationNames = favJson == null
          ? []
          : (jsonDecode(favJson) as List).cast<String>();
      stations = favoriteStationNames
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
    _fetchArrivals();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < stations.length; i++) {
          final name = stations[i]['name']?.toString() ?? '';
          final arrivals = stationArrivals[name] ?? const [];
          for (int j = 0; j < arrivals.length && j < 2; j++) {
            final a = arrivals[j];
            final r = _remainingSeconds(a.baseSeconds, a.baseTimeMs);
            final formatted = r <= 0 ? '進站' : _formatSeconds(r);
            if (j == 0) {
              stations[i]['destination1'] = a.destination;
              stations[i]['timeToDirection1'] = formatted;
            } else if (j == 1) {
              stations[i]['destination2'] = a.destination;
              stations[i]['timeToDirection2'] = formatted;
            }
          }
        }
      });
    });
  }

  void _startPolling() {
    _fetchArrivals();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _fetchArrivals();
    });
  }

  Future<void> _fetchArrivals() async {
    try {
      if (_isFetching) return;
      setState(() => _isFetching = true);
      final all = await MetroApiService.fetchTrackInfo();
      final Map<String, List<StationArrivalFav>> next = {};
      for (final s in stations) {
        final name = s['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final filtered = MetroApiService.filterByStation(all, name);
        final List<StationArrivalFav> list = filtered
            .map((e) {
              final dest = e['DestinationName']?.toString() ?? '';
              final cd = e['CountDown']?.toString() ?? '';
              final base = _parseCountDownToSeconds(cd);
              if (base == null) return null;
              final nowStr = e['NowDateTime']?.toString() ?? '';
              final ms = _parseNowDateTimeMs(nowStr);
              final line = StationsData.lineForDestination(dest);
              final isArriving = cd.contains('進站');
              return StationArrivalFav(
                destination: dest,
                lineName: line,
                baseSeconds: base,
                baseTimeMs: ms,
                isArriving: isArriving,
              );
            })
            .whereType<StationArrivalFav>()
            .toList();
        list.sort((a, b) => a.baseSeconds.compareTo(b.baseSeconds));
        next[name] = list.take(4).toList();
      }
      if (!mounted) return;
      setState(() {
        stationArrivals
          ..clear()
          ..addAll(next);
        _isFetching = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  int _remainingSeconds(int baseSeconds, int baseMs) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsed = ((nowMs - baseMs) / 1000).floor();
    return baseSeconds - elapsed;
  }

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

  int? _parseCountDownToSeconds(String countDown) {
    if (countDown.contains('進站')) return 0;
    if (countDown.contains(':')) {
      final parts = countDown.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return m * 60 + s;
      }
    }
    return null;
  }

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
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStationArrivalChips(String stationName) {
    final List<Widget> chips = [];
    final arrivals = stationArrivals[stationName] ?? const [];

    final Map<String, List<StationArrivalFav>> byLine = {};
    for (final a in arrivals) {
      final line = a.lineName ?? '未知路線';
      byLine.putIfAbsent(line, () => []).add(a);
    }
    final List<String> candidateLines = byLine.keys.toList();
    final List<String> chosenLines = candidateLines.take(2).toList();
    for (final line in chosenLines) {
      final list = (byLine[line] ?? [])
        ..sort((a, b) => a.baseSeconds.compareTo(b.baseSeconds));
      final color = Color(StationsData.lineColors[line] ?? 0xFF26C6DA);
      final List<StationArrivalFav> dir0 = [];
      final List<StationArrivalFav> dir1 = [];
      for (final item in list) {
        final d = StationsData.whichDirection(line, item.destination);
        if (d == 0) dir0.add(item);
        if (d == 1) dir1.add(item);
      }
      if (dir0.isNotEmpty) {
        final it = dir0.first;
        final r = _remainingSeconds(it.baseSeconds, it.baseTimeMs);
        final txt = (it.isArriving || r <= 0)
            ? '往 ${it.destination} | 進站中'
            : '往 ${it.destination} | ${_formatSeconds(r)}';
        chips.add(_buildArrivalChip(txt, color));
      }
      chips.add(const SizedBox(height: 8));
      if (dir1.isNotEmpty) {
        final it = dir1.first;
        final r = _remainingSeconds(it.baseSeconds, it.baseTimeMs);
        final txt = (it.isArriving || r <= 0)
            ? '往 ${it.destination} | 進站中'
            : '往 ${it.destination} | ${_formatSeconds(r)}';
        chips.add(_buildArrivalChip(txt, color));
      }
      chips.add(const SizedBox(height: 8));
    }
    if (chips.isNotEmpty && chips.last is SizedBox) chips.removeLast();
    if (chips.isEmpty) chips.add(_buildArrivalChip('末班車已過', Colors.grey));
    return chips;
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '進站';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}分 ${s.toString().padLeft(2, '0')}秒';
  }

  Future<void> _openEditFavorites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFavoriteStationsPage(
          initialSelected: favoriteStationNames,
          onChanged: (list) async {
            favoriteStationNames = list;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('favorite_stations', jsonEncode(list));
            _loadFavorites();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最愛站點'),
        actions: [
          IconButton(
            onPressed: _isFetching ? null : _fetchArrivals,
            icon: _isFetching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          TextButton(
            onPressed: _openEditFavorites,
            child: const Text('編輯', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: stations.length,
          itemBuilder: (context, index) {
            final station = stations[index];
            final lines = StationsData.linesForStation(station['name']);
            final List<Color> baseColors = lines
                .take(2)
                .map((l) => Color(StationsData.lineColors[l] ?? 0xFF22303C))
                .toList();
            final List<Color> bgColors = [];
            for (int i = 0; i < baseColors.length; i++) {
              final String lineName = i < lines.length ? lines[i] : '';
              final double alpha = lineName == '文湖線' ? 0.35 : 0.20;
              bgColors.add(baseColors[i].withValues(alpha: alpha));
            }
            final BoxDecoration boxDeco = bgColors.length <= 1
                ? BoxDecoration(
                    color: const Color(0xFF22303C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF114D4D),
                      width: 1,
                    ),
                  )
                : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: const Alignment(0.866, 0.5),
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
                            station['name'] ?? '',
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
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildStationArrivalChips(station['name'] ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
