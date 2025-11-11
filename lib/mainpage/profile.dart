import 'package:amica/mainpage/create_post_page.dart';
import 'package:amica/models/post_model.dart';
import 'package:amica/mainpage/connect.dart';
import 'package:amica/mainpage/post_detail_page.dart';
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late final TabController _mainTabController;
  late final TabController _savedTabController;

  bool _isCollectionPrivate = false;
  final bool isViewingOwnProfile = true;

  final List<Post> _userPosts = Post.dummyPosts.where((p) => p.user.id == 'user_001').toList();
  late final List<Post> _imagePosts;
  late final List<Post> _textPosts;
  late final List<Post> _savedImagePosts;
  late final List<Post> _savedTextPosts;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _savedTabController = TabController(length: 2, vsync: this);

    _imagePosts = _userPosts.where((p) => p.imageUrl != null || p.assetPath != null).toList();
    _textPosts = _userPosts.where((p) => p.imageUrl == null && p.assetPath == null).toList();

    final savedPosts = Post.dummyPosts.where((p) => p.user.id != 'user_001').toList();
    _savedImagePosts = savedPosts.where((p) => p.imageUrl != null || p.assetPath != null).toList();
    _savedTextPosts = savedPosts.where((p) => p.imageUrl == null && p.assetPath == null).toList();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _savedTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                    controller: _mainTabController,
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
            controller: _mainTabController,
            children: [
              Column(
                children: [
                  _buildCreatePostButton(),
                  const Divider(height: 1),
                  Expanded(child: _buildUserPostsGrid(_imagePosts)),
                ],
              ),
              Column(
                children: [
                  _buildCreatePostButton(),
                  const Divider(height: 1),
                  Expanded(child: _buildTextPostsList(_textPosts)),
                ],
              ),
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
                  'https://images.pexels.com/photos/933054/pexels-photo-933054.jpeg?auto=compress&cs=tinysrgb&w=1260',
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
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Text(
          'Bunda Hebat',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '@bundahebat123',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Menyebarkan positivitas dan saling mendukung. Di sini untuk mendengar dan membantu.',
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
          _buildStatColumn(context, '28', 'Postingan'),
          _buildStatColumn(context, '1.2K', 'Pengikut'),
          _buildStatColumn(context, '152', 'Koneksi'),
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
          child: FilledButton.icon(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ));
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            label: const Text('Edit Profil'),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ));
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.settings_outlined),
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
                : Image.network(post.imageUrl!, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  Widget _buildCreatePostButton() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CreatePostPage(),
          fullscreenDialog: true,
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Buat Postingan Baru',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.add_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPostsTab() {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (isViewingOwnProfile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Text(
                  'Koleksi Pribadi',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _isCollectionPrivate,
                  onChanged: (value) {
                    setState(() {
                      _isCollectionPrivate = value;
                    });
                  },
                ),
              ],
            ),
          ),
        if (isViewingOwnProfile || !_isCollectionPrivate) ...[
          const Divider(height: 1),
          TabBar(
            controller: _savedTabController,
            indicatorColor: theme.colorScheme.secondary,
            labelColor: theme.colorScheme.secondary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(icon: Icon(Icons.image_outlined)),
              Tab(icon: Icon(Icons.notes_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _savedTabController,
              children: [
                _buildUserPostsGrid(_savedImagePosts),
                _buildTextPostsList(_savedTextPosts),
              ],
            ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 48),
                  SizedBox(height: 16),
                  Text('Koleksi pengguna ini bersifat pribadi.'),
                ],
              ),
            ),
          ),
      ],
    );
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