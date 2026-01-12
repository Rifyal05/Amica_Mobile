import 'package:amica/mainpage/moderation_list_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

import '../provider/notification_provider.dart';
import '../provider/post_provider.dart';
import '../models/notification_model.dart';
import '../mainpage/widgets/verified_badge.dart';
import 'post_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  Future<void> _handleNavigation(AppNotification notif) async {
    if (notif.type == 'post_rejected' ||
        notif.type == 'moderation_update' ||
        notif.type == 'appeal_approved' ||
        notif.type == 'appeal_rejected') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ModerationListPage()),
      );
    } else if ((notif.type == 'like' || notif.type == 'comment') &&
        notif.referenceId != null) {
      _navigateToPost(notif.referenceId!);
    }
  }

  Future<void> _navigateToPost(String postId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final postProvider = context.read<PostProvider>();
      final post = await postProvider.getPostById(postId);
      if (!mounted) return;
      Navigator.pop(context);
      if (post != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Postingan tidak ditemukan")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal memuat postingan")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final filteredList = _selectedFilter == 'all'
        ? provider.notifications
        : provider.notifications
              .where((n) => n.type == _selectedFilter)
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Suka', 'like'),
                const SizedBox(width: 8),
                _buildFilterChip('Komentar', 'comment'),
                const SizedBox(width: 8),
                _buildFilterChip('Mengikuti', 'follow'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.fetchNotifications(),
                    child: filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) =>
                                _buildNotificationTile(
                                  context,
                                  filteredList[index],
                                ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = value);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada notifikasi",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, AppNotification notif) {
    IconData icon;
    Color iconColor;
    String text;
    switch (notif.type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.redAccent;
        text = "menyukai postingan Anda.";
        break;
      case 'comment':
        icon = Icons.chat_bubble;
        iconColor = Colors.blueAccent;
        text = "mengomentari: ${notif.text ?? ''}";
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.green;
        text = "mulai mengikuti Anda.";
        break;
      case 'post_rejected':
        icon = Icons.gpp_maybe;
        iconColor = Colors.orange;
        text = "Postingan Anda ditahan oleh sistem moderasi.";
        break;
      case 'appeal_approved':
        icon = Icons.verified_user;
        iconColor = Colors.green;
        text = "Banding diterima! Postingan Anda kini telah tayang.";
        break;
      case 'appeal_rejected':
        icon = Icons.gpp_bad;
        iconColor = Colors.red;
        text = "Banding ditolak. Konten dihapus karena melanggar aturan.";
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        text = "berinteraksi dengan Anda.";
    }

    return ListTile(
      onTap: () => _handleNavigation(notif),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: notif.senderAvatar != null
                ? CachedNetworkImageProvider(
                    notif.senderAvatar!,
                    maxHeight: 100,
                    maxWidth: 100,
                  )
                : null,
            child: notif.senderAvatar == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
          ),
        ],
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
          children: [
            TextSpan(
              text: "${notif.senderName} ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notif.senderIsVerified)
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: VerifiedBadge(
                  size: 14,
                  padding: EdgeInsets.only(right: 4),
                ),
              ),
            TextSpan(text: text),
          ],
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          timeago.format(notif.createdAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
      trailing: notif.relatedImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: notif.relatedImageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                memCacheHeight: 150,
                memCacheWidth: 150,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[200], width: 48, height: 48),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            )
          : null,
    );
  }
}
