import 'package:flutter/material.dart';

class VersionUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String? diaryText;
  final bool isForceUpdate;
  final bool isPatchUpdate;

  const VersionUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    this.diaryText,
    this.isForceUpdate = false,
    this.isPatchUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF22303C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isForceUpdate ? Icons.system_update : Icons.info_outline,
            color: isForceUpdate ? Colors.orange : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isForceUpdate ? '需要更新' : '建議更新',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isForceUpdate
                ? '您的應用程式版本過舊，需要更新到最新版本才能繼續使用。'
                : '有新版本可用，建議您更新以獲得最佳體驗。',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2327),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '當前版本: $currentVersion',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '最新版本: $latestVersion',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (diaryText != null && diaryText!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2327),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF26C6DA), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book, color: Color(0xFF26C6DA), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '更新日誌',
                        style: TextStyle(
                          color: Color(0xFF26C6DA),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diaryText!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!isForceUpdate) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '稍後再說',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF114D4D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isForceUpdate ? '我知道了' : '我知道了',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}
