import 'package:amica/mainpage/user_profile_page.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'chat_page.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final _searchController = TextEditingController();
  List<User> _connections = [];
  List<User> _searchResults = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _connections = User.dummyUsers.where((u) => u.id != 'user_001').toList();
    _searchResults = _connections;
    _searchController.addListener(_filterConnections);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterConnections);
    _searchController.dispose();
    super.dispose();
  }

  void _filterConnections() {
    final query = _searchController.text.toLowerCase();
    if (query == _query) return;

    setState(() {
      _query = query;
      _searchResults = _connections
          .where((user) =>
      user.username.toLowerCase().contains(query) ||
          user.displayName.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi Anda'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari koneksi...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => UserProfilePage(user: user),
                      ));
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(user.avatarUrl),
                    ),
                  ),
                  title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.username),
                  trailing: IconButton(
                    icon: Icon(Icons.message_outlined, color: theme.colorScheme.primary),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ChatPage(),
                      ));
                    },
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