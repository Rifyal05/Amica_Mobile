import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../provider/post_provider.dart';
import '../provider/navigation_provider.dart';
import '../provider/notification_provider.dart';
import 'widgets/post_card.dart';
import 'create_post_page.dart';
import 'notifications_page.dart';
import 'discover_page.dart';

class Connect extends StatefulWidget {
  const Connect({super.key});

  @override
  State<Connect> createState() => _ConnectState();
}

class _ConnectState extends State<Connect> with SingleTickerProviderStateMixin {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Terbaru', 'Mengikuti', 'Temukan'];
  late ScrollController _scrollController;
  bool _isNavVisible = true;
  NavigationProvider? _navProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = context.read<PostProvider>();
      final notifProvider = context.read<NotificationProvider>();

      if (postProvider.posts.isEmpty) {
        postProvider.fetchPosts();
      }
      notifProvider.fetchNotifications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navProvider == null) {
      _navProvider = Provider.of<NavigationProvider>(context, listen: false);
      _navProvider!.addListener(_handleScrollToTop);
    }
  }

  void _handleScrollToTop() {
    if (_navProvider!.selectedIndex == 0 &&
        _navProvider!.scrollToTopTime != null) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _onRefresh();
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostProvider>().fetchPosts();
    }

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isNavVisible) setState(() => _isNavVisible = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isNavVisible) setState(() => _isNavVisible = true);
    }
  }

  @override
  void dispose() {
    _navProvider?.removeListener(_handleScrollToTop);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<PostProvider>().refreshPosts();
  }

  void _onFilterChanged(int index) {
    if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const DiscoverPage()));
      return;
    }

    setState(() => _selectedFilterIndex = index);
    final provider = context.read<PostProvider>();

    if (index == 1) {
      provider.setFilter('following');
    } else {
      provider.setFilter('latest');
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreatePostPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  String _friendlyErrorMessage(String error) {
    if (error.contains("SocketException") ||
        error.contains("Connection refused")) {
      return "Gagal terhubung ke server.\nPastikan internet anda menyala.";
    } else if (error.contains("Timeout")) {
      return "Koneksi lambat, coba lagi ya.";
    }
    return "Terjadi kesalahan: $error";
  }

  Widget _buildErrorWidget(String error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: colorScheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Ups, ada masalah!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _friendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            _openCreatePost();
          }
        },
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              edgeOffset: 100,
              color: colorScheme.primary,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: false,
                    backgroundColor: colorScheme.surface.withOpacity(0.95),
                    elevation: 0,
                    centerTitle: false,
                    title: Text(
                      "Amica",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    actions: [
                      Consumer<NotificationProvider>(
                        builder: (context, notifProvider, child) {
                          return IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            ),
                            icon: Badge(
                              isLabelVisible: notifProvider.unreadCount > 0,
                              label: Text('${notifProvider.unreadCount}'),
                              backgroundColor: colorScheme.error,
                              child: Icon(
                                Icons.notifications_none_outlined,
                                color: colorScheme.onSurface,
                                size: 26,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: _openCreatePost,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: colorScheme.onSurface,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1),
                      child: Container(
                        height: 1,
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  if (postProvider.isUploading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            const LinearProgressIndicator(),
                            const SizedBox(height: 4),
                            Text(
                              "Mengirim postingan...",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (postProvider.posts.isEmpty && postProvider.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (postProvider.errorMessage != null &&
                      postProvider.posts.isEmpty)
                    SliverFillRemaining(
                      child: _buildErrorWidget(
                        postProvider.errorMessage!,
                        colorScheme,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == postProvider.posts.length) {
                            return postProvider.hasMore
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox(height: 80);
                          }
                          final post = postProvider.posts[index];
                          return PostCard(key: ValueKey(post.id), post: post);
                        },
                        childCount:
                            postProvider.posts.length +
                            (postProvider.hasMore ? 1 : 0),
                      ),
                    ),
                ],
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _isNavVisible ? 16 : -80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(
                      0.95,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_filters.length, (index) {
                      bool isSelected = _selectedFilterIndex == index;
                      return GestureDetector(
                        onTap: () => _onFilterChanged(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
