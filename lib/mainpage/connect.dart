import 'package:amica/mainpage/comments_page.dart';
import 'package:amica/mainpage/create_post_page.dart';
import 'package:amica/mainpage/discover_page.dart';
import 'package:amica/mainpage/notifications_page.dart';
import 'package:amica/mainpage/user_profile_page.dart';
import 'package:amica/provider/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import 'widgets/adaptive_image_card.dart';

class Connect extends StatefulWidget {
  const Connect({super.key});

  @override
  State<Connect> createState() => _ConnectState();
}

class _ConnectState extends State<Connect> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Terbaru', 'Mengikuti', 'Temukan'];
  final List<Post> _posts = Post.dummyPosts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Amica",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outline
                .withAlpha((255 * 0.2).round()), // withOpacity is deprecated
            width: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ));
            },
            icon: Icon(Icons.notifications_none_outlined, color: colorScheme.onSurface, size: 26),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CreatePostPage(),
                fullscreenDialog: true,
              ));
            },
            icon: Icon(Icons.add_circle_outline, color: colorScheme.onSurface, size: 26),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: _posts[index]);
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withAlpha((255 * 0.95).round()),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  children: List.generate(_filters.length, (index) {
                    bool isSelected = _selectedFilterIndex == index;
                    return ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          if (index == 2) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const DiscoverPage(),
                            ));
                          } else {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                          }
                        }
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected && index != 2
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  bool _isSaved = false;
  final String currentUserId = 'user_001';

  void _showPostMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Ikuti Pengguna'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Laporkan Postingan'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToProfile() {
    if (widget.post.user.id == currentUserId) {
      context.read<NavigationProvider>().setIndex(3);
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => UserProfilePage(user: widget.post.user),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = widget.post.imageUrl != null || widget.post.assetPath != null;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: _navigateToProfile,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(widget.post.user.avatarUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _navigateToProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.post.timestamp.hour} jam lalu',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.post.user.id != currentUserId)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showPostMenu,
                  )
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.caption,
              style: TextStyle(
                fontSize: hasImage ? 15 : 18,
                height: 1.4,
              ),
            ),
            if (widget.post.tags.isNotEmpty) const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: widget.post.tags.map((tag) {
                return Chip(
                  label: Text('#$tag'),
                  padding: EdgeInsets.zero,
                  labelStyle: TextStyle(fontSize: 12, color: colorScheme.primary),
                  backgroundColor: colorScheme.primary.withAlpha((255 * 0.1).round()),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            if (hasImage) ...[
              const SizedBox(height: 12),
              if (widget.post.assetPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: Image.asset(
                      widget.post.assetPath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                )
              else
                AdaptiveImageCard(
                  imageUrl: widget.post.imageUrl!,
                ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                _buildInteractiveIcon(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${widget.post.likes}',
                  color: _isLiked ? Colors.redAccent : colorScheme.onSurfaceVariant,
                  onPressed: () => setState(() => _isLiked = !_isLiked),
                ),
                const SizedBox(width: 16),
                _buildInteractiveIcon(
                  icon: Icons.chat_bubble_outline,
                  label: '${widget.post.comments}',
                  color: colorScheme.onSurfaceVariant,
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const CommentsPage(),
                    ));
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _isSaved = !_isSaved),
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}