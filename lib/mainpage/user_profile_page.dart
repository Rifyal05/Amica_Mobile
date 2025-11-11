import 'package:amica/models/post_model.dart';
import 'package:amica/models/user_model.dart';
import 'package:amica/mainpage/connect.dart';
import 'package:amica/mainpage/post_detail_page.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  final User user;
  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final bool _isCollectionPrivate = true;
  bool _isFollowing = false;

  late final List<Post> _userPosts;
  late final List<Post> _imagePosts;
  late final List<Post> _textPosts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userPosts = Post.dummyPosts.where((p) => p.user.id == widget.user.id).toList();
    _imagePosts = _userPosts.where((p) => p.imageUrl != null || p.assetPath != null).toList();
    _textPosts = _userPosts.where((p) => p.imageUrl == null && p.assetPath == null).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Laporkan Pengguna'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('Blokir Pengguna', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildProfileDetails(context),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: colorScheme.primary,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.notes_outlined)),
                      Tab(icon: Icon(Icons.bookmark_border)),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildUserPostsGrid(_imagePosts),
              _buildTextPostsList(_textPosts),
              _buildSavedPostsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 160,
              child: ClipRRect(
                child: Image.network(
                  widget.user.bannerUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              child: CircleAvatar(
                radius: 54,
                backgroundColor: theme.colorScheme.surface,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.user.avatarUrl),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Text(
          widget.user.displayName,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          widget.user.username,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            widget.user.bio,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsSection(context),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildActions(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(context, '15', 'Postingan'),
          _buildStatColumn(context, '2.5K', 'Pengikut'),
          _buildStatColumn(context, '210', 'Koneksi'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _isFollowing
              ? FilledButton.tonal(
            onPressed: () {
              setState(() => _isFollowing = false);
            },
            child: const Text('Mengikuti'),
          )
              : FilledButton(
            onPressed: () {
              setState(() => _isFollowing = true);
            },
            child: const Text('Ikuti'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('Kirim Pesan'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _showUserMenu,
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  Widget _buildTextPostsList(List<Post> posts) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }

  Widget _buildUserPostsGrid(List<Post> posts) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PostDetailPage(posts: posts, initialIndex: index),
            ));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: post.assetPath != null
                ? Image.asset(post.assetPath!, fit: BoxFit.cover)
                : Image.network(
              post.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedPostsTab() {
    if (_isCollectionPrivate) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48),
            SizedBox(height: 16),
            Text('Koleksi pengguna ini bersifat pribadi.'),
          ],
        ),
      );
    } else {
      return const Center(child: Text('Tidak ada postingan tersimpan.'));
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}