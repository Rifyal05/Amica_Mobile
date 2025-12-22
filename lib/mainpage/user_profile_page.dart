import 'package:amica/mainpage/create_post_page.dart';
import 'package:amica/mainpage/edit_profile_page.dart';
import 'package:amica/mainpage/user_posts_page.dart';
import 'package:amica/mainpage/widgets/post_card.dart';
import 'package:amica/models/user_model.dart';
import 'package:amica/models/user_profile_model.dart';
import 'package:amica/provider/auth_provider.dart';
import 'package:amica/provider/profile_provider.dart';
import 'package:amica/mainpage/settings_page.dart';
import 'package:amica/services/chat_service.dart';
import 'package:amica/mainpage/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatelessWidget {
  final User? user;

  const UserProfilePage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: _UserProfileContent(user: user),
    );
  }
}

class _UserProfileContent extends StatefulWidget {
  final User? user;
  const _UserProfileContent({this.user});

  @override
  State<_UserProfileContent> createState() => _UserProfileContentState();
}

class _UserProfileContentState extends State<_UserProfileContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final String currentUserId = authProvider.currentUser?.id ?? '';
    final String targetId = widget.user?.id ?? currentUserId;

    if (targetId.isNotEmpty) {
      profileProvider.loadFullProfile(targetId, currentUserId: currentUserId);
      profileProvider.loadSavedPosts(targetId);
    }
  }

  void _onMessagePressed(UserProfileData profile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _chatService.getOrCreateChat(profile.id);

    if (!mounted) return;
    Navigator.pop(context);

    if (result['success']) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: result['chat_id'],
            chatName: profile.displayName,
            chatImage: profile.fullAvatarUrl,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Gagal membuka chat")),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    await context.read<ProfileProvider>().refreshProfile(
      currentUserId: currentUserId,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth == 2) {
      if (notification is ScrollEndNotification &&
          notification.metrics.extentAfter == 0) {
        context.read<ProfileProvider>().loadMorePosts();
      }
    }
    return false;
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text("Laporkan"),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text("Blokir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: (ctx, err, stack) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<ProfileProvider>();
    final profile = provider.userProfile;
    final bool canGoBack = Navigator.of(context).canPop();
    final bool isMe = profile?.status.isMe ?? false;

    if (provider.isLoadingProfile) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.errorMessage != null || profile == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.errorMessage ?? "Gagal memuat profil."),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _onRefresh,
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            top: true,
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              notificationPredicate: (notification) => notification.depth == 2,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _buildProfileDetails(context, profile),
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
                      _buildImageGridTab(provider),
                      _buildTextListTab(provider),
                      _buildSavedPostsTab(provider, profile.status.isMe),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMe && canGoBack)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new,
                                size: 14,
                                color: colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Kembali",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (canGoBack && !isMe) const SizedBox(width: 8),

                    GestureDetector(
                      onTap: _scrollToTop,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          size: 24,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGridTab(ProfileProvider provider) {
    if (provider.imagePosts.isEmpty && !provider.isLoadingPosts) {
      return _buildEmptyState(
        "Belum ada foto.",
        provider.userProfile!.status.isMe,
      );
    }
    return CustomScrollView(
      key: const PageStorageKey<String>('imageGrid'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (provider.userProfile!.status.isMe)
          SliverToBoxAdapter(child: _buildCreatePostButton()),
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = provider.imagePosts[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: UserPostsFeedPage(
                          posts: provider.imagePosts,
                          initialIndex: index,
                          username: provider.userProfile?.username ?? 'User',
                          profileProvider: provider,
                        ),
                      ),
                    ),
                  );
                },
                child: _buildNetworkImage(post.fullImageUrl!),
              );
            }, childCount: provider.imagePosts.length),
          ),
        ),
        if (provider.isLoadingPosts)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTextListTab(ProfileProvider provider) {
    if (provider.textPosts.isEmpty) {
      return _buildEmptyState(
        "Belum ada postingan teks.",
        provider.userProfile!.status.isMe,
      );
    }
    return CustomScrollView(
      key: const PageStorageKey<String>('textList'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (provider.userProfile!.status.isMe)
          SliverToBoxAdapter(child: _buildCreatePostButton()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => PostCard(
              key: ValueKey(provider.textPosts[index].id),
              post: provider.textPosts[index],
            ),
            childCount: provider.textPosts.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSavedPostsTab(ProfileProvider provider, bool isMe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isMe) {
      return CustomScrollView(
        key: const PageStorageKey<String>('savedPostsMe'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(
                    provider.myPrivacySetting
                        ? Icons.public
                        : Icons.lock_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.myPrivacySetting
                              ? 'Koleksi Publik'
                              : 'Koleksi Pribadi',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          provider.myPrivacySetting
                              ? 'Semua orang bisa melihat ini'
                              : 'Hanya kamu yang bisa melihat ini',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: provider.myPrivacySetting,
                    activeColor: colorScheme.primary,
                    onChanged: (val) async {
                      bool success = await provider.togglePrivacySetting(val);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Gagal memperbarui pengaturan privasi.",
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (provider.isLoadingSaved)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.savedPosts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text("Belum ada postingan yang disimpan.")),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostCard(post: provider.savedPosts[index]),
                childCount: provider.savedPosts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    } else {
      if (provider.isSavedCollectionPrivate) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_person_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Koleksi ini bersifat pribadi.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      if (provider.isLoadingSaved) {
        return const Center(child: CircularProgressIndicator());
      } else if (provider.savedPosts.isEmpty) {
        return const Center(child: Text("Belum ada postingan tersimpan."));
      }
      return CustomScrollView(
        key: const PageStorageKey<String>('savedPostsVisitor'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PostCard(post: provider.savedPosts[index]),
              childCount: provider.savedPosts.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }
  }

  Widget _buildEmptyState(String msg, bool isMe) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isMe) SliverToBoxAdapter(child: _buildCreatePostButton()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(msg)),
        ),
      ],
    );
  }

  Widget _buildCreatePostButton() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreatePostPage(),
            fullscreenDialog: true,
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Buat Postingan Baru...',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context, UserProfileData profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isMe = profile.status.isMe;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: profile.fullBannerUrl != null
                  ? _buildNetworkImage(profile.fullBannerUrl!)
                  : Container(color: Colors.grey.shade300),
            ),
            Positioned(
              bottom: -50,
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 4),
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: profile.fullAvatarUrl != null
                      ? _buildNetworkImage(
                          profile.fullAvatarUrl!,
                          width: 100,
                          height: 100,
                        )
                      : const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Text(
          profile.displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '@${profile.username}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (profile.bio != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(context, '${profile.stats.posts}', 'Postingan'),
              _buildStatColumn(
                context,
                '${profile.stats.followers}',
                'Pengikut',
              ),
              _buildStatColumn(
                context,
                '${profile.stats.following}',
                'Mengikuti',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: isMe
                    ? FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(profile: profile),
                          ),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Profil"),
                      )
                    : FilledButton(
                        onPressed: () =>
                            context.read<ProfileProvider>().toggleFollow(),
                        style: FilledButton.styleFrom(
                          backgroundColor: profile.status.isFollowing
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.primary,
                          foregroundColor: profile.status.isFollowing
                              ? colorScheme.onSurface
                              : colorScheme.onPrimary,
                        ),
                        child: Text(
                          profile.status.isFollowing ? "Mengikuti" : "Ikuti",
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              if (!isMe) ...[
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: () => _onMessagePressed(profile),
                    child: const Text('Kirim Pesan'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _showUserMenu,
                  icon: const Icon(Icons.more_vert),
                ),
              ] else ...[
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.settings_outlined),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: Theme.of(context).colorScheme.surface, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
