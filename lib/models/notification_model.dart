class AppNotification {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String type;
  final String? referenceId;
  final String? text;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    this.referenceId,
    this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      type: json['type'],
      referenceId: json['reference_id'],
      text: json['text'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}