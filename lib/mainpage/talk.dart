import 'package:amica/mainpage/create_group_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat_page.dart';
import 'connections_page.dart';
import 'webview_page.dart';
import '../provider/chat_provider.dart';
import '../provider/auth_provider.dart';
import '../services/user_service.dart';
import 'widgets/verified_badge.dart';

class Talk extends StatefulWidget {
  const Talk({super.key});

  @override
  State<Talk> createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final chatProv = Provider.of<ChatProvider>(context, listen: false);

      if (auth.isLoggedIn) {
        String? validToken = await auth.getFreshToken();
        String myUserId = auth.currentUser?.id ?? "";

        if (validToken != null && myUserId.isNotEmpty) {
          chatProv.connectSocket(validToken, myUserId);
          chatProv.fetchInbox();
        }
      }
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "";
    final now = DateTime.now();
    final localTime = time.toLocal();
    if (localTime.day == now.day &&
        localTime.month == now.month &&
        localTime.year == now.year) {
      return DateFormat('HH:mm').format(localTime);
    }
    return DateFormat('dd/MM').format(localTime);
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final String url =
        "https://wa.me/$phone/?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatProvider = context.watch<ChatProvider>();

    final int unreadDirect = chatProvider.inbox
        .where((c) => !c.isGroup)
        .fold(0, (sum, item) => sum + item.unreadCount);
    final int unreadGroup = chatProvider.inbox
        .where((c) => c.isGroup)
        .fold(0, (sum, item) => sum + item.unreadCount);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            "Komunikasi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          centerTitle: false,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                child: Badge(
                  isLabelVisible: unreadDirect > 0,
                  label: Text('$unreadDirect'),
                  backgroundColor: colorScheme.primary,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Pesan"),
                  ),
                ),
              ),
              Tab(
                child: Badge(
                  isLabelVisible: unreadGroup > 0,
                  label: Text('$unreadGroup'),
                  backgroundColor: colorScheme.secondary,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Grup"),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatList(chatProvider, isGroupOnly: false),
            _buildChatList(chatProvider, isGroupOnly: true),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'group_fab',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateGroupPage(),
                ),
              ),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              tooltip: "Buat Grup",
              child: const Icon(Icons.groups_outlined),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'chat_fab',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConnectionsPage(),
                ),
              ),
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.message_outlined, color: colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(
    ChatProvider chatProvider, {
    required bool isGroupOnly,
  }) {
    final chats = chatProvider.inbox.where((c) {
      bool matchesSearch = c.name.toLowerCase().contains(_query);

      if (isGroupOnly) {
        return matchesSearch && c.isGroup;
      } else {
        return matchesSearch && !c.isHidden && !c.isGroup;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: () => chatProvider.fetchInbox(),
      child: CustomScrollView(
        slivers: [
          if (!isGroupOnly)
            SliverToBoxAdapter(child: _buildCollapsibleSupportSection(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: isGroupOnly
                      ? 'Cari grup...'
                      : 'Cari pesan atau teman...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
          if (chatProvider.isLoading && chatProvider.inbox.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (chats.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  isGroupOnly ? "Belum ada grup." : "Belum ada pesan.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final chat = chats[index];
                return _buildChatListItem(
                  context: context,
                  chatId: chat.id,
                  name: chat.name,
                  message: chat.lastMessage ?? "Mulai percakapan...",
                  lastSenderName: chat.lastSenderName,
                  time: _formatTime(chat.lastMessageTime),
                  unreadCount: chat.unreadCount,
                  imageUrl: chat.imageUrl,
                  isGroup: chat.isGroup,
                  targetUserId: chat.targetUserId,
                  targetUsername: chat.targetUsername,
                  isVerified: chat.isVerified,
                );
              }, childCount: chats.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildChatListItem({
    required BuildContext context,
    required String chatId,
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required String imageUrl,
    required bool isGroup,
    String? lastSenderName,
    String? targetUserId,
    String? targetUsername,
    bool isVerified = false,
  }) {
    final theme = Theme.of(context);
    String displayMessage = message;

    if (message != "🚫 Pesan ini telah dihapus") {
      if (lastSenderName == "Anda") {
        if (isGroup) {
          displayMessage = "Anda: $message";
        } else {
          displayMessage = message;
        }
      } else if (lastSenderName != null && lastSenderName.isNotEmpty) {
        displayMessage = "$lastSenderName: $message";
      }
    }

    if (message.contains('/join/') && message.startsWith('http')) {
      String invitePrefix = (lastSenderName == "Anda")
          ? "Anda: "
          : (lastSenderName != null ? "$lastSenderName: " : "");
      displayMessage = "$invitePrefix Undangan Grup";
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 5.0,
      ),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: ClipOval(
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(strokeWidth: 2),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.person),
                )
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(isGroup ? Icons.groups : Icons.person),
                ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isVerified && !isGroup) const VerifiedBadge(size: 14),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isGroup && targetUsername != null)
            Text(
              "@$targetUsername",
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          Text(
            displayMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              color: unreadCount > 0
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            CircleAvatar(
              radius: 10,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                unreadCount.toString(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: chatId,
              chatName: name,
              chatImage: imageUrl,
              isGroup: isGroup,
              targetUserId: targetUserId,
            ),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => Wrap(
            children: [
              if (!isGroup && targetUserId != null)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    "Blokir Pengguna",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Blokir?"),
                        content: const Text(
                          "Pesan dari pengguna ini tidak akan muncul lagi di daftar chat Anda.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Blokir",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await UserService().blockUser(targetUserId);
                      if (mounted) {
                        context.read<ChatProvider>().fetchInbox();
                      }
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Hapus Percakapan",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Hapus Chat?"),
                      content: const Text(
                        "Tindakan ini akan menghapus percakapan ini secara permanen dari daftar Anda.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Hapus",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    context.read<ChatProvider>().deleteConversation(chatId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleSupportSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ExpansionTile(
        title: Text(
          'Lembaga Profesional',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        collapsedBackgroundColor: colorScheme.surfaceContainerHighest
            .withOpacity(0.3),
        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        children: [
          _buildSupportTile(
            context,
            icon: Icons.support_agent,
            title: 'Kementerian PPPA',
            subtitle: 'Layanan SAPA 129 via WhatsApp',
            onTap: () => _launchWhatsApp(
              '628111129129',
              'Halo SAPA 129, saya membutuhkan bantuan.',
            ),
          ),
          _buildSupportTile(
            context,
            icon: Icons.health_and_safety,
            title: 'Laporan Perundungan Kemkes',
            subtitle: 'Situs resmi Kemenkes RI',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WebViewPage(
                  title: 'Laporan Perundungan',
                  url: 'https://perundungan.kemkes.go.id/',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.launch, size: 18),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
