import 'package:amica/mainpage/user_profile_page.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _searchController = TextEditingController();
  String _query = '';

  final List<User> _userResults = [];
  List<Post> _postResults = [];
  bool _isSearchingTags = false;
  bool _isTagQueryTooShort = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContent);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContent);
    _searchController.dispose();
    super.dispose();
  }

  void _filterContent() {
    final query = _searchController.text;
    if (query == _query) return;

    setState(() {
      _query = query;
      _isSearchingTags = query.startsWith('#');
      _isTagQueryTooShort = false;

      if (_isSearchingTags) {
        final tagQuery = query.substring(1).toLowerCase();
        final int minTagLength = 3;

        if (tagQuery.isEmpty) {
          _postResults = [];
        } else if (tagQuery.length < minTagLength) {
          _isTagQueryTooShort = true;
          _postResults = [];
        } else {
          // _postResults = Post.dummyPosts
          //     .where((post) => post.tags.any((tag) => tag.toLowerCase().startsWith(tagQuery)))
          //     .toList();
        }
      } else {
        if (query.isNotEmpty) {
          // _userResults = User.dummyUsers
          //     .where((user) =>
          // user.username.toLowerCase().contains(query.toLowerCase()) ||
          //     user.displayName.toLowerCase().contains(query.toLowerCase()))
          //     .toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Temukan'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari pengguna atau tag dengan #',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_query.isEmpty) {
      return const Center(
        child: Text('Mulai ketik untuk mencari pengguna atau tag.'),
      );
    }

    if (_isSearchingTags) {
      if (_isTagQueryTooShort) {
        return const Center(
          child: Text('Ketik minimal 3 huruf setelah # untuk mencari tag.'),
        );
      }
      if (_postResults.isNotEmpty) {
        return _buildPostResultsList();
      } else {
        return Center(
          child: Text('Tidak ada postingan dengan tag yang cocok: $_query'),
        );
      }
    } else {
      if (_userResults.isNotEmpty) {
        return _buildUserResultsList();
      } else {
        return const Center(
          child: Text('Maaf, pengguna yang Anda cari tidak ditemukan.'),
        );
      }
    }
  }

  Widget _buildUserResultsList() {
    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            // backgroundImage: NetworkImage(user.avatarUrl),
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(user.username),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserProfilePage(user: user),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostResultsList() {
    final theme = Theme.of(context);
    final queryTag = _query.substring(1).toLowerCase();

    return ListView.builder(
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        // final hasImage = post.imageUrl != null || post.assetPath != null;

        return ListTile(
          leading: SizedBox(
            width: 50,
            height: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: theme.colorScheme.surfaceContainer,
                // child: hasImage
                //     ? (post.assetPath != null
                //     ? Image.asset(post.assetPath!, fit: BoxFit.cover)
                //     : Image.network(post.imageUrl!, fit: BoxFit.cover))
                //     : const Icon(Icons.notes),
              ),
            ),
          ),
          title: Text(
            post.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text('oleh ${post.user.displayName}'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4.0,
                runSpacing: 2.0,
                children: post.tags.map((tag) {
                  final isMatched = tag.toLowerCase().startsWith(queryTag);
                  return Chip(
                    label: Text('#$tag'),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: TextStyle(
                      fontSize: 10,
                      color: isMatched
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                    backgroundColor: isMatched
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withAlpha(
                            (255 * 0.1).round(),
                          ),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
          ),
          onTap: () {
            // Navigator.of(context).push(MaterialPageRoute(
            //   builder: (context) => PostDetailPage(posts: _postResults, initialIndex: index),
            // ));
          },
        );
      },
    );
  }
}
