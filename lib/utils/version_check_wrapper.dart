import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'version_checker.dart';
import '../widgets/version_update_dialog.dart';

class VersionCheckWrapper {
  static const String _lastPatchUpdateKey = 'last_patch_update_check';
  static const Duration _patchUpdateCooldown = Duration(days: 1);

  /// 在應用啟動時檢查版本
  static Future<void> checkVersionOnStartup(BuildContext context) async {
    try {
      final checker = VersionChecker();

      // 檢查是否需要強制更新
      final shouldForceUpdate = await checker.shouldForceUpdate();

      if (shouldForceUpdate && context.mounted) {
        // 強制更新，顯示對話框並阻止繼續
        await _showForceUpdateDialog(context, checker);
        return;
      }

      // 檢查是否為 patch 更新
      final isPatchUpdate = await checker.isPatchUpdate();

      if (isPatchUpdate && context.mounted) {
        // 檢查是否在冷卻期內
        final shouldShowPatchUpdate = await _shouldShowPatchUpdate();

        if (shouldShowPatchUpdate) {
          // 顯示建議更新對話框
          await _showPatchUpdateDialog(context, checker);
        }
      }
    } catch (e) {
      debugPrint('版本檢查失敗: $e');
      // 版本檢查失敗時不阻止應用啟動
    }
  }

  /// 顯示強制更新對話框
  static Future<void> _showForceUpdateDialog(
    BuildContext context,
    VersionChecker checker,
  ) async {
    final currentVersion = await checker.getLocalVersionString();
    final latestVersion = await checker.getLatestVersionString();
    final diaryText = await checker.getDiaryText();

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 強制更新時不能關閉
      builder: (context) => VersionUpdateDialog(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        diaryText: diaryText,
        isForceUpdate: true,
      ),
    );

    // 當用戶點擊「我知道了」後，退出應用程式
    if (result == true) {
      exit(0); // 強制退出應用程式
    } else {
      // 如果用戶關閉對話框（理論上不會發生），再次顯示
      if (context.mounted) {
        await _showForceUpdateDialog(context, checker);
      }
    }
  }

  /// 顯示建議更新對話框
  static Future<void> _showPatchUpdateDialog(
    BuildContext context,
    VersionChecker checker,
  ) async {
    final currentVersion = await checker.getLocalVersionString();
    final latestVersion = await checker.getLatestVersionString();
    final diaryText = await checker.getDiaryText();

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => VersionUpdateDialog(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        diaryText: diaryText,
        isForceUpdate: false,
        isPatchUpdate: true,
      ),
    );

    // 記錄 patch 更新檢查時間
    if (result != null) {
      await _recordPatchUpdateCheck();
    }
  }

  /// 檢查是否應該顯示 patch 更新提示
  static Future<bool> _shouldShowPatchUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_lastPatchUpdateKey);

      if (lastCheckTime == null) {
        return true;
      }

      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
      final now = DateTime.now();

      return now.difference(lastCheck) > _patchUpdateCooldown;
    } catch (e) {
      debugPrint('檢查 patch 更新時間失敗: $e');
      return true; // 如果檢查失敗，預設顯示
    }
  }

  /// 記錄 patch 更新檢查時間
  static Future<void> _recordPatchUpdateCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastPatchUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('記錄 patch 更新檢查時間失敗: $e');
    }
  }

  /// 手動檢查版本（可在設定頁面調用）
  static Future<void> manualVersionCheck(BuildContext context) async {
    try {
      final checker = VersionChecker();

      // 檢查是否需要強制更新
      final shouldForceUpdate = await checker.shouldForceUpdate();

      if (shouldForceUpdate && context.mounted) {
        await _showForceUpdateDialog(context, checker);
        return;
      }

      // 檢查是否為 patch 更新
      final isPatchUpdate = await checker.isPatchUpdate();

      if (isPatchUpdate && context.mounted) {
        await _showPatchUpdateDialog(context, checker);
      } else {
        // 顯示已是最新版本
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('您使用的是最新版本'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('手動版本檢查失敗: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('版本檢查失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
