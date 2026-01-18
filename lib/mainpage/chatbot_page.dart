import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _userHasScrolledUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<BotProvider>().fetchSessions(token);
      }
    });
  }

  void _sendMessage() {
    final botProv = context.read<BotProvider>();
    if (botProv.isTyping) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    FocusScope.of(context).unfocus();
    _userHasScrolledUp = false;

    botProv.sendMessage(text, token);
    _controller.clear();
    _scrollToBottom(force: true);
  }

  void _stopGeneration() {
    context.read<BotProvider>().stopGeneration();
  }

  void _regenerate() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<BotProvider>().regenerateLastResponse(token);
    }
  }

  void _editMessage(String msgId, String currentText) {
    _controller.text = currentText;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Pesan"),
        content: TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.clear();
              Navigator.pop(ctx);
            },
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () {
              final newText = _controller.text.trim();
              if (newText.isNotEmpty) {
                final token = context.read<AuthProvider>().token;
                if (token != null) {
                  context.read<BotProvider>().editMessage(
                    msgId,
                    newText,
                    token,
                  );
                }
              }
              _controller.clear();
              Navigator.pop(ctx);
            },
            child: const Text("Kirim Ulang"),
          ),
        ],
      ),
    );
  }

  void _showLongPressOptions(BuildContext context, BotMessageModel msg) {
    final theme = Theme.of(context);
    final isUser = msg.role == 'user';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("Salin Teks"),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Teks disalin"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (isUser && msg.id != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Pesan"),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(msg.id!, msg.content);
                },
              ),
            if (!isUser)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text("Jawab Ulang (Regenerate)"),
                onTap: () {
                  Navigator.pop(ctx);
                  _regenerate();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _startNewChat() {
    context.read<BotProvider>().startNewSession();
  }

  void _loadSession(String sessionId) {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<BotProvider>().loadSessionHistory(sessionId, token);
    }
    Navigator.pop(context);
  }

  void _deleteSession(String sessionId) {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<BotProvider>().deleteSession(sessionId, token);
    }
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (force || !_userHasScrolledUp) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleLinkTap(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (uri.host == 'withamica.my.id' && uri.path.contains('/post/')) {
      _openInternalPost(uri.pathSegments.last);
      return;
    }
    _showLinkOptionsModal(url);
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

  void _showLinkOptionsModal(String originalUrl) async {
    _showLoading();
    Article? matchedArticle;
    try {
      matchedArticle = await _discoverService.findArticleByUrl(originalUrl);
    } catch (e) {
      debugPrint("Error lookup article: $e");
    }
    if (mounted) Navigator.pop(context);
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
            child: Wrap(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (matchedArticle != null)
                  ListTile(
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.blue,
                    ),
                    title: const Text("Baca di Aplikasi"),
                    subtitle: Text(matchedArticle.title, maxLines: 1),
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
                ListTile(
                  leading: const Icon(Icons.public, color: Colors.orange),
                  title: const Text("Buka Browser"),
                  subtitle: const Text("Kunjungi website asli"),
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

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final messages = botProvider.messages;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (botProvider.isTyping && !_userHasScrolledUp) {
      _scrollToBottom();
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              accountName: const Text("Amica AI Assistant"),
              accountEmail: const Text("Riwayat Percakapan"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.auto_awesome, color: Colors.deepPurple),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Percakapan Baru"),
              onTap: () {
                _startNewChat();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: botProvider.sessions.isEmpty
                  ? const Center(child: Text("Belum ada riwayat"))
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: botProvider.sessions.length,
                      itemBuilder: (ctx, i) {
                        final session = botProvider.sessions[i];
                        final isSelected =
                            session.id == botProvider.currentSessionId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: theme.colorScheme.primaryContainer
                              .withOpacity(0.5),
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _loadSession(session.id),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => _deleteSession(session.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Tanya Amica'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: "Chat Baru",
            onPressed: () => context.read<BotProvider>().startNewSession(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.amber.shade50,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  "AI dapat membuat kesalahan. Verifikasi info medis.",
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  if (notification.metrics.extentAfter > 50) {
                    if (!_userHasScrolledUp) _userHasScrolledUp = true;
                  } else if (notification.metrics.extentAfter < 10) {
                    if (_userHasScrolledUp) _userHasScrolledUp = false;
                  }
                }
                return false;
              },
              child: messages.isEmpty && !botProvider.isTyping
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount:
                          messages.length + (botProvider.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _buildBotBubble(
                            context,
                            msg: BotMessageModel(role: 'bot', content: ''),
                            text: botProvider.currentStreamBuffer,
                            status: botProvider.statusMessage,
                            isTyping: true,
                          );
                        }

                        final msg = messages[index];
                        final isLastMessage = index == messages.length - 1;
                        final isSecondLast = index == messages.length - 2;

                        // LOGIC TAMPIL TOMBOL (Aman dari Crash karena cek msg.id != null)
                        final bool showEdit =
                            !botProvider.isTyping &&
                            msg.role == 'user' &&
                            msg.id != null && // Pastikan ID ada
                            (isLastMessage ||
                                (isSecondLast && messages.last.role != 'user'));

                        final bool showRegen =
                            !botProvider.isTyping &&
                            (msg.role == 'model' || msg.role == 'bot') &&
                            isLastMessage;

                        return msg.role == 'user'
                            ? _buildUserBubble(context, msg, showEdit: showEdit)
                            : _buildBotBubble(
                                context,
                                msg: msg,
                                showRegen: showRegen,
                              );
                      },
                    ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 5,
                          readOnly: botProvider.isTyping,
                          style: TextStyle(
                            color: botProvider.isTyping
                                ? Colors.grey
                                : theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: botProvider.isTyping
                                ? 'Sedang memproses...'
                                : 'Tanyakan tentang bullying...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: botProvider.isTyping
                          ? IconButton.filled(
                              key: const ValueKey('stop'),
                              onPressed: _stopGeneration,
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                              ),
                              icon: const Icon(Icons.stop_rounded),
                              tooltip: "Hentikan",
                            )
                          : IconButton.filled(
                              key: const ValueKey('send'),
                              onPressed: _sendMessage,
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              icon: const Icon(Icons.arrow_upward_rounded),
                              tooltip: "Kirim",
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(
    BuildContext context,
    BotMessageModel msg, {
    bool showEdit = false,
  }) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onLongPress: () => _showLongPressOptions(context, msg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4, left: 60),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            if (showEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    if (msg.id != null) {
                      _editMessage(msg.id!, msg.content);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 12,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBotBubble(
    BuildContext context, {
    required BotMessageModel msg,
    String? text,
    String status = "",
    bool isTyping = false,
    bool showRegen = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String mainContent = text ?? msg.content;
    List<Map<String, String>> citations = [];

    int iconIndex = mainContent.indexOf('📚');
    if (iconIndex != -1) {
      String linkPart = mainContent.substring(iconIndex);
      mainContent = mainContent.substring(0, iconIndex).trim();
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
      child: GestureDetector(
        onLongPress: isTyping
            ? null
            : () => _showLongPressOptions(context, msg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.transparent,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.deepPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        "Amica",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.5,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.secondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (mainContent.isEmpty && isTyping && status.isEmpty)
                            Text(
                              "...",
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            MarkdownBody(
                              data: mainContent,
                              selectable: true,
                              onTapLink: (text, href, title) =>
                                  _handleLinkTap(href),
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                code: TextStyle(
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  fontFamily: 'monospace',
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (citations.isNotEmpty && !isTyping) ...[
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          "Sumber Bacaan:",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
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
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.08,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.15),
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
                    if (showRegen)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: InkWell(
                          onTap: _regenerate,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 12,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Jawab Ulang",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            "Ceritakan masalah Anda",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tanyakan tentang tanda-tanda bullying,\ncara melapor, atau dukungan psikologis.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
