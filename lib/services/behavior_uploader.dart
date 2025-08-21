import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import '../utils/behavior_tracker.dart';

class BehaviorUploader {
  static const String _eventsBox = 'events';

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String();
    print('[BehaviorUploader][$ts] $msg');
  }

  Future<Map<String, String>> _deviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      try {
        final android = await plugin.androidInfo;
        return {'brand': android.brand, 'model': android.model};
      } catch (_) {
        final ios = await plugin.iosInfo;
        return {'brand': 'apple', 'model': ios.utsname.machine};
      }
    } catch (_) {
      return {'brand': 'unknown', 'model': 'unknown'};
    }
  }

  String _todayYYYYMMDDUtc() {
    final now = DateTime.now().toUtc();
    return _yyyymmdd(now);
  }

  String _yyyymmdd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }

  DateTime _dayStartUtc(String yyyymmdd) {
    final y = int.parse(yyyymmdd.substring(0, 4));
    final m = int.parse(yyyymmdd.substring(4, 6));
    final d = int.parse(yyyymmdd.substring(6, 8));
    return DateTime.utc(y, m, d, 0, 0, 0);
  }

  DateTime _dayEndUtc(String yyyymmdd) {
    final start = _dayStartUtc(yyyymmdd);
    return start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
  }

  Future<int> flushToday(String uid) async {
    final day = _todayYYYYMMDDUtc();
    _log('flushToday uid=$uid day=$day');
    final n = await flushDay(uid, day);
    _log('flushToday done uploaded=$n');
    return n;
  }

  Future<void> flushIfDateChanged(String uid, String? lastSyncYYYYMMDD) async {
    final today = _todayYYYYMMDDUtc();
    if (lastSyncYYYYMMDD == null || lastSyncYYYYMMDD == today) return;
    final yesterday = _yyyymmdd(
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    await flushDay(uid, yesterday);
  }

  // 讀取並上傳某日的事件，成功後刪除本機該日事件
  Future<int> flushDay(String uid, String dayYYYYMMDD) async {
    _log('flushDay uid=$uid day=$dayYYYYMMDD open Hive');
    final Box<String> events = await Hive.openBox<String>(_eventsBox);
    _log('events.len=${events.length}');
    if (events.isEmpty) return 0;

    // 支援秒為鍵：將毫秒轉為秒
    final int startSec =
        _dayStartUtc(dayYYYYMMDD).millisecondsSinceEpoch ~/ 1000;
    final int endSec = _dayEndUtc(dayYYYYMMDD).millisecondsSinceEpoch ~/ 1000;

    final entries =
        events
            .toMap()
            .entries
            .where(
              (e) =>
                  e.key is int &&
                  (e.key as int) >= startSec &&
                  (e.key as int) <= endSec,
            )
            .toList()
          ..sort((a, b) => (a.key as int).compareTo(b.key as int));

    _log('entriesInDay=${entries.length} range=[$startSec,$endSec]');
    if (entries.isEmpty) return 0;

    final device = await _deviceInfo();
    final profile = BehaviorTracker().snapshotProfile().toJson();
    _log('device=$device');

    final windowStart = DateTime.fromMillisecondsSinceEpoch(
      startSec * 1000,
      isUtc: true,
    ).toIso8601String();
    final windowEnd = DateTime.fromMillisecondsSinceEpoch(
      endSec * 1000,
      isUtc: true,
    ).toIso8601String();

    // 事件清單（已按時間排序）
    final List<Map<String, dynamic>> allEvents = entries
        .map((e) => jsonDecode(e.value) as Map<String, dynamic>)
        .toList();
    _log('allEvents.len=${allEvents.length}');

    // 分塊上傳（<=400 筆/批）
    const int chunkSize = 400;
    int uploadedCount = 0;
    final firestore = FirebaseFirestore.instance;
    final String baseUploadTs = DateTime.now().toUtc().toIso8601String();

    for (int i = 0; i < allEvents.length; i += chunkSize) {
      final chunk = allEvents.sublist(
        i,
        i + chunkSize > allEvents.length ? allEvents.length : i + chunkSize,
      );
      final String docId = i == 0 ? baseUploadTs : '$baseUploadTs-$i';
      _log('upload chunk i=$i size=${chunk.length} docId=$docId');
      final docRef = firestore
          .collection('users')
          .doc(uid)
          .collection('days')
          .doc(dayYYYYMMDD)
          .collection('batches')
          .doc(docId);

      final payload = {
        'day':
            '${dayYYYYMMDD.substring(0, 4)}-${dayYYYYMMDD.substring(4, 6)}-${dayYYYYMMDD.substring(6, 8)}',
        'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        'count': chunk.length,
        'window': {'start': windowStart, 'end': windowEnd},
        'device': device,
        'profile': profile,
        'events': chunk,
        'schemaVersion': 1,
      };

      _log(
        'payload.count=${payload['count']} schema=${payload['schemaVersion']}',
      );
      await docRef.set(payload, SetOptions(merge: true));
      _log('uploaded doc=$docId');
      uploadedCount += chunk.length;
    }

    // 全部成功後，刪除本機該日事件
    final keysToDelete = entries.map((e) => e.key).toList();
    _log('delete local keys n=${keysToDelete.length}');
    await events.deleteAll(keysToDelete);
    _log('flushDay done uploaded=$uploadedCount');
    return uploadedCount;
  }
}
