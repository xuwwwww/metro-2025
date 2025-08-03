import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_item.dart';

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

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
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
}
