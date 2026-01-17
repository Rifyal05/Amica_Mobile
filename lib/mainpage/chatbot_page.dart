import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/auth_provider.dart';
import '../provider/bot_provider.dart';
import '../provider/post_provider.dart';
import '../models/article_model.dart';
import '../services/discover_services.dart';
import 'post_detail_page.dart';
import 'article_detail_page.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DiscoverService _discoverService = DiscoverService();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
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

  String _cleanUrl(String url) {
    return url
        .toLowerCase()
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('www.', '')
        .replaceAll(RegExp(r'/$'), '')
        .trim();
  }

  Future<void> _handleLinkTap(String? url) async {
    if (url == null) return;
    debugPrint("🔍 DEBUG: URL ditangkap: '$url'");

    final uri = Uri.parse(url);
    if (uri.host == 'withamica.my.id' && uri.path.contains('/post/')) {
      _openInternalPost(uri.pathSegments.last);
      return;
    }

    _showLinkOptionsModal(url);
  }

  void _showLinkOptionsModal(String originalUrl) async {
    _showLoading();

    Article? matchedArticle;

    try {
      matchedArticle = await _discoverService.findArticleByUrl(originalUrl);
    } catch (e) {
      debugPrint("Error lookup article: $e");
    }

    if (mounted) Navigator.pop(context); // Tutup Loading
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                if (matchedArticle != null) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      "Baca di Aplikasi Amica",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      matchedArticle.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ArticleDetailPage(article: matchedArticle!),
                        ),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(),
                  ),
                ],

                // TOMBOL DEFAULT BUKA DI BROWSER
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.public,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    "Buka Sumber Asli",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: const Text("Kunjungi website referensi"),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse(originalUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openInternalPost(String postId) async {
    _showLoading();
    try {
      final post = await context.read<PostProvider>().getPostById(postId);
      if (mounted) Navigator.pop(context);
      if (post != null && mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => PostDetailPage(post: post)));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
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
                return msg.role == 'user'
                    ? _buildUserBubble(context, msg.content)
                    : _buildBotBubble(context, text: msg.content);
              },
            ),
          ),
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

    int iconIndex = text.indexOf('📚');
    if (iconIndex != -1) {
      mainContent = text.substring(0, iconIndex).trim();
      String linkPart = text.substring(iconIndex);
      final RegExp linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
      final Iterable<RegExpMatch> matches = linkRegex.allMatches(linkPart);
      for (final m in matches) {
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
          mainAxisSize: MainAxisSize.min,
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
            MarkdownBody(
              data: mainContent,
              selectable: true,
              onTapLink: (text, href, title) => _handleLinkTap(href),
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.5,
                ),
                strong: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (citations.isNotEmpty && !isTyping) ...[
              const SizedBox(height: 16),
              const Divider(height: 0.5),
              const SizedBox(height: 12),
              const Text(
                "Bacaan Terkait:",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: citations.map((cite) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleLinkTap(cite['url']),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                cite['title']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
