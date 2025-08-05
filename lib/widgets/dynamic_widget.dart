import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_item.dart';
import '../utils/grid_config.dart';

class DynamicWidget extends StatefulWidget {
  final AppItem item;
  final Color backgroundColor;
  final int size;

  const DynamicWidget({
    super.key,
    required this.item,
    required this.backgroundColor,
    required this.size,
  });

  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  // MRT arrival simulation variables
  late int _northboundTime1;
  late int _northboundTime2;
  late int _northboundTime3;
  late int _southboundTime1;
  late int _southboundTime2;
  late int _southboundTime3;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _initializeMRTTimes();
    _startTimer();
  }

  void _initializeMRTTimes() {
    // Initialize with random arrival times between 1-8 minutes
    _northboundTime1 = 2 + (DateTime.now().millisecond % 3);
    _northboundTime2 = _northboundTime1 + 2 + (DateTime.now().millisecond % 2);
    _northboundTime3 = _northboundTime2 + 2 + (DateTime.now().millisecond % 2);

    _southboundTime1 = 1 + (DateTime.now().millisecond % 3);
    _southboundTime2 = _southboundTime1 + 2 + (DateTime.now().millisecond % 2);
    _southboundTime3 = _southboundTime2 + 2 + (DateTime.now().millisecond % 2);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
          _updateMRTTimes();
        });
      }
    });
  }

  void _updateMRTTimes() {
    // Decrease all times by 1 minute
    _northboundTime1 = (_northboundTime1 - 1).clamp(0, 10);
    _northboundTime2 = (_northboundTime2 - 1).clamp(0, 10);
    _northboundTime3 = (_northboundTime3 - 1).clamp(0, 10);

    _southboundTime1 = (_southboundTime1 - 1).clamp(0, 10);
    _southboundTime2 = (_southboundTime2 - 1).clamp(0, 10);
    _southboundTime3 = (_southboundTime3 - 1).clamp(0, 10);

    // Reset times when they reach 0 (simulate new trains)
    if (_northboundTime1 == 0) {
      _northboundTime1 = 6 + (DateTime.now().millisecond % 3);
      _northboundTime2 =
          _northboundTime1 + 2 + (DateTime.now().millisecond % 2);
      _northboundTime3 =
          _northboundTime2 + 2 + (DateTime.now().millisecond % 2);
    }
    if (_southboundTime1 == 0) {
      _southboundTime1 = 5 + (DateTime.now().millisecond % 3);
      _southboundTime2 =
          _southboundTime1 + 2 + (DateTime.now().millisecond % 2);
      _southboundTime3 =
          _southboundTime2 + 2 + (DateTime.now().millisecond % 2);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.item.widgetType) {
      case 'clock':
        return _buildClockWidget();
      case 'weather':
        return _buildWeatherWidget();
      case 'battery':
        return _buildBatteryWidget();
      case 'calendar':
        return _buildCalendarWidget();
      case 'pedometer':
        return _buildPedometerWidget();
      case 'alarm':
        return _buildAlarmWidget();
      case 'mrt':
        return _buildMRTWidget();
      default:
        return _buildDefaultWidget();
    }
  }

  Widget _buildClockWidget() {
    final timeString =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
    final dateString =
        '${_currentTime.year}/${_currentTime.month.toString().padLeft(2, '0')}/${_currentTime.day.toString().padLeft(2, '0')}';

    return Container(
      width: 72.0 * widget.size + 8.0 * (widget.size - 1),
      height: 72,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.item.icon, color: widget.item.color, size: 20),
          const SizedBox(height: 2),
          Text(
            timeString,
            style: TextStyle(
              fontSize: widget.size >= 2 ? 14 : 10,
              fontWeight: FontWeight.bold,
              color: widget.item.color,
            ),
          ),
          if (widget.size >= 2) ...[
            const SizedBox(height: 1),
            Text(
              dateString,
              style: TextStyle(
                fontSize: 8,
                color: widget.item.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      width: 72.0 * widget.size + 8.0 * (widget.size - 1),
      height: 72,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.item.icon, color: widget.item.color, size: 20),
          const SizedBox(height: 2),
          Text(
            '25°C',
            style: TextStyle(
              fontSize: widget.size >= 2 ? 14 : 10,
              fontWeight: FontWeight.bold,
              color: widget.item.color,
            ),
          ),
          if (widget.size >= 2) ...[
            const SizedBox(height: 1),
            Text(
              '晴天',
              style: TextStyle(
                fontSize: 8,
                color: widget.item.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryWidget() {
    return Container(
      width: 72.0 * widget.size + 8.0 * (widget.size - 1),
      height: 72,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.item.icon, color: widget.item.color, size: 20),
          const SizedBox(height: 2),
          Text(
            '85%',
            style: TextStyle(
              fontSize: widget.size >= 2 ? 14 : 10,
              fontWeight: FontWeight.bold,
              color: widget.item.color,
            ),
          ),
          if (widget.size >= 2) ...[
            const SizedBox(height: 1),
            Text(
              '充電中',
              style: TextStyle(
                fontSize: 8,
                color: widget.item.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultWidget() {
    return Container(
      width: 72.0 * widget.size + 8.0 * (widget.size - 1),
      height: 72,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.item.icon, color: widget.item.color, size: 20),
          const SizedBox(height: 2),
          Text(
            widget.item.name,
            style: TextStyle(
              fontSize: widget.size >= 2 ? 12 : 10,
              color: widget.item.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final dateString = '${_currentTime.day}';
    final monthString = '${_currentTime.month}月';

    return Container(
      width: 72.0 * widget.size + 8.0 * (widget.size - 1),
      height: 72,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.item.icon, color: widget.item.color, size: 20),
          const SizedBox(height: 2),
          Text(
            dateString,
            style: TextStyle(
              fontSize: widget.size >= 2 ? 16 : 12,
              fontWeight: FontWeight.bold,
              color: widget.item.color,
            ),
          ),
          if (widget.size >= 2) ...[
            const SizedBox(height: 1),
            Text(
              monthString,
              style: TextStyle(
                fontSize: 8,
                color: widget.item.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPedometerWidget() {
    return Container(
      width: 72.0 * widget.size + 8.0 * (widget.size - 1),
      height: 72,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.item.icon, color: widget.item.color, size: 20),
          const SizedBox(height: 2),
          Text(
            '8,547',
            style: TextStyle(
              fontSize: widget.size >= 2 ? 14 : 10,
              fontWeight: FontWeight.bold,
              color: widget.item.color,
            ),
          ),
          if (widget.size >= 2) ...[
            const SizedBox(height: 1),
            Text(
              '步',
              style: TextStyle(
                fontSize: 8,
                color: widget.item.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlarmWidget() {
    return Container(
      width: 72.0 * widget.size + 8.0 * (widget.size - 1),
      height: 72,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.item.icon, color: widget.item.color, size: 20),
          const SizedBox(height: 2),
          Text(
            '07:30',
            style: TextStyle(
              fontSize: widget.size >= 2 ? 14 : 10,
              fontWeight: FontWeight.bold,
              color: widget.item.color,
            ),
          ),
          if (widget.size >= 2) ...[
            const SizedBox(height: 1),
            Text(
              '鬧鐘',
              style: TextStyle(
                fontSize: 8,
                color: widget.item.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMRTWidget() {
    // Get dimensions from grid config for MRT widget (4x2)
    final dimensions = GridConfig.getWidgetDimensions('mrt');
    final int gridWidth = dimensions['width']!;
    final int gridHeight = dimensions['height']!;

    // Calculate dimensions based on grid config
    final double width =
        GridConfig.cellSize * gridWidth +
        GridConfig.cellSpacing * (gridWidth - 1);
    final double height =
        GridConfig.cellSize * gridHeight +
        GridConfig.cellSpacing * (gridHeight - 1);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header with station name and icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.item.icon, color: widget.item.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  '台北車站',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.item.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Train arrival information
            Expanded(
              child: Row(
                children: [
                  // Northbound direction
                  Expanded(
                    child: _buildDirectionInfo(
                      '往淡水',
                      '${_northboundTime1}分',
                      '${_northboundTime2}分',
                      '${_northboundTime3}分',
                      widget.item.color,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: widget.item.color.withValues(alpha: 0.3),
                  ),
                  // Southbound direction
                  Expanded(
                    child: _buildDirectionInfo(
                      '往象山',
                      '${_southboundTime1}分',
                      '${_southboundTime2}分',
                      '${_southboundTime3}分',
                      widget.item.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionInfo(
    String direction,
    String time1,
    String time2,
    String time3,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          direction,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimeIndicator(time1, color),
            _buildTimeIndicator(time2, color),
            _buildTimeIndicator(time3, color),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeIndicator(String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
