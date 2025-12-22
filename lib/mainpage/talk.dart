import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_page.dart';
import 'connections_page.dart';
import 'webview_page.dart';
import '../provider/chat_provider.dart';
import '../provider/auth_provider.dart';

class Talk extends StatefulWidget {
  const Talk({super.key});

  @override
  State<Talk> createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  @override
  void initState() {
    super.initState();
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
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return DateFormat('HH:mm').format(time.toLocal());
    }
    return DateFormat('dd/MM').format(time.toLocal());
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Dukungan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => chatProvider.fetchInbox(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCollapsibleSupportSection(context),
                ),
                SliverToBoxAdapter(child: _buildSearchBar(context)),

                if (chatProvider.isLoading && chatProvider.inbox.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (chatProvider.inbox.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text("Belum ada pesan.")),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final chat = chatProvider.inbox[index];
                      return _buildChatListItem(
                        context: context,
                        chatId: chat.id,
                        name: chat.name,
                        message: chat.lastMessage ?? "Mulai percakapan...",
                        time: _formatTime(chat.lastMessageTime),
                        unreadCount: chat.unreadCount,
                        imageUrl: chat.imageUrl,
                      );
                    }, childCount: chatProvider.inbox.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              heroTag: 'talk_tab',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConnectionsPage(),
                ),
              ),
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.people_alt_outlined,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
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
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 5.0,
      ),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: theme.textTheme.bodySmall),
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
            builder: (context) =>
                ChatPage(chatId: chatId, chatName: name, chatImage: imageUrl),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Hapus Percakapan",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari pesan atau teman...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleSupportSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ExpansionTile(
        title: Text(
          'Dukungan Mental & Darurat',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        collapsedBackgroundColor: colorScheme.surfaceContainer,
        backgroundColor: colorScheme.surfaceContainer,
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
            icon: Icons.public,
            title: 'Into The Light Indonesia',
            subtitle: 'Website dukungan kesehatan jiwa',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WebViewPage(
                  title: 'Into The Light ID',
                  url: 'https://www.intothelightid.org/',
                ),
              ),
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.launch, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
