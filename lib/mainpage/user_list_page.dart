import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/user_service.dart';
import '../services/api_config.dart';
import 'user_profile_page.dart';
import 'widgets/verified_badge.dart';

class UserConnectionsPage extends StatefulWidget {
  final String userId;
  final String username;
  final int initialIndex;

  const UserConnectionsPage({
    super.key,
    required this.userId,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  State<UserConnectionsPage> createState() => _UserConnectionsPageState();
}

class _UserConnectionsPageState extends State<UserConnectionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: "Pengikut"),
            Tab(text: "Mengikuti"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pengguna...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UserListTab(
                  userId: widget.userId,
                  isFollowers: true,
                  searchQuery: _searchQuery,
                ),
                _UserListTab(
                  userId: widget.userId,
                  isFollowers: false,
                  searchQuery: _searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListTab extends StatefulWidget {
  final String userId;
  final bool isFollowers;
  final String searchQuery;

  const _UserListTab({
    required this.userId,
    required this.isFollowers,
    required this.searchQuery,
  });

  @override
  State<_UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<_UserListTab>
    with AutomaticKeepAliveClientMixin {
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _users = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasNext = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _UserListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _fetchInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasNext) {
        _fetchMore();
      }
    }
  }

  Future<void> _fetchInitial() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _page = 1;
      _users = [];
    });
    try {
      final res = widget.isFollowers
          ? await _userService.getFollowers(
              widget.userId,
              1,
              widget.searchQuery,
            )
          : await _userService.getFollowing(
              widget.userId,
              1,
              widget.searchQuery,
            );

      if (mounted) {
        setState(() {
          _users = res['users'];
          _hasNext = res['has_next'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMore() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _page++;
      final res = widget.isFollowers
          ? await _userService.getFollowers(
              widget.userId,
              _page,
              widget.searchQuery,
            )
          : await _userService.getFollowing(
              widget.userId,
              _page,
              widget.searchQuery,
            );

      if (mounted) {
        setState(() {
          _users.addAll(res['users']);
          _hasNext = res['has_next'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(int index) async {
    final user = _users[index];
    final String targetId = user['id'];
    final bool currentStatus = user['is_following'];

    setState(() {
      _users[index]['is_following'] = !currentStatus;
    });

    try {
      await _userService.followUser(targetId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _users[index]['is_following'] = currentStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengubah status follow")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _page == 1) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          widget.searchQuery.isEmpty
              ? (widget.isFollowers
                    ? "Belum ada pengikut"
                    : "Belum mengikuti siapapun")
              : "Tidak ditemukan",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _users.length + (_hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _users.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = _users[index];
        final String? avatarUrl = user['avatar_url'];
        final String fullAvatarUrl =
            (avatarUrl != null && !avatarUrl.startsWith('http'))
            ? '${ApiConfig.baseUrl}/$avatarUrl'
            : (avatarUrl ?? '');
        final bool isVerified = user['is_verified'] == true;

        return ListTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: ClipOval(
              child: fullAvatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fullAvatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  user['display_name'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) const VerifiedBadge(size: 14),
            ],
          ),
          subtitle: Text("@${user['username']}"),
          trailing: user['is_me'] == true
              ? null
              : SizedBox(
                  height: 32,
                  child: user['is_following']
                      ? OutlinedButton(
                          onPressed: () => _toggleFollow(index),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: const Text("Mengikuti"),
                        )
                      : FilledButton(
                          onPressed: () => _toggleFollow(index),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text("Ikuti"),
                        ),
                ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(userId: user['id']),
              ),
            );
          },
        );
      },
    );
  }
}
