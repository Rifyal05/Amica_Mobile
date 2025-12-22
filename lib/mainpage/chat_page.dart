import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/chat_provider.dart';
import '../provider/auth_provider.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatImage;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chatImage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProv = Provider.of<ChatProvider>(context, listen: false);
      final authProv = Provider.of<AuthProvider>(context, listen: false);

      chatProv.fetchMessages(widget.chatId);

      if (authProv.isLoggedIn && authProv.token != null) {
        chatProv.connectSocket(authProv.token!, authProv.currentUser?.id ?? "");
        chatProv.socket?.emit('join_chat', {'chat_id': widget.chatId});
      }

      chatProv.markChatAsRead(widget.chatId);
    });
  }

  void _onTextChanged(String text) {
    final chatProv = context.read<ChatProvider>();
    chatProv.sendTyping(widget.chatId, true);
    if (_typingTimer != null) _typingTimer!.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      chatProv.sendTyping(widget.chatId, false);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final myUserId = context.read<AuthProvider>().currentUser?.id;
    if (myUserId == null) return;

    context.read<ChatProvider>().sendMessage(widget.chatId, text, myUserId);
    _messageController.clear();
    context.read<ChatProvider>().sendTyping(widget.chatId, false);
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text(
              "Blokir Pengguna",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fitur Blokir akan segera hadir")),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Hapus Percakapan"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProv = context.watch<AuthProvider>();

    final bool hasImage =
        widget.chatImage != null && widget.chatImage!.isNotEmpty;
    ImageProvider? imageProvider;
    if (hasImage) {
      imageProvider = NetworkImage(widget.chatImage!);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: imageProvider,
              child: !hasImage ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProv, _) {
                  final typingUser = chatProv.getTypingUser(widget.chatId);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (typingUser != null)
                        const Text(
                          "Sedang mengetik...",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showChatMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProv, child) {
                final messages = chatProv.getMessages(widget.chatId);

                if (messages.isNotEmpty &&
                    !messages.first.isRead &&
                    messages.first.senderId != authProv.currentUser?.id) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    chatProv.markChatAsRead(widget.chatId);
                  });
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "Mulai percakapan...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == authProv.currentUser?.id;

                    bool showAvatar = !isMe;
                    if (index + 1 < messages.length) {
                      final prevMsg = messages[index + 1];
                      if (prevMsg.senderId == msg.senderId) {
                        showAvatar = false;
                      }
                    }

                    return _MessageBubble(
                      text: msg.text ?? "",
                      isMe: isMe,
                      time: msg.sentAt,
                      isRead: msg.isRead,
                      showAvatar: showAvatar,
                      avatarUrl: widget.chatImage,
                    );
                  },
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
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
  final DateTime time;
  final bool isRead;
  final bool showAvatar;
  final String? avatarUrl;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.isRead,
    this.showAvatar = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm').format(time.toLocal());

    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar ? 12 : 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 16)
                    : null,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : (showAvatar
                                ? Radius.zero
                                : const Radius.circular(16)),
                      bottomRight: isMe
                          ? (showAvatar
                                ? Radius.zero
                                : const Radius.circular(16))
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4, left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: isRead ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
