// Dart-only client for your Metro LLM Lambda.
// No Chinese literals in code; comments are Traditional Chinese.

import 'dart:convert';
import 'package:http/http.dart' as http;

enum ChatRole { general, lostFound, emergency }

extension ChatRoleJson on ChatRole {
  String get json => switch (this) {
    ChatRole.general => 'general',
    ChatRole.lostFound => 'lost_found',
    ChatRole.emergency => 'emergency',
  };
  static ChatRole? fromJson(String? v) {
    return switch (v) {
      'general' => ChatRole.general,
      'lost_found' => ChatRole.lostFound,
      'emergency' => ChatRole.emergency,
      _ => null,
    };
  }
}

class ChatMessage {
  // role: 'user' or 'assistant'
  final String role;
  final String content;
  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatResponse {
  final ChatRole? role;
  final String reply;
  final String? model;
  const ChatResponse({required this.role, required this.reply, this.model});

  factory ChatResponse.fromJson(Map<String, dynamic> j) {
    return ChatResponse(
      role: ChatRoleJson.fromJson(j['role'] as String?),
      reply: (j['reply'] ?? '').toString(),
      model: j['model'] as String?,
    );
  }
}

class MetroChatError implements Exception {
  final int statusCode;
  final String code;
  final String? detail;
  MetroChatError(this.statusCode, this.code, this.detail);
  @override
  String toString() => 'MetroChatError($statusCode, $code, $detail)';
}

class MetroChatClient {
  final String endpoint; // e.g. https://.../metro-customer-service
  final String? bearer; // optional auth header if you add it later
  final Duration timeout;

  MetroChatClient({
    required this.endpoint,
    this.bearer,
    this.timeout = const Duration(seconds: 20),
  });

  void _log(String m) {
    final ts = DateTime.now().toIso8601String();
    print('[MetroChatClient][$ts] $m');
  }

  Future<ChatResponse> send({
    required String message,
    required ChatRole role,
    List<ChatMessage> history = const [],
    String? userId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (bearer != null && bearer!.isNotEmpty)
        'Authorization': 'Bearer $bearer',
    };

    final body = <String, dynamic>{
      'message': message,
      'role': role.json,
      if (history.isNotEmpty)
        'history': history.map((m) => m.toJson()).toList(),
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
    };

    final bodyStr = json.encode(body);
    _log('POST $endpoint');
    _log('req.headers: ${json.encode(headers)}');
    _log('req.body.len=${bodyStr.length}');
    _log(bodyStr);

    final resp = await http
        .post(Uri.parse(endpoint), headers: headers, body: json.encode(body))
        .timeout(timeout);

    _log('status=${resp.statusCode}');
    _log('resp.body.len=${resp.body.length}');
    _log(resp.body);

    if (resp.statusCode == 200) {
      final j = json.decode(resp.body) as Map<String, dynamic>;
      return ChatResponse.fromJson(j);
    } else {
      // Expect Lambda error schema: {"error":"...", "detail":"..."}
      try {
        final j = json.decode(resp.body) as Map<String, dynamic>;
        throw MetroChatError(
          resp.statusCode,
          (j['error'] ?? 'unknown_error').toString(),
          j['detail']?.toString(),
        );
      } catch (_) {
        throw MetroChatError(resp.statusCode, 'http_error', resp.body);
      }
    }
  }
}
