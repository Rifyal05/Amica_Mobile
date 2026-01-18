import '../services/api_config.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String? senderId;
  final String? senderName;
  final String? senderUsername;
  final String? _rawSenderAvatar;
  final bool senderIsVerified;
  final String? text;
  final String type;
  final DateTime time;
  final DateTime sentAt;
  final bool isRead;
  final bool isDelivered;
  final bool isDeleted;
  final Map<String, dynamic>? replyTo;

  ChatMessage({
    required this.id,
    required this.chatId,
    this.senderId,
    this.senderName,
    this.senderUsername,
    String? senderAvatar,
    this.senderIsVerified = false,
    this.text,
    required this.type,
    required this.time,
    required this.sentAt,
    required this.isRead,
    this.isDelivered = false,
    this.isDeleted = false,
    this.replyTo,
  }) : _rawSenderAvatar = senderAvatar;

  String? get senderAvatar {
    if (_rawSenderAvatar == null || _rawSenderAvatar.isEmpty) return null;
    if (_rawSenderAvatar.startsWith('http')) return _rawSenderAvatar;
    String cleanPath = _rawSenderAvatar.startsWith('/')
        ? _rawSenderAvatar.substring(1)
        : _rawSenderAvatar;
    return '${ApiConfig.baseUrl}/$cleanPath';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderUsername: json['sender_username'],
      senderAvatar: json['sender_avatar'],
      senderIsVerified: json['sender_is_verified'] ?? false,
      text: json['text'],
      type: json['type'] ?? 'text',
      time: DateTime.parse(json['sent_at']),
      sentAt: DateTime.parse(json['sent_at']),
      isRead: json['is_read'] ?? false,
      isDelivered: json['is_delivered'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      replyTo: json['reply_to'],
    );
  }

  ChatMessage copyWith({bool? isDeleted, String? text, bool? isRead, bool? isDelivered}) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderUsername: senderUsername,
      senderAvatar: _rawSenderAvatar,
      senderIsVerified: senderIsVerified,
      text: text ?? this.text,
      type: type,
      time: time,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isDeleted: isDeleted ?? this.isDeleted,
      replyTo: replyTo,
    );
  }
}