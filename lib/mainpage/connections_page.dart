import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/api_config.dart';
import 'chat_page.dart';
import 'widgets/verified_badge.dart';

class ConnectionsPage extends StatefulWidget {
  final bool isSelectionMode;

  const ConnectionsPage({super.key, this.isSelectionMode = false});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  List<User> _friends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      final users = await _chatService.getMutualFriends(query);
      setState(() => _friends = users);
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onUserTap(User user) async {
    if (widget.isSelectionMode) {
      Navigator.pop(context, user);
    } else {
      final result = await _chatService.getOrCreateChat(user.id);
      if (result['success'] && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: result['chat_id'],
              chatName: user.displayName,
              chatImage: ApiConfig.getFullUrl(user.avatarUrl),
              targetUserId: user.id,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Pilih Teman' : 'Teman Saya'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _loadFriends,
              decoration: InputDecoration(
                hintText: 'Cari teman...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                ? const Center(
                    child: Text("Belum ada teman yang saling follow."),
                  )
                : ListView.builder(
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final user = _friends[index];
                      final avatar = ApiConfig.getFullUrl(user.avatarUrl) ?? '';

                      return ListTile(
                        leading: SizedBox(
                          width: 44,
                          height: 44,
                          child: ClipOval(
                            child: avatar.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatar,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person),
                                  )
                                : Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (user.isVerified) const VerifiedBadge(size: 14),
                          ],
                        ),
                        subtitle: Text("@${user.username}"),
                        onTap: () => _onUserTap(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
