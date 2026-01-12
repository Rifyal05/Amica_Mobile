import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'article_detail_page.dart';
import 'sdq_dashboard_page.dart';
import 'chatbot_page.dart';

import '../models/article_model.dart';
import '../services/api_config.dart';
import '../provider/navigation_provider.dart';

class Educative extends StatefulWidget {
  const Educative({super.key});

  @override
  State<Educative> createState() => _EducativePageState();
}

class _EducativePageState extends State<Educative>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Semua',
    'Bullying',
    'Peran Orang tua',
    'Penanganan kasus',
    'Hukum dan Keamanan',
    'Lingkungan Sekolah',
    'Parenting Positif',
    'Kesehatan Mental',
    'Perilaku dan Psikologi',
  ];

  List<Article> _articles = [];
  Article? _featuredArticle;
  int _page = 1;
  final int _limit = 10;
  bool _hasNextPage = true;
  bool _isFirstLoadRunning = true;
  bool _isLoadMoreRunning = false;
  late ScrollController _scrollController;
  String _searchQuery = '';
  String _errorMessage = '';
  NavigationProvider? _navProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _fetchFirstBatch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navProvider == null) {
      _navProvider = Provider.of<NavigationProvider>(context, listen: false);
      _navProvider!.addListener(_handleScrollToTop);
    }
  }

  @override
  void dispose() {
    _navProvider?.removeListener(_handleScrollToTop);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollToTop() {
    if (_navProvider != null &&
        _navProvider!.selectedIndex == 1 &&
        _navProvider!.scrollToTopTime != null) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _handleRefresh();
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 &&
        !_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _hasNextPage) {
      _fetchNextBatch();
    }
  }

  String _buildApiUrl(int page) {
    String baseUrlStr =
        '${ApiConfig.baseUrl}/api/articles?page=$page&limit=$_limit';
    if (_selectedFilterIndex != 0) {
      baseUrlStr += '&category=${_filters[_selectedFilterIndex]}';
    }
    if (_searchQuery.isNotEmpty) {
      baseUrlStr += '&search=$_searchQuery';
    }
    return baseUrlStr;
  }

  Future<void> _fetchFirstBatch() async {
    setState(() {
      _isFirstLoadRunning = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(Uri.parse(_buildApiUrl(1)));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Article> loaded = (data['articles'] as List)
            .map((json) => Article.fromJson(json))
            .toList();

        bool hasNext = loaded.length == _limit;
        if (data['pagination'] != null) {
          hasNext = data['pagination']['has_next'] ?? hasNext;
        }

        setState(() {
          _articles = loaded;
          _hasNextPage = hasNext;
          if (_articles.isNotEmpty) {
            final featured = _articles.where((a) => a.isFeatured).toList();
            _featuredArticle = featured.isNotEmpty
                ? featured[Random().nextInt(featured.length)]
                : _articles.first;
          } else {
            _featuredArticle = null;
          }
        });
      } else {
        setState(() => _errorMessage = "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Gagal memuat data: ${e.toString()}");
    } finally {
      setState(() => _isFirstLoadRunning = false);
    }
  }

  Future<void> _fetchNextBatch() async {
    if (!_hasNextPage) return;
    setState(() => _isLoadMoreRunning = true);
    try {
      final response = await http.get(Uri.parse(_buildApiUrl(_page + 1)));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Article> newArts = (data['articles'] as List)
            .map((json) => Article.fromJson(json))
            .toList();
        setState(() {
          _page++;
          _articles.addAll(newArts);
          _hasNextPage = (data['pagination'] != null)
              ? data['pagination']['has_next']
              : newArts.length == _limit;
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoadMoreRunning = false);
    }
  }

  Future<void> _handleRefresh() async {
    _page = 1;
    _hasNextPage = true;
    _articles.clear();
    await _fetchFirstBatch();
  }

  void _showFeatureOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.orange,
                ),
                title: const Text('Deteksi Dini (Kuis SDQ)'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SdDashboardPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.purple,
                ),
                title: const Text('Tanya Amica (AI Assistant)'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatbotPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isFirstLoadRunning && _articles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _articles.isEmpty
          ? _buildErrorState(theme)
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SafeArea(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildSearchBar(context)),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildFilterChips(context)),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    if (_searchQuery.isEmpty && _featuredArticle != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: _buildFeaturedArticleCard(
                            context,
                            article: _featuredArticle!,
                          ),
                        ),
                      ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Bacaan Terkini'
                              : 'Hasil Pencarian',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    if (!_isFirstLoadRunning && _articles.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Artikel tidak ditemukan",
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildArticleListItem(
                            context,
                            article: _articles[index],
                          );
                        }, childCount: _articles.length),
                      ),

                    if (_isLoadMoreRunning)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'educative_fab',
        onPressed: _showFeatureOptions,
        label: const Text('Layanan Amica'),
        icon: const Icon(Icons.psychology_outlined),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: theme.colorScheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Ups, ada kendala!",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panduan Orang Tua',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Sumber daya untuk mendampingi tumbuh kembang anak.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        onSubmitted: (val) {
          setState(() {
            _searchQuery = val;
            _page = 1;
            _hasNextPage = true;
          });
          _fetchFirstBatch();
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari artikel...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _page = 1;
                      _hasNextPage = true;
                    });
                    _fetchFirstBatch();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilterIndex == index;
          return ChoiceChip(
            label: Text(_filters[index]),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilterIndex = index;
                  _page = 1;
                  _hasNextPage = true;
                  _searchQuery = '';
                });
                _fetchFirstBatch();
              }
            },
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            shape: const StadiumBorder(),
            side: BorderSide.none,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }

  Widget _buildNetworkImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
      ),
      fadeInDuration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildFeaturedArticleCard(
    BuildContext context, {
    required Article article,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ArticleDetailPage(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20.0),
        child: SizedBox(
          height: 250,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: _buildNetworkImage(article.imageUrl),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildArticleListItem(
    BuildContext context, {
    required Article article,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ArticleDetailPage(article: article),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: _buildNetworkImage(
                article.imageUrl,
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readTime} min read',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
    );
  }
}
