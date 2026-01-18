class ChatRoom {
  final String id;
  final String name;
  final String imageUrl;
  final String? lastMessage;
  final String? lastSenderName;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isGroup;
  final String? targetUserId;
  final String? targetUsername;
  final bool isHidden;
  final bool isVerified;
  final bool isBlockedByMe;

  ChatRoom({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.lastMessage,
    this.lastSenderName,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isGroup,
    this.targetUserId,
    this.targetUsername,
    this.isHidden = false,
    this.isVerified = false,
    this.isBlockedByMe = false,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      imageUrl: json['image_url'] ?? '',
      lastMessage: json['last_message_text'],
      lastSenderName: json['last_sender_name'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isGroup: json['is_group'] ?? false,
      targetUserId: json['target_user_id'],
      targetUsername: json['target_username'],
      isHidden: json['is_hidden'] ?? false,
      isVerified: json['target_user']?['is_verified'] ?? false,
      isBlockedByMe: json['is_blocked_by_me'] ?? false,
    );
  }
}