import 'package:flutter/material.dart';
import '../models/user_model.dart';
// import '../services/user_service.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';
import 'user_profile_page.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();

  List<User> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startChat(String targetUserId, String targetName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _chatService.getOrCreateChat(targetUserId);

    if (!mounted) return;
    Navigator.pop(context);

    if (result['success']) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: result['chat_id'],
          chatName: targetName,
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Koneksi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Cari username atau nama...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("@${user.username}"),
                    trailing: IconButton(
                      icon: Icon(Icons.message_outlined, color: theme.colorScheme.primary),
                      onPressed: () => _startChat(user.id, user.displayName),
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => UserProfilePage(user: user),
                      ));
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}