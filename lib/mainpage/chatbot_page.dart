import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/auth_provider.dart';
import '../provider/bot_provider.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Anda perlu login.")));
      return;
    }

    context.read<BotProvider>().sendMessage(text, token);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleLinkTap(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka link")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final messages = botProvider.messages;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanya Amica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => botProvider.clearMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // DISCLAIMER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: isDark
                ? Colors.amber.shade900.withOpacity(0.3)
                : Colors.amber.shade100,
            width: double.infinity,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? Colors.amber.shade100 : Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Amica AI dapat membuat kesalahan. Selalu verifikasi informasi medis/penting.",
                    style: TextStyle(
                      color: isDark
                          ? Colors.amber.shade100
                          : Colors.amber.shade900,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (botProvider.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return _buildBotBubble(
                    context,
                    text: botProvider.currentStreamBuffer.isEmpty
                        ? "..."
                        : botProvider.currentStreamBuffer,
                    status: botProvider.statusMessage,
                    isTyping: true,
                  );
                }

                final msg = messages[index];

                if (msg.role == 'user') {
                  return _buildUserBubble(context, msg.content);
                } else {
                  return _buildBotBubble(context, text: msg.content);
                }
              },
            ),
          ),

          // INPUT FIELD
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Tanya seputar parenting...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: botProvider.isTyping ? null : _sendMessage,
                  icon: botProvider.isTyping
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(text, style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
    );
  }

  Widget _buildBotBubble(
    BuildContext context, {
    required String text,
    String status = "",
    bool isTyping = false,
  }) {
    final theme = Theme.of(context);

    String mainContent = text;
    List<Map<String, String>> citations = [];

    // Regex untuk mengambil bagian Referensi Bacaan
    final RegExp bacaanRegex = RegExp(
      r'\n\n📚 \*\*Bacaan:\*\* (.*)',
      dotAll: true,
    );
    final match = bacaanRegex.firstMatch(text);

    if (match != null) {
      String linksPart = match.group(1) ?? "";
      mainContent = text.replaceAll(match.group(0)!, "").trim();

      final RegExp linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
      final linkMatches = linkRegex.allMatches(linksPart);

      for (final m in linkMatches) {
        citations.add({
          'title': m.group(1) ?? "Artikel",
          'url': m.group(2) ?? "",
        });
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // Markdown Render menggunakan flutter_markdown_plus
            MarkdownBody(
              data: mainContent,
              selectable: true,
              onTapLink: (text, href, title) => _handleLinkTap(href),
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                strong: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(color: theme.colorScheme.onSurface),
                blockquote: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                code: TextStyle(
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            if (citations.isNotEmpty && !isTyping) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                "Sumber Bacaan:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: citations.map((cite) {
                  return ActionChip(
                    avatar: const Icon(Icons.link, size: 16),
                    label: Text(
                      cite['title']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _handleLinkTap(cite['url']),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
