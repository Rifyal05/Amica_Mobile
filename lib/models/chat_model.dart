class ChatRoom {
  final String id;
  final String name;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String imageUrl;
  final bool isGroup;

  ChatRoom({
    required this.id,
    required this.name,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.imageUrl,
    required this.isGroup,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'] ?? 'Chat',
      lastMessage: json['last_message_text'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      isGroup: json['is_group'] ?? false,
    );
  }
}
