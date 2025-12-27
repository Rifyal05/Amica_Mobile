class BotMessageModel {
  final String role;
  final String content;
  final bool isStreaming;

  BotMessageModel({
    required this.role,
    required this.content,
    this.isStreaming = false,
  });
}