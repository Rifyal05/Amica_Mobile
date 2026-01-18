import 'dart:async';
import 'package:amica/mainpage/widgets/verified_badge.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/chat_provider.dart';
import '../provider/auth_provider.dart';
import '../services/api_config.dart';
import '../models/messages_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'group_info_page.dart';
import 'user_profile_page.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatImage;
  final bool isGroup;
  final String? targetUserId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chatImage,
    this.isGroup = false,
    this.targetUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final UserService _userService = UserService();
  ChatMessage? _replyingTo;
  Timer? _typingTimer;
  bool _iBlockedThisUser = false;
  bool _isTargetVerified = false;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
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

  void _checkBlockStatus() async {
    if (widget.targetUserId == null || widget.isGroup) return;
    final profile = await _userService.getUserProfile(widget.targetUserId!);
    if (mounted && profile != null) {
      setState(() {
        _iBlockedThisUser = profile.status.isBlocked;
        _isTargetVerified = profile.isVerified;
      });
    }
  }

  void _showTopSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onTextChanged(String text) {
    context.read<ChatProvider>().sendTyping(widget.chatId, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      context.read<ChatProvider>().sendTyping(widget.chatId, false);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final myUser = context.read<AuthProvider>().currentUser;
    if (myUser == null) return;

    context.read<ChatProvider>().sendMessage(
      widget.chatId,
      text,
      myUser.id,
      myName: myUser.displayName,
      myAvatar: myUser.avatarUrl,
      replyToId: _replyingTo?.id,
    );
    _messageController.clear();
    setState(() => _replyingTo = null);
    context.read<ChatProvider>().sendTyping(widget.chatId, false);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onReply(ChatMessage msg) {
    if (msg.isDeleted) return;
    setState(() => _replyingTo = msg);
    _focusNode.requestFocus();
  }

  void _deleteMessage(String msgId) {
    context.read<ChatProvider>().deleteMessage(widget.chatId, msgId);
    _showTopSnackbar("Pesan dihapus");
  }

  void _handleBlock() async {
    if (widget.targetUserId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Blokir Pengguna?"),
        content: const Text(
          "Anda tidak akan menerima pesan dari pengguna ini lagi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Blokir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _userService.blockUser(widget.targetUserId!);
      if (mounted) {
        if (success) {
          setState(() => _iBlockedThisUser = true);
          _showTopSnackbar("Pengguna berhasil diblokir");
        } else {
          _showTopSnackbar("Gagal memproses permintaan", isError: true);
        }
      }
    }
  }

  void _handleUnblock() async {
    if (widget.targetUserId == null) return;
    final success = await _userService.unblockUser(widget.targetUserId!);
    if (mounted) {
      if (success) {
        setState(() => _iBlockedThisUser = false);
        _showTopSnackbar("Blokir berhasil dibuka");
      } else {
        _showTopSnackbar("Gagal membuka blokir", isError: true);
      }
    }
  }

  void _scrollToMessage(String? targetMsgId) {
    if (targetMsgId == null) return;
    final chatProv = context.read<ChatProvider>();
    final messages = chatProv.getMessages(widget.chatId);
    final index = messages.indexWhere((m) => m.id == targetMsgId);
    if (index != -1) {
      _scrollController.animateTo(
        index * 70.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _showActionMenu(ChatMessage msg, bool isMe) {
    if (msg.isDeleted && !isMe) return;

    _focusNode.unfocus();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (!msg.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text("Balas"),
                onTap: () {
                  Navigator.pop(ctx);
                  _onReply(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Salin Teks"),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.text ?? ""));
                  _showTopSnackbar("Pesan disalin");
                },
              ),
            ],
            if (isMe && !msg.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Hapus Pesan",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(msg.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuOption(String value) {
    switch (value) {
      case 'info':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupInfoPage(chatId: widget.chatId),
          ),
        );
        break;
      case 'profile':
        if (widget.targetUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(userId: widget.targetUserId!),
            ),
          );
        }
        break;
      case 'block':
        _handleBlock();
        break;
      case 'clear':
        context.read<ChatProvider>().clearChat(widget.chatId);
        _showTopSnackbar("Chat dibersihkan untuk Anda");
        break;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    final d1 = date1.toLocal();
    final d2 = date2.toLocal();
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final localDate = date.toLocal();
    final messageDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    if (messageDate == today) {
      return "Hari Ini";
    } else if (messageDate == yesterday) {
      return "Kemarin";
    } else {
      try {
        return DateFormat('d MMMM yyyy', 'id_ID').format(localDate);
      } catch (e) {
        return DateFormat('d MMMM yyyy').format(localDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = context.read<AuthProvider>().currentUser?.id;
    final bool hasImage =
        widget.chatImage != null && widget.chatImage!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onTap: () {
            if (widget.isGroup) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupInfoPage(chatId: widget.chatId),
                ),
              );
            } else if (widget.targetUserId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: widget.targetUserId!),
                ),
              );
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: hasImage
                      ? NetworkImage(widget.chatImage!)
                      : null,
                  child: !hasImage
                      ? Icon(widget.isGroup ? Icons.groups : Icons.person)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, chatProv, _) {
                      final typingUser = chatProv.getTypingUser(widget.chatId);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.chatName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isTargetVerified)
                                const VerifiedBadge(size: 16),
                            ],
                          ),
                          if (typingUser != null)
                            Text(
                              widget.isGroup
                                  ? "$typingUser mengetik..."
                                  : "Sedang mengetik...",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Text(
                              widget.isGroup
                                  ? "Ketuk untuk info grup"
                                  : "Ketuk untuk lihat profil",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuOption,
            itemBuilder: (BuildContext context) {
              return [
                if (widget.isGroup)
                  const PopupMenuItem(value: 'info', child: Text("Info Grup")),
                if (!widget.isGroup) ...[
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text("Lihat Profil"),
                  ),
                  if (!_iBlockedThisUser)
                    const PopupMenuItem(
                      value: 'block',
                      child: Text(
                        "Blokir Pengguna",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
                const PopupMenuItem(
                  value: 'clear',
                  child: Text("Bersihkan Chat"),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProv, child) {
                  final messages = chatProv.getMessages(widget.chatId);

                  if (messages.isNotEmpty &&
                      !messages.first.isRead &&
                      messages.first.senderId != myId) {
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
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == myId;

                      if (msg.type == 'system') {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg.text ?? "",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }

                      bool showAvatar = !isMe;
                      if (index + 1 < messages.length) {
                        final prevMsg = messages[index + 1];
                        if (prevMsg.senderId == msg.senderId &&
                            prevMsg.type != 'system') {
                          showAvatar = false;
                        }
                      }

                      bool showDate = false;
                      if (index == messages.length - 1) {
                        showDate = true;
                      } else {
                        final nextMsg = messages[index + 1];
                        if (!_isSameDay(msg.sentAt, nextMsg.sentAt)) {
                          showDate = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDate)
                            _DateChip(text: _formatDateSeparator(msg.sentAt)),
                          Dismissible(
                            key: Key("msg_${msg.id}"),
                            direction: msg.isDeleted
                                ? DismissDirection.none
                                : DismissDirection.startToEnd,
                            dismissThresholds: const {
                              DismissDirection.startToEnd: 0.2,
                            },
                            movementDuration: const Duration(milliseconds: 200),
                            onDismissed: (_) => _onReply(msg),
                            confirmDismiss: (_) async {
                              if (!msg.isDeleted) {
                                _onReply(msg);
                              }
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: Icon(
                                Icons.reply,
                                color: theme.primaryColor,
                              ),
                            ),
                            child: GestureDetector(
                              onLongPress: () => _showActionMenu(msg, isMe),
                              child: _MessageBubble(
                                msg: msg,
                                isMe: isMe,
                                showAvatar: showAvatar,
                                isGroup: widget.isGroup,
                                currentChatId: widget.chatId,
                                onReplyTap: (id) => _scrollToMessage(id),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(Icons.reply, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Membalas ${_replyingTo!.senderName ?? 'Unknown'}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Text(
                            _replyingTo!.text ?? "...",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),
            if (_iBlockedThisUser)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.red.withOpacity(0.1),
                child: Column(
                  children: [
                    const Text(
                      "Anda telah memblokir pengguna ini",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _handleUnblock,
                      child: const Text("Buka Blokir untuk mengirim pesan"),
                    ),
                  ],
                ),
              )
            else
              _buildMessageInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  onChanged: _onTextChanged,
                  minLines: 1,
                  maxLines: 4,
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
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String text;
  const _DateChip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _InviteCard extends StatefulWidget {
  final String inviteLink;
  final bool isMe;
  final String currentChatId;

  const _InviteCard({
    required this.inviteLink,
    required this.isMe,
    required this.currentChatId,
  });

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  static final Set<String> _invalidTokens = {};
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  bool _isInvalid = false;
  String _groupName = "Undangan Grup";
  String? _groupImage;
  int _memberCount = 0;
  bool _isAlreadyMember = false;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    final token = widget.inviteLink.split('/').last;
    if (token.isEmpty) return;

    if (_invalidTokens.contains(token)) {
      if (mounted) {
        setState(() {
          _isInvalid = true;
          _isLoading = false;
          _groupName = "Link tidak valid";
        });
      }
      return;
    }

    try {
      final data = await _chatService.getInviteInfo(token);
      if (mounted) {
        setState(() {
          _groupName = data['name'] ?? "Grup";
          _groupImage = data['image_url'];
          _memberCount = data['member_count'] ?? 0;
          _isAlreadyMember = data['is_member'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      _invalidTokens.add(token);
      if (mounted) {
        setState(() {
          _isInvalid = true;
          _isLoading = false;
          _groupName = "Link tidak valid";
        });
      }
    }
  }

  Future<void> _handleButtonPress() async {
    final token = widget.inviteLink.split('/').last;
    if (token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _chatService.joinGroup(token);
      if (mounted) {
        setState(() {
          _isAlreadyMember = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil bergabung!")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String err = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = widget.isMe
        ? Colors.black.withOpacity(0.1)
        : theme.colorScheme.surface;

    final fullImageUrl = _groupImage != null
        ? ApiConfig.getFullUrl(_groupImage)
        : null;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: fullImageUrl != null
                    ? NetworkImage(fullImageUrl)
                    : null,
                child: fullImageUrl == null
                    ? const Icon(Icons.groups, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Undangan Grup Amica",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _groupName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: widget.isMe
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!_isLoading && !_isInvalid)
                      Text(
                        "$_memberCount Anggota",
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: (_isLoading || _isAlreadyMember || _isInvalid)
                  ? null
                  : _handleButtonPress,
              style: FilledButton.styleFrom(
                backgroundColor: (_isAlreadyMember || _isInvalid)
                    ? Colors.grey.shade500
                    : theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isInvalid
                          ? "Link Kadaluarsa"
                          : (_isAlreadyMember
                                ? "Anda Sudah Bergabung"
                                : "Gabung Grup"),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final bool showAvatar;
  final bool isGroup;
  final String currentChatId;
  final Function(String?)? onReplyTap;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    this.showAvatar = false,
    this.isGroup = false,
    required this.currentChatId,
    this.onReplyTap,
  });

  void _navigateToProfile(BuildContext context) {
    if (msg.senderId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfilePage(userId: msg.senderId!),
        ),
      );
    }
  }

  bool _isInviteLink(String text) {
    return (text.contains("/join/") && text.startsWith("http")) ||
        text.startsWith("amica://join/");
  }

  Widget _buildMessageContent(BuildContext context, ThemeData theme) {
    final text = msg.text ?? "";

    return Linkify(
      onOpen: (link) async {
        final uri = Uri.parse(link.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      text: text,
      style: TextStyle(
        color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        fontSize: 15,
      ),
      linkStyle: TextStyle(
        color: isMe ? Colors.white : Colors.blue,
        decoration: TextDecoration.none,
        fontWeight: FontWeight.bold,
      ),
      options: const LinkifyOptions(humanize: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm').format(msg.sentAt.toLocal());
    const double avatarSize = 18.0;
    final bool isInvite = _isInviteLink(msg.text ?? "");

    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar ? 12.0 : 4.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              GestureDetector(
                onTap: () => _navigateToProfile(context),
                child: CircleAvatar(
                  radius: avatarSize,
                  backgroundImage: (msg.senderAvatar != null)
                      ? NetworkImage(msg.senderAvatar!)
                      : null,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: (msg.senderAvatar == null)
                      ? Icon(
                          Icons.person,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              )
            else
              SizedBox(width: avatarSize * 2),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (isGroup && !isMe && showAvatar && msg.senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: GestureDetector(
                      onTap: () => _navigateToProfile(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              msg.senderName!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (msg.senderIsVerified)
                            const VerifiedBadge(
                              size: 10,
                              padding: EdgeInsets.only(left: 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (msg.replyTo != null)
                  GestureDetector(
                    onTap: () => onReplyTap?.call(msg.replyTo!['id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(color: theme.primaryColor, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.replyTo!['sender_name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: theme.primaryColor,
                            ),
                          ),
                          Text(
                            msg.replyTo!['text'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isDeleted
                        ? Colors.grey[300]
                        : (isMe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(showAvatar && !isMe ? 4 : 18),
                      topRight: Radius.circular(showAvatar && isMe ? 4 : 18),
                      bottomLeft: const Radius.circular(18),
                      bottomRight: const Radius.circular(18),
                    ),
                  ),
                  child: msg.isDeleted
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              "Pesan ini telah dihapus",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : (isInvite
                            ? _InviteCard(
                                inviteLink: msg.text!,
                                isMe: isMe,
                                currentChatId: currentChatId,
                              )
                            : _buildMessageContent(context, theme)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 2, left: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead
                              ? Icons.done_all
                              : (msg.isDelivered
                                    ? Icons.done_all
                                    : Icons.check),
                          size: 14,
                          color: msg.isRead
                              ? Colors.lightBlueAccent
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
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
