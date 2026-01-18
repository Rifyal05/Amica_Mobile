import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_model.dart';
import '../models/messages_model.dart';
import '../models/user_model.dart';
import '../services/api_config.dart';
import '../services/authenticated_client.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final AuthenticatedClient _client = AuthenticatedClient();
  final ChatService _service = ChatService();
  IO.Socket? socket;

  List<ChatRoom> _inbox = [];
  final Map<String, List<ChatMessage>> _messagesCache = {};
  final Map<String, String?> _typingStatus = {};

  String? _myUserId;
  bool _isLoading = false;

  Function(String, String, String)? onModerationBlocked;
  Function(String, String)? onModerationWarning;

  List<ChatRoom> get inbox => _inbox;
  bool get isLoading => _isLoading;

  int get unreadMessageCount {
    return _inbox.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  List<ChatMessage> getMessages(String chatId) {
    return _messagesCache[chatId] ?? [];
  }

  String? getTypingUser(String chatId) => _typingStatus[chatId];

  void clearData() {
    _inbox.clear();
    _messagesCache.clear();
    _typingStatus.clear();
    _myUserId = null;

    if (socket != null) {
      socket!.io.options?['autoConnect'] = false;
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }
    notifyListeners();
  }

  void markChatAsRead(String chatId) {
    int index = _inbox.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      var old = _inbox[index];
      if (old.unreadCount > 0) {
        _inbox[index] = ChatRoom(
          id: old.id,
          name: old.name,
          imageUrl: old.imageUrl,
          isGroup: old.isGroup,
          lastMessage: old.lastMessage,
          lastMessageTime: old.lastMessageTime,
          unreadCount: 0,
          targetUserId: old.targetUserId,
          targetUsername: old.targetUsername,
          isBlockedByMe: old.isBlockedByMe,
        );
        notifyListeners();
      }
    }
    socket?.emit('mark_read', {'chat_id': chatId});
  }

  Future<void> fetchInbox() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chats/inbox'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _inbox = data.map((json) => ChatRoom.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String chatId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chats/$chatId/messages'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final newMessages = data
            .map((json) => ChatMessage.fromJson(json))
            .toList();
        _messagesCache[chatId] = newMessages;
        notifyListeners();
        markChatAsRead(chatId);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String?> createGroup(
    String name,
    File? image,
    List<User> members,
    bool allowInvites,
  ) async {
    try {
      List<String> memberIds = members.map((u) => u.id).toList();
      final res = await _service.createGroup(
        name,
        image,
        memberIds,
        allowInvites,
      );
      if (res['success'] == true) {
        fetchInbox();
        return res['chat_id'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> leaveGroup(String chatId) async {
    await _service.leaveGroup(chatId);
    _inbox.removeWhere((c) => c.id == chatId);
    notifyListeners();
  }

  Future<void> clearChat(String chatId) async {
    await _service.clearChat(chatId);
    _messagesCache[chatId] = [];
    notifyListeners();
  }

  Future<void> deleteMessage(String chatId, String msgId) async {
    final msgs = _messagesCache[chatId];
    if (msgs != null) {
      final idx = msgs.indexWhere((m) => m.id == msgId);
      if (idx != -1) {
        msgs[idx] = msgs[idx].copyWith(
          isDeleted: true,
          text: "🚫 Pesan ini telah dihapus",
        );
        notifyListeners();
      }
    }
    await _service.deleteMessage(msgId);
  }

  void connectSocket(String token, String myUserId) {
    if (_myUserId == myUserId && socket != null && socket!.connected) return;

    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
    }

    _myUserId = myUserId;

    socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .enableAutoConnect()
          .enableForceNew()
          .build(),
    );

    socket!.onConnect((_) {});

    socket!.onDisconnect((_) {});

    socket!.on('new_message', (data) {
      final newMessage = ChatMessage.fromJson(data);
      final currentList = _messagesCache[newMessage.chatId] ?? [];
      if (newMessage.senderId != _myUserId &&
          !newMessage.id.startsWith('temp_')) {
        socket!.emit('message_received', {
          'message_id': newMessage.id,
          'chat_id': newMessage.chatId,
          'sender_id': newMessage.senderId,
        });
      }

      final tempIndex = currentList.indexWhere(
        (m) =>
            m.id.startsWith('temp_') &&
            m.text == newMessage.text &&
            m.senderId == newMessage.senderId,
      );

      if (tempIndex != -1) {
        currentList[tempIndex] = newMessage;
      } else {
        if (!currentList.any((m) => m.id == newMessage.id)) {
          currentList.insert(0, newMessage);
        }
      }

      _messagesCache[newMessage.chatId] = currentList;
      _updateInboxLocal(newMessage);
      notifyListeners();
    });

    socket!.on('message_deleted', (data) {
      String chatId = data['chat_id'];
      String msgId = data['msg_id'];
      final list = _messagesCache[chatId];
      if (list != null) {
        final idx = list.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(
            isDeleted: true,
            text: "🚫 Pesan ini telah dihapus",
          );
        }
      }

      int inboxIdx = _inbox.indexWhere((c) => c.id == chatId);
      if (inboxIdx != -1) {
        var chat = _inbox[inboxIdx];
        _inbox[inboxIdx] = ChatRoom(
          id: chat.id,
          name: chat.name,
          imageUrl: chat.imageUrl,
          isGroup: chat.isGroup,
          lastMessage: "🚫 Pesan ini telah dihapus",
          lastMessageTime: chat.lastMessageTime,
          unreadCount: chat.unreadCount,
          targetUserId: chat.targetUserId,
          targetUsername: chat.targetUsername,
          isBlockedByMe: chat.isBlockedByMe,
        );
      }
      notifyListeners();
    });

    socket!.on('messages_read', (data) {
      String chatId = data['chat_id'];
      if (_messagesCache.containsKey(chatId)) {
        final messages = _messagesCache[chatId]!;
        _messagesCache[chatId] = messages.map((msg) {
          if (!msg.isRead && msg.senderId == _myUserId) {
            return msg.copyWith(isRead: true, isDelivered: true);
          }
          return msg;
        }).toList();
        notifyListeners();
      }
    });

    socket!.on('message_delivered', (data) {
      String chatId = data['chat_id'];
      String msgId = data['message_id'];
      if (_messagesCache.containsKey(chatId)) {
        final messages = _messagesCache[chatId]!;
        final idx = messages.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          messages[idx] = messages[idx].copyWith(isDelivered: true);
          notifyListeners();
        }
      }
    });

    socket!.on('inbox_update', (data) {
      _updateInboxLocalFromSocket(data);
    });

    socket!.on('user_typing', (data) {
      String chatId = data['chat_id'] ?? '';
      bool isTyping = data['is_typing'] ?? false;
      String username = data['username'] ?? '';
      _typingStatus[chatId] = isTyping ? username : null;
      notifyListeners();
    });

    socket!.on('moderation_blocked', (data) {
      if (onModerationBlocked != null) {
        onModerationBlocked!(
          data['chat_id'],
          data['user_name'],
          data['user_id'],
        );
      }
      fetchInbox();
    });

    socket!.on('moderation_warning', (data) {
      if (onModerationWarning != null) {
        onModerationWarning!(data['chat_id'], data['warning']);
      }
    });

    socket!.connect();
  }

  void _updateInboxLocal(ChatMessage msg) {
    int index = _inbox.indexWhere((c) => c.id == msg.chatId);
    String senderDisplayName = "";
    if (msg.senderId == _myUserId) {
      senderDisplayName = "Anda";
    } else {
      senderDisplayName = msg.senderName ?? "";
    }

    if (index != -1) {
      var oldChat = _inbox[index];
      int newUnread = (msg.senderId == _myUserId) ? 0 : oldChat.unreadCount + 1;

      _inbox.removeAt(index);
      _inbox.insert(
        0,
        ChatRoom(
          id: oldChat.id,
          name: oldChat.name,
          imageUrl: oldChat.imageUrl,
          isGroup: oldChat.isGroup,
          lastMessage: msg.isDeleted ? "🚫 Pesan ini telah dihapus" : msg.text,
          lastSenderName: senderDisplayName,
          lastMessageTime: msg.sentAt,
          unreadCount: newUnread,
          targetUserId: oldChat.targetUserId,
          targetUsername: oldChat.targetUsername,
          isBlockedByMe: oldChat.isBlockedByMe,
        ),
      );
      notifyListeners();
    } else {
      fetchInbox();
    }
  }

  Future<void> deleteConversation(String chatId) async {
    final success = await _service.deleteConversationPermanently(chatId);
    if (success) {
      _inbox.removeWhere((c) => c.id == chatId);
      _messagesCache.remove(chatId);
      notifyListeners();
    }
  }

  void _updateInboxLocalFromSocket(Map<String, dynamic> data) {
    int index = _inbox.indexWhere((c) => c.id == data['chat_id']);
    if (index != -1) {
      var oldChat = _inbox[index];
      _inbox.removeAt(index);
      _inbox.insert(
        0,
        ChatRoom(
          id: oldChat.id,
          name: oldChat.name,
          imageUrl: oldChat.imageUrl,
          isGroup: oldChat.isGroup,
          lastMessage: data['last_message'],
          lastMessageTime: DateTime.parse(data['time']),
          unreadCount: data['unread_count'],
          targetUserId: oldChat.targetUserId,
          targetUsername: oldChat.targetUsername,
          isBlockedByMe: oldChat.isBlockedByMe,
        ),
      );
      notifyListeners();
    } else {
      fetchInbox();
    }
  }

  void sendTyping(String chatId, bool isTyping) {
    socket?.emit('typing', {'chat_id': chatId, 'is_typing': isTyping});
  }

  void sendMessage(
    String chatId,
    String text,
    String myUserId, {
    String? myName,
    String? myAvatar,
    String? replyToId,
  }) {
    final tempMessage = ChatMessage(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      chatId: chatId,
      senderId: myUserId,
      senderName: myName,
      senderAvatar: myAvatar,
      text: text,
      type: 'text',
      time: DateTime.now(),
      sentAt: DateTime.now(),
      isRead: false,
      isDelivered: false,
      replyTo: null,
    );

    final currentList = _messagesCache[chatId] ?? [];
    _messagesCache[chatId] = [tempMessage, ...currentList];
    notifyListeners();

    socket?.emit('send_message', {
      'chat_id': chatId,
      'text': text,
      'type': 'text',
      'reply_to_id': replyToId,
    });
  }

  @override
  void dispose() {
    clearData();
    super.dispose();
  }
}
