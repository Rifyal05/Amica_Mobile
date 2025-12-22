import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_model.dart';
import '../models/messages_model.dart';
import '../services/api_config.dart';
import '../services/authenticated_client.dart';

class ChatProvider with ChangeNotifier {
  final AuthenticatedClient _client = AuthenticatedClient();
  IO.Socket? socket;

  List<ChatRoom> _inbox = [];
  final Map<String, List<ChatMessage>> _messagesCache = {};
  final Map<String, String?> _typingStatus = {};

  String? _myUserId;
  bool _isLoading = false;

  List<ChatRoom> get inbox => _inbox;
  bool get isLoading => _isLoading;

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

  void connectSocket(String token, String myUserId) {
    if (_myUserId != null && _myUserId != myUserId) {
      clearData();
    }

    _myUserId = myUserId;

    if (socket != null && socket!.connected) return;

    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
    }

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

    socket!.on('new_message', (data) {
      final newMessage = ChatMessage.fromJson(data);

      final currentList = _messagesCache[newMessage.chatId] ?? [];

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

    socket!.on('messages_read', (data) {
      String chatId = data['chat_id'];
      if (_messagesCache.containsKey(chatId)) {
        final messages = _messagesCache[chatId]!;
        _messagesCache[chatId] = messages.map((msg) {
          if (!msg.isRead) {
            return ChatMessage(
              id: msg.id,
              chatId: msg.chatId,
              senderId: msg.senderId,
              text: msg.text,
              type: msg.type,
              sentAt: msg.sentAt,
              isRead: true,
            );
          }
          return msg;
        }).toList();
        notifyListeners();
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
  }

  void _updateInboxLocal(ChatMessage msg) {
    int index = _inbox.indexWhere((c) => c.id == msg.chatId);

    int newUnreadCount = 0;

    if (index != -1) {
      var oldChat = _inbox[index];
      newUnreadCount = (msg.senderId == _myUserId)
          ? 0
          : oldChat.unreadCount + 1;

      _inbox.removeAt(index);
      _inbox.insert(
        0,
        ChatRoom(
          id: oldChat.id,
          name: oldChat.name,
          imageUrl: oldChat.imageUrl,
          isGroup: oldChat.isGroup,
          lastMessage: msg.text,
          lastMessageTime: msg.sentAt,
          unreadCount: newUnreadCount,
        ),
      );
    } else {
      fetchInbox();
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

  void sendMessage(String chatId, String text, String myUserId) {
    final tempMessage = ChatMessage(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      chatId: chatId,
      senderId: myUserId,
      text: text,
      type: 'text',
      sentAt: DateTime.now(),
      isRead: false,
    );

    final currentList = _messagesCache[chatId] ?? [];
    _messagesCache[chatId] = [tempMessage, ...currentList];
    notifyListeners();

    socket?.emit('send_message', {
      'chat_id': chatId,
      'text': text,
      'type': 'text',
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }
}
