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
                    imageUrl: 'data:image/jpeg;base64,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',
                  ),
                  _buildChatListItem(
                    context: context,
                    name: 'Ayah Keren',
                    message: 'Tentu, aku akan ada di sana!',
                    time: 'Kemarin',
                    unreadCount: 0,
                    imageUrl: 'data:image/jpeg;base64,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',
                  ),
                  _buildChatListItem(
                    context: context,
                    name: 'Tim Dukungan Amica',
                    message: 'Selamat datang di Amica!',
                    time: '2 hari lalu',
                    unreadCount: 0,
                    imageUrl: 'data:image/jpeg;base64,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',
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