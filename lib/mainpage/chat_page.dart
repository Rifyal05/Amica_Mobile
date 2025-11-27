import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class Message {
  final String text;
  final bool isMe;
  final String time;

  Message(this.text, this.isMe, this.time);
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();

  final List<Message> _messages = [
    Message('Sama-sama, semoga membantu ya!', false, '10:05'),
    Message('Terima kasih banyak atas sarannya, Dok.', true, '10:04'),
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(0, Message(text, true, 'Now'));
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRrHHSURcy1oXxHIo0Kp4TBOAI_I-X0PDCnGg&s')),
            SizedBox(width: 12),
            Text('Dr. Anisa, Sp.A'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(
                  text: message.text,
                  isMe: message.isMe,
                  time: message.time,
                );
              },
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.primary),
              onPressed: _sendMessage, // Panggil fungsi _sendMessage yang baru
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}