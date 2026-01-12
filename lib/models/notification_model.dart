import '../services/api_config.dart';

class AppNotification {
  final String id;
  final String senderId;
  final String senderName;
  final String? _rawSenderAvatar;
  final bool senderIsVerified;
  final String type;
  final String? referenceId;
  final String? text;
  final bool isRead;
  final DateTime createdAt;
  final String? _rawRelatedImage;

  AppNotification({
    required this.id,
    required this.senderId,
    required this.senderName,
    String? senderAvatar,
    this.senderIsVerified = false,
    required this.type,
    this.referenceId,
    this.text,
    required this.isRead,
    required this.createdAt,
    String? relatedImageUrl,
  }) : _rawSenderAvatar = senderAvatar,
        _rawRelatedImage = relatedImageUrl;

  String? get senderAvatar {
    if (_rawSenderAvatar == null || _rawSenderAvatar.isEmpty) return null;
    if (_rawSenderAvatar.startsWith('http')) return _rawSenderAvatar;
    String cleanPath = _rawSenderAvatar.startsWith('/')
        ? _rawSenderAvatar.substring(1)
        : _rawSenderAvatar;
    if (!cleanPath.startsWith('static/')) {
      cleanPath = 'static/uploads/$cleanPath';
    }
    return '${ApiConfig.baseUrl}/$cleanPath';
  }

  String? get relatedImageUrl {
    if (_rawRelatedImage == null || _rawRelatedImage.isEmpty) return null;
    if (_rawRelatedImage.startsWith('http')) return _rawRelatedImage;
    String cleanPath = _rawRelatedImage.startsWith('/')
        ? _rawRelatedImage.substring(1)
        : _rawRelatedImage;
    if (!cleanPath.startsWith('static/')) {
      cleanPath = 'static/$cleanPath';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${ApiConfig.baseUrl}/$cleanPath?t=$timestamp';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      senderIsVerified: json['sender_is_verified'] ?? false,
      type: json['type'],
      referenceId: json['reference_id'],
      text: json['text'],
      isRead: json['is_read'] ?? false,
      relatedImageUrl: json['related_image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}