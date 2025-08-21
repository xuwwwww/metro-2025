import 'package:flutter/material.dart';
import '../utils/stations_data.dart';

class EditFavoriteStationsPage extends StatefulWidget {
  final List<String> initialSelected;
  final ValueChanged<List<String>> onChanged;

  const EditFavoriteStationsPage({
    super.key,
    required this.initialSelected,
    required this.onChanged,
  });

  @override
  State<EditFavoriteStationsPage> createState() =>
      _EditFavoriteStationsPageState();
}

class _EditFavoriteStationsPageState extends State<EditFavoriteStationsPage> {
  late List<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initialSelected);
  }

  void _toggleStation(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  List<Widget> _buildLineSections() {
    final List<Widget> sections = [];
    StationsData.lineStations.forEach((line, stations) {
      // 搜尋過濾
      final filtered = stations.where((s) => s.contains(_query)).toList();
      if (_query.isNotEmpty && filtered.isEmpty) return;

      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            line,
            style: const TextStyle(
              color: Color(0xFF26C6DA),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      sections.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (filtered.isEmpty ? stations : filtered).map((name) {
            final bool isSel = _selected.contains(name);
            return FilterChip(
              selected: isSel,
              onSelected: (_) => _toggleStation(name),
              selectedColor: const Color(0xFF26C6DA).withValues(alpha: 0.2),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSel ? const Color(0xFF26C6DA) : Colors.grey.shade600,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 上色該站所屬線（最多兩個色塊）
                  ...StationsData.linesForStation(name).take(2).map((line) {
                    final colorInt =
                        StationsData.lineColors[line] ?? 0xFF26C6DA;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Color(colorInt),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              avatar: isSel
                  ? const Icon(Icons.check, size: 18, color: Color(0xFF26C6DA))
                  : null,
              backgroundColor: const Color(0xFF3A4A5A),
            );
          }).toList(),
        ),
      );
    });
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF22303C),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '編輯常用站點',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onChanged(_selected);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '完成',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // 搜尋框
            Container(
              color: const Color(0xFF22303C),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '搜尋站名（例：台北車站）',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A3A4A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
            ),

            // 清單
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildLineSections(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
