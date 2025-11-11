import 'package:amica/mainpage/connections_page.dart';
import 'package:amica/mainpage/webview_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_page.dart';

class Talk extends StatefulWidget {
  const Talk({super.key});

  @override
  State<Talk> createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final String url =
        "https://wa.me/$phone/?text=${Uri.encodeComponent(message)}";
    await _launchURL(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Dukungan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildCollapsibleSupportSection(context),
              ),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildChatListItem(
                    context: context,
                    name: 'Dr. Anisa, Sp.A',
                    message: 'Sama-sama, semoga membantu ya!',
                    time: '10:05',
                    unreadCount: 1,
                    imageUrl: 'https://i.pravatar.cc/150?img=31',
                  ),
                  _buildChatListItem(
                    context: context,
                    name: 'Ayah Keren',
                    message: 'Tentu, aku akan ada di sana!',
                    time: 'Kemarin',
                    unreadCount: 0,
                    imageUrl: 'https://i.pravatar.cc/150?img=32',
                  ),
                  _buildChatListItem(
                    context: context,
                    name: 'Tim Dukungan Amica',
                    message: 'Selamat datang di Amica!',
                    time: '2 hari lalu',
                    unreadCount: 0,
                    imageUrl: 'https://i.pravatar.cc/150?img=10',
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ConnectionsPage(),
                ));
              },
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
        childrenPadding: const EdgeInsets.only(bottom: 8),
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
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const WebViewPage(
                title: 'Into The Light ID',
                url: 'https://www.intothelightid.org/',
              ),
            )),
          ),
          _buildSupportTile(
            context,
            icon: Icons.health_and_safety,
            title: 'Laporan Perundungan Kemkes',
            subtitle: 'Situs resmi Kemenkes RI',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const WebViewPage(
                title: 'Laporan Perundungan',
                url: 'https://perundungan.kemkes.go.id/',
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

  Widget _buildChatListItem({
    required BuildContext context,
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required String imageUrl,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool hasUnread = unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 10.0,
      ),
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          if (hasUnread)
            CircleAvatar(
              radius: 12,
              backgroundColor: colorScheme.primary,
              child: Text(
                unreadCount.toString(),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(height: 24),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const ChatPage(),
        ));
      },
    );
  }
}