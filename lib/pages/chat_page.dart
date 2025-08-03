import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadFakeMessages();
  }

  void _loadFakeMessages() {
    _messages.addAll([
      ChatMessage(
        text: '你好！歡迎使用 Metro App',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        text: '謝謝！這個 app 很棒',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatMessage(
        text: '有任何問題都可以問我',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      ChatMessage(
        text: '好的，我會的',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ]);
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    print('嘗試發送訊息: $messageText'); // 調試信息

    if (messageText.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(text: messageText, isMe: true, timestamp: DateTime.now()),
        );
      });
      print('訊息已添加到列表，總共 ${_messages.length} 條訊息'); // 調試信息
      _messageController.clear();

      // 滾動到最新消息
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // 模擬自動回覆
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: '收到你的訊息了！',
                isMe: false,
                timestamp: DateTime.now(),
              ),
            );
          });
          print('自動回覆已添加，總共 ${_messages.length} 條訊息'); // 調試信息

          // 滾動到最新消息
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    } else {
      print('訊息為空，無法發送'); // 調試信息
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天室'),
        backgroundColor: const Color(0xFF114D4D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF22303C),
              border: Border(
                top: BorderSide(color: const Color(0xFF114D4D), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: const Color(0xFF114D4D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: const Color(0xFF114D4D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: const Color(0xFF26C6DA),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF26C6DA),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF26C6DA),
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe
                    ? const Color(0xFF26C6DA)
                    : const Color(0xFF114D4D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF26C6DA),
              child: Text(
                '我',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
