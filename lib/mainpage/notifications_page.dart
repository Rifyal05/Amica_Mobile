import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: ListView(
        children: [
          _buildNotificationTile(
            context,
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
            title: 'Ayah Keren menyukai postingan Anda.',
            time: '5 menit lalu',
          ),
          _buildNotificationTile(
            context,
            icon: Icons.chat_bubble,
            iconColor: Colors.blueAccent,
            title: 'Dr. Anisa, Sp.A mengomentari postingan Anda.',
            time: '1 jam lalu',
          ),
          _buildNotificationTile(
            context,
            icon: Icons.person_add,
            iconColor: Colors.green,
            title: 'Keluarga Ceria mulai mengikuti Anda.',
            time: '3 jam lalu',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String time,
      }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(time),
      onTap: () {},
    );
  }
}