import 'package:amica/models/user_model.dart';
import 'package:flutter/material.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  List<User> get _mockBlockedUsers => User.dummyUsers.where((u) => u.id != 'user_001').toList();

  void _unblockUser(BuildContext context, User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.displayName} berhasil dibuka blokirnya.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockedUsers = _mockBlockedUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengguna Diblokir'),
      ),
      body: blockedUsers.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 48),
            SizedBox(height: 16),
            Text('Anda belum memblokir pengguna manapun.'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: blockedUsers.length,
        itemBuilder: (context, index) {
          final user = blockedUsers[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
            title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.username),
            trailing: TextButton(
              onPressed: () => _unblockUser(context, user),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Buka Blokir'),
            ),
          );
        },
      ),
    );
  }
}