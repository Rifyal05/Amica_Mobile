import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../provider/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'all'; // 'all', 'like', 'comment', 'follow'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    // Logika Filter Lokal
    final filteredList = _selectedFilter == 'all'
        ? provider.notifications
        : provider.notifications
              .where((n) => n.type == _selectedFilter)
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: Column(
        children: [
          // --- BAGIAN CHIP FILTER ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
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

          // --- BAGIAN LIST NOTIFIKASI ---
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.fetchNotifications(),
                    child: filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final notif = filteredList[index];
                              return _buildNotificationTile(context, notif);
                            },
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
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      // Menggunakan ColorScheme agar aman di Light & Dark Mode tanpa withOpacity
      selectedColor: colorScheme.primaryContainer,

      // Warna background saat TIDAK dipilih (Penting untuk Dark Mode)
      // Menggunakan surfaceContainerHighest untuk standar Material 3, atau grey fallback
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,

      // Hilangkan border agar terlihat lebih modern
      side: BorderSide.none,

      // Styling Teks
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme
                  .onPrimaryContainer // Warna teks kontras saat dipilih
            : colorScheme.onSurface, // Warna teks biasa saat tidak dipilih
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState() {
    String message = "Belum ada notifikasi";
    if (_selectedFilter == 'like') message = "Belum ada yang menyukai";
    if (_selectedFilter == 'comment') message = "Belum ada komentar";
    if (_selectedFilter == 'follow') message = "Belum ada pengikut baru";

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
          Text(message, style: TextStyle(color: Colors.grey[600])),
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
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        text = "berinteraksi dengan Anda.";
    }

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: notif.senderAvatar != null
                ? NetworkImage(notif.senderAvatar!)
                : const AssetImage('source/images/default_avatar.png')
                      as ImageProvider,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
          ),
        ],
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: "${notif.senderName} ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
      subtitle: Text(
        timeago.format(notif.createdAt),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () {
        // Logika navigasi bisa ditambahkan di sini
      },
    );
  }
}
