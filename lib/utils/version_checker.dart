import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:pub_semver/pub_semver.dart';

class VersionChecker {
  static const String _configCollection = 'config';
  static const String _appDocId = 'app';
  static const String _latestVersionField = 'latestVersion';
  static const String _diaryField = 'diary';
  static const String _remoteConfigKey = 'latest_version';

  /// 獲取本地版本
  Future<Version> _getLocalVersion() async {
    final info = await PackageInfo.fromPlatform();
    return Version.parse(info.version);
  }

  /// 從 Firestore 獲取最新版本
  Future<Version> _getFirestoreVersion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_configCollection)
          .doc(_appDocId)
          .get();
      
      if (!doc.exists) {
        throw Exception('版本配置文檔不存在');
      }
      
      final data = doc.data();
      if (data == null || !data.containsKey(_latestVersionField)) {
        throw Exception('版本配置欄位不存在');
      }
      
      final versionString = data[_latestVersionField] as String;
      return Version.parse(versionString);
    } catch (e) {
      debugPrint('從 Firestore 獲取版本失敗: $e');
      rethrow;
    }
  }

  /// 從 Firestore 獲取日誌文字
  Future<String> getDiaryText() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_configCollection)
          .doc(_appDocId)
          .get();
      
      if (!doc.exists) {
        return '日誌載入失敗';
      }
      
      final data = doc.data();
      if (data == null || !data.containsKey(_diaryField)) {
        return '日誌內容不存在';
      }
      
      return data[_diaryField] as String? ?? '日誌內容為空';
    } catch (e) {
      debugPrint('從 Firestore 獲取日誌失敗: $e');
      return '日誌載入失敗: $e';
    }
  }

  /// 檢查是否需要強制更新
  /// 當 major 或 minor 版本不同時，返回 true
  Future<bool> shouldForceUpdate() async {
    try {
      final localVersion = await _getLocalVersion();
      final remoteVersion = await _getFirestoreVersion(); // 或使用 _getRemoteConfigVersion()
      
      // 當 major 或 minor 版本不同時，需要強制更新
      return localVersion.major != remoteVersion.major || 
             localVersion.minor != remoteVersion.minor;
    } catch (e) {
      debugPrint('版本檢查失敗: $e');
      // 如果檢查失敗，預設不強制更新
      return false;
    }
  }

  /// 獲取遠端最新版本字串
  Future<String> getLatestVersionString() async {
    try {
      final remoteVersion = await _getFirestoreVersion();
      return remoteVersion.toString();
    } catch (e) {
      debugPrint('獲取最新版本字串失敗: $e');
      return '未知';
    }
  }

  /// 獲取本地版本字串
  Future<String> getLocalVersionString() async {
    try {
      final localVersion = await _getLocalVersion();
      return localVersion.toString();
    } catch (e) {
      debugPrint('獲取本地版本字串失敗: $e');
      return '未知';
    }
  }

  /// 檢查是否為 patch 更新
  Future<bool> isPatchUpdate() async {
    try {
      final localVersion = await _getLocalVersion();
      final remoteVersion = await _getFirestoreVersion();
      
      // 當 major 和 minor 相同，但 patch 不同時，為 patch 更新
      return localVersion.major == remoteVersion.major && 
             localVersion.minor == remoteVersion.minor &&
             localVersion.patch != remoteVersion.patch;
    } catch (e) {
      debugPrint('檢查 patch 更新失敗: $e');
      return false;
    }
  }
}
