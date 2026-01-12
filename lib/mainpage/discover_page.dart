import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/article_model.dart';
import '../services/api_config.dart';
import '../services/discover_services.dart';
import '../provider/auth_provider.dart';
import '../provider/post_provider.dart';
import 'user_profile_page.dart';
import 'post_detail_page.dart';
import 'article_detail_page.dart';

class DiscoverPage extends StatefulWidget {
  final String? initialQuery;

  const DiscoverPage({super.key, this.initialQuery});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  final DiscoverService _discoverService = DiscoverService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late TabController _mainTabController;
  Timer? _debounce;

  bool _isLoading = true;
  bool _isSearching = false;
  bool _isPerformingSearch = false;
  String _queryText = '';

  List<String> _tags = [];
  List<User> _verifiedUsersPool = [];
  List<Article> _dashboardArticles = [];

  List<User> _userResults = [];
  List<Post> _postResults = [];
  List<Article> _articleResults = [];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _isLoading = false;
      _executeSearch(widget.initialQuery!);
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _mainTabController.dispose();
    if (_debounce != null) {
      _debounce!.cancel();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final result = await _discoverService.getDiscoverDashboard();
    if (!mounted) {
      return;
    }
    if (result['success']) {
      setState(() {
        _tags = result['tags'];
        _verifiedUsersPool = result['users'];
        _dashboardArticles = (result['articles'] as List)
            .map((e) => Article.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _executeSearch(String val) async {
    setState(() {
      _isSearching = true;
      _isPerformingSearch = true;
      _queryText = val;
    });

    final result = await _discoverService.search(val);
    if (!mounted) {
      return;
    }
    setState(() {
      _isPerformingSearch = false;
      if (result['success']) {
        _userResults = result['users'];
        _postResults = result['posts'];
        _articleResults = (result['articles'] as List)
            .map((e) => Article.fromJson(e))
            .toList();
      }
    });
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (val.trim().isNotEmpty) {
        _executeSearch(val);
      } else {
        setState(() {
          _isSearching = false;
          _queryText = '';
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _queryText = '';
    });
  }

  Future<void> _openArticle(Article article) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final fullArticle = await _discoverService.getArticleDetail(article.id);

    if (!mounted) {
      return;
    }
    Navigator.pop(context);

    if (fullArticle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailPage(article: fullArticle),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleDetailPage(article: article)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentId = context.read<AuthProvider>().currentUser?.id;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Temukan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.initialQuery != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari topik, pengguna, artikel...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: _clearSearch,
                    child: const Text(
                      "Hapus",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: TabBar(
              controller: _mainTabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: "Beranda"),
                Tab(text: "Orang"),
                Tab(text: "Post"),
                Tab(text: "Artikel"),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _mainTabController,
                    children: [
                      _isSearching
                          ? _buildSearchResults("all", currentId)
                          : _buildHomeTab(colorScheme),
                      _PeopleTabSection(
                        isSearching: _isSearching,
                        userResults: _userResults,
                      ),
                      _PostTabSection(
                        isSearching: _isSearching,
                        postResults: _postResults,
                      ),
                      _ArticleTabSection(
                        isSearching: _isSearching,
                        articleResults: _articleResults,
                        onArticleTap: _openArticle,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Trending Tags 🔥",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _tags
                      .map((tag) => _buildTagBubble(tag, colorScheme))
                      .toList(),
                ),
              ],
            ),
          ),
          _buildSectionHeader(
            "Saran Pengguna ✨",
            () => _mainTabController.animateTo(1),
          ),
          SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _verifiedUsersPool.length,
              itemBuilder: (ctx, i) =>
                  _buildUserCard(_verifiedUsersPool[i], colorScheme),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "Artikel Terbaru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (_dashboardArticles.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dashboardArticles.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (ctx, i) =>
                  _buildArticleCard(_dashboardArticles[i], colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(String type, String? currentId) {
    if (_isPerformingSearch) {
      return const Center(child: CircularProgressIndicator());
    }

    if (type == 'all') {
      if (_userResults.isEmpty &&
          _postResults.isEmpty &&
          _articleResults.isEmpty) {
        return _buildEmptyState(
          "Hasil pencarian tidak ditemukan untuk '$_queryText'",
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_userResults.isNotEmpty) ...[
            const Text(
              "Pengguna",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._userResults.map((u) => _buildCompactUser(u)),
            const Divider(),
          ],
          if (_articleResults.isNotEmpty) ...[
            const Text(
              "Artikel",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._articleResults
                .take(3)
                .map(
                  (a) => _buildArticleCard(a, Theme.of(context).colorScheme),
                ),
            const Divider(),
          ],
          if (_postResults.isNotEmpty) ...[
            const Text(
              "Postingan Pengguna",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _postResults.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final post = _postResults[i];
                if (post.fullImageUrl != null) {
                  return _buildPinterestCard(post);
                } else {
                  return _buildTextPostCard(
                    post,
                    Theme.of(context).colorScheme,
                  );
                }
              },
            ),
          ],
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildSectionHeader(String title, VoidCallback onTapMore) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: onTapMore,
            child: const Text(
              "Lihat Lainnya",
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagBubble(String tag, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        _searchController.text = tag;
        _executeSearch(tag);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Text(
          "#$tag",
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfilePage(user: user)),
      ),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 85,
                  width: double.infinity,
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  child: user.bannerUrl != null
                      ? CachedNetworkImage(
                          imageUrl: user.fullBannerUrl!,
                          fit: BoxFit.cover,
                          memCacheHeight: 250,
                        )
                      : null,
                ),
                Positioned(
                  top: 50,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: user.avatarUrl != null
                            ? CachedNetworkImageProvider(user.fullAvatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 45, 8, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (user.isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Image.asset(
                            'source/images/verified.png',
                            width: 16,
                            height: 16,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    "@${user.username}",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _miniStat("Post", "${user.stats?['posts'] ?? 0}"),
                      _miniStat("Follower", "${user.stats?['followers'] ?? 0}"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCompactUser(User user) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.fullAvatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(user.displayName[0].toUpperCase())
            : null,
      ),
      title: Row(
        children: [
          Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (user.isVerified)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Image.asset('source/images/verified.png', width: 14),
            ),
        ],
      ),
      subtitle: Text("@${user.username}", style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfilePage(user: user)),
      ),
    );
  }

  Widget _buildPinterestCard(Post post) {
    if (post.fullImageUrl == null) {
      return const SizedBox();
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          child: CachedNetworkImage(
            imageUrl: ApiConfig.getFullUrl(post.fullImageUrl)!,
            fit: BoxFit.cover,
            memCacheHeight: 600,
            placeholder: (_, __) =>
                Container(color: Colors.grey[900], height: 150),
          ),
        ),
      ),
    );
  }

  Widget _buildTextPostCard(Post p, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailPage(post: p)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.caption,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: p.author.avatarUrl != null
                        ? CachedNetworkImageProvider(
                            ApiConfig.getFullUrl(p.author.avatarUrl)!,
                          )
                        : null,
                    child: p.author.avatarUrl == null
                        ? Text(p.author.displayName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.author.username,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 18,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${p.likesCount}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.comment,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${p.commentsCount}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(Article article, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openArticle(article),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child: article.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.imageUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 300,
                        )
                      : const Icon(Icons.article, size: 40),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Oleh ${article.author}",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${article.readTime} min read",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleTabSection extends StatefulWidget {
  final bool isSearching;
  final List<User> userResults;

  const _PeopleTabSection({
    required this.isSearching,
    required this.userResults,
  });

  @override
  State<_PeopleTabSection> createState() => _PeopleTabSectionState();
}

class _PeopleTabSectionState extends State<_PeopleTabSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final DiscoverService _service = DiscoverService();
  List<User> _verifiedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isSearching) {
      _fetchData();
    }
  }

  @override
  void didUpdateWidget(_PeopleTabSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSearching && !widget.isSearching) {
      if (_verifiedList.isEmpty) {
        _fetchData();
      }
    }
  }

  Future<void> _fetchData() async {
    final currentId = context.read<AuthProvider>().currentUser?.id;
    final ver = await _service.getUserList(type: 'verified');
    if (mounted) {
      setState(() {
        _verifiedList = ver.where((u) => u.id != currentId).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFollow(User user) async {
    final listToUpdate = widget.isSearching
        ? widget.userResults
        : _verifiedList;
    final index = listToUpdate.indexOf(user);

    if (index == -1) return;

    final newUser = user.copyWith(isFollowing: !user.isFollowing);

    setState(() {
      listToUpdate[index] = newUser;
    });

    try {
      await context.read<PostProvider>().toggleFollowFromFeed(user.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          listToUpdate[index] = user;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memproses permintaan")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.isSearching) {
      if (widget.userResults.isEmpty) {
        return const Center(
          child: Text(
            "Pengguna tidak ditemukan",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.userResults.length,
        separatorBuilder: (_, __) => const Divider(height: 32, thickness: 0.5),
        itemBuilder: (ctx, i) =>
            _buildCleanTile(widget.userResults[i], showFollow: true),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _verifiedList.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 32, thickness: 0.5),
              itemBuilder: (ctx, i) =>
                  _buildCleanTile(_verifiedList[i], showFollow: true),
            ),
    );
  }

  Widget _buildCleanTile(User u, {bool showFollow = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: u.avatarUrl != null
            ? CachedNetworkImageProvider(u.fullAvatarUrl!)
            : null,
        child: u.avatarUrl == null
            ? Text(
                u.displayName[0].toUpperCase(),
                style: const TextStyle(fontSize: 20),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              u.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          if (u.isVerified)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Image.asset('source/images/verified.png', width: 16),
            ),
        ],
      ),
      subtitle: Text(
        "${u.stats?['posts'] ?? 0} Post • ${u.stats?['followers'] ?? 0} Pengikut",
        style: const TextStyle(fontSize: 13),
      ),
      trailing: showFollow
          ? SizedBox(
              height: 32,
              child: u.isFollowing
                  ? OutlinedButton(
                      onPressed: () => _handleFollow(u),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: const Text("Mengikuti"),
                    )
                  : ElevatedButton(
                      onPressed: () => _handleFollow(u),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: const Text("Ikuti"),
                    ),
            )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfilePage(user: u)),
      ),
    );
  }
}

class _PostTabSection extends StatefulWidget {
  final bool isSearching;
  final List<Post> postResults;

  const _PostTabSection({required this.isSearching, required this.postResults});

  @override
  State<_PostTabSection> createState() => _PostTabSectionState();
}

class _PostTabSectionState extends State<_PostTabSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final DiscoverService _service = DiscoverService();
  final ScrollController _scrollController = ScrollController();
  List<Post> _imagePosts = [];
  List<Post> _textPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNext = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isSearching) {
      _fetchData();
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent * 0.8 &&
            !_isLoadingMore &&
            _hasNext) {
          _loadMore();
        }
      });
    }
  }

  @override
  void didUpdateWidget(_PostTabSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSearching && !widget.isSearching) {
      if (_imagePosts.isEmpty && _textPosts.isEmpty) {
        _fetchData();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final currentId = context.read<AuthProvider>().currentUser?.id;
    final imgs = await _service.getPostList(type: 'image', page: 1);
    final txts = await _service.getPostList(type: 'text', page: 1);
    if (mounted) {
      setState(() {
        _imagePosts = imgs.where((p) => p.author.id != currentId).toList();
        _textPosts = txts.where((p) => p.author.id != currentId).toList();
        _isLoading = false;
        _currentPage = 1;
        _hasNext = true;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final currentId = context.read<AuthProvider>().currentUser?.id;
    final next = await _service.getPostList(
      type: 'all',
      page: _currentPage + 1,
    );
    if (mounted) {
      setState(() {
        if (next.isEmpty) {
          _hasNext = false;
        } else {
          final filtered = next.where((p) => p.author.id != currentId).toList();
          _imagePosts.addAll(filtered.where((p) => p.fullImageUrl != null));
          _textPosts.addAll(filtered.where((p) => p.fullImageUrl == null));
          _currentPage++;
        }
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isSearching) {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Gambar"),
                Tab(text: "Teks"),
              ],
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildImageGrid(
                    widget.postResults
                        .where((p) => p.fullImageUrl != null)
                        .toList(),
                  ),
                  _buildTextList(
                    widget.postResults
                        .where((p) => p.fullImageUrl == null)
                        .toList(),
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "Gambar"),
              Tab(text: "Teks"),
            ],
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: _fetchData,
                        child: _buildImageGrid(_imagePosts),
                      ),
                      RefreshIndicator(
                        onRefresh: _fetchData,
                        child: _buildTextList(_textPosts, colorScheme),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<Post> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada gambar ditemukan",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return MasonryGridView.count(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: posts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == posts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildPinterestGrid(posts[i]);
      },
    );
  }

  Widget _buildTextList(List<Post> posts, ColorScheme colorScheme) {
    if (posts.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada postingan teks ditemukan",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: posts.length + (_isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, i) {
        if (i == posts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildTextPostCard(posts[i], colorScheme);
      },
    );
  }

  Widget _buildPinterestGrid(Post p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailPage(post: p)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          child: CachedNetworkImage(
            imageUrl: ApiConfig.getFullUrl(p.fullImageUrl)!,
            fit: BoxFit.cover,
            memCacheHeight: 600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextPostCard(Post p, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailPage(post: p)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.caption,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: p.author.avatarUrl != null
                        ? CachedNetworkImageProvider(
                            ApiConfig.getFullUrl(p.author.avatarUrl)!,
                          )
                        : null,
                    child: p.author.avatarUrl == null
                        ? Text(p.author.displayName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.author.username,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 18,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${p.likesCount}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.comment,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${p.commentsCount}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleTabSection extends StatefulWidget {
  final bool isSearching;
  final List<Article> articleResults;
  final Function(Article) onArticleTap;

  const _ArticleTabSection({
    required this.isSearching,
    required this.articleResults,
    required this.onArticleTap,
  });

  @override
  State<_ArticleTabSection> createState() => _ArticleTabSectionState();
}

class _ArticleTabSectionState extends State<_ArticleTabSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final DiscoverService _service = DiscoverService();
  final ScrollController _scrollController = ScrollController();
  List<Article> _articles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNext = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isSearching) {
      _fetchData();
    }
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore &&
          _hasNext) {
        _loadMore();
      }
    });
  }

  @override
  void didUpdateWidget(_ArticleTabSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSearching && !widget.isSearching) {
      if (_articles.isEmpty) {
        _fetchData();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final response = await _service.getArticleList(page: 1);
    if (mounted) {
      setState(() {
        _articles = response;
        _isLoading = false;
        _currentPage = 1;
        _hasNext = response.length >= 10;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final next = await _service.getArticleList(page: _currentPage + 1);
    if (mounted) {
      setState(() {
        if (next.isEmpty) {
          _hasNext = false;
        } else {
          _articles.addAll(next);
          _currentPage++;
        }
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final list = widget.isSearching ? widget.articleResults : _articles;
    if (_isLoading && !widget.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return const Center(
        child: Text(
          "Artikel tidak ditemukan",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == list.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildLargeArticleCard(list[i]);
        },
      ),
    );
  }

  Widget _buildLargeArticleCard(Article article) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => widget.onArticleTap(article),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[300],
                  child: article.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.imageUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 350,
                        )
                      : const Icon(Icons.article, size: 40),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Dipublish oleh ${article.author}",
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${article.readTime} min read",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
