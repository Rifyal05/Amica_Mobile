import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/api_config.dart';

class GroupBannedPage extends StatefulWidget {
  final String chatId;
  const GroupBannedPage({super.key, required this.chatId});

  @override
  State<GroupBannedPage> createState() => _GroupBannedPageState();
}

class _GroupBannedPageState extends State<GroupBannedPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  final ChatService _service = ChatService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final data = await _service.getBannedList(widget.chatId);
      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _unban(String userId) async {
    await _service.unbanUser(widget.chatId, userId);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User di-unban")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Blokir Grup")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text("Tidak ada user yang diblokir"))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (ctx, idx) {
          final u = _users[idx];
          final avatar = ApiConfig.getFullUrl(u['avatar_url']);
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: avatar != null
                  ? NetworkImage(avatar)
                  : null,
              child: avatar == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(u['name'] ?? "Unknown"),
            subtitle: Text("@${u['username'] ?? ''}"),
            trailing: TextButton(
              onPressed: () => _unban(u['id']),
              child: const Text("Unban", style: TextStyle(color: Colors.red)),
            ),
          );
        },
      ),
    );
  }
}