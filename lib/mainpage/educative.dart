import 'dart:convert';
import 'dart:async';
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
  List<String> _filters = ['Semua'];

  List<Article> _articles = [];
  List<Article> _featuredArticles = [];
  int _page = 1;
  final int _limit = 10;
  bool _hasNextPage = true;
  bool _isFirstLoadRunning = true;
  bool _isLoadMoreRunning = false;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _errorMessage = '';
  NavigationProvider? _navProvider;

  int _currentFeaturedIndex = 0;
  late PageController _pageController;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _pageController = PageController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchCategories();
    await _fetchFeaturedArticles();
    await _fetchFirstBatch();
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
    _sliderTimer?.cancel();
    _pageController.dispose();
    _navProvider?.removeListener(_handleScrollToTop);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startSliderTimer() {
    _sliderTimer?.cancel();
    if (_featuredArticles.length > 1) {
      _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          int nextStep = _currentFeaturedIndex + 1;
          if (nextStep >= _featuredArticles.length) nextStep = 0;
          _pageController.animateToPage(
            nextStep,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
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
    if (_selectedFilterIndex != 0 && _filters.isNotEmpty) {
      baseUrlStr +=
          '&category=${Uri.encodeComponent(_filters[_selectedFilterIndex])}';
    }
    if (_searchQuery.isNotEmpty) {
      baseUrlStr += '&q=${Uri.encodeComponent(_searchQuery)}';
    }
    return baseUrlStr;
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/articles/categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _filters = List<String>.from(data);
          });
        }
      }
    } catch (e) {
      debugPrint("Error categories: $e");
    }
  }

  Future<void> _fetchFeaturedArticles() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/articles?is_featured=true&limit=5'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Article> loaded = (data['articles'] as List)
            .map((json) => Article.fromJson(json))
            .toList();
        if (mounted) {
          setState(() {
            _featuredArticles = loaded;
            _startSliderTimer();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching featured: $e");
    }
  }

  Future<void> _fetchFirstBatch() async {
    if (!mounted) return;
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

        bool hasNext = false;
        if (data['pagination'] != null) {
          hasNext = data['pagination']['has_next'] ?? false;
        } else {
          hasNext = loaded.length == _limit;
        }

        if (mounted) {
          setState(() {
            _articles = loaded;
            _hasNextPage = hasNext;
            _page = 1;
          });
        }
      } else {
        if (mounted) {
          setState(
            () => _errorMessage =
                "Gagal memuat data (Server ${response.statusCode})",
          );
        }
      }
    } catch (e) {
      String errorStr = e.toString().toLowerCase();
      String friendlyMsg = "Terjadi kesalahan saat memuat data.";

      if (errorStr.contains('socketexception') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('network is unreachable') ||
          errorStr.contains('clientexception')) {
        friendlyMsg = "Tidak ada koneksi internet.\nPeriksa jaringan Anda.";
      } else if (errorStr.contains('timeout')) {
        friendlyMsg = "Waktu koneksi habis.\nSilakan coba lagi.";
      }

      if (mounted) {
        setState(() => _errorMessage = friendlyMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isFirstLoadRunning = false);
      }
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

        bool hasNext = false;
        if (data['pagination'] != null) {
          hasNext = data['pagination']['has_next'] ?? false;
        } else {
          hasNext = newArts.length == _limit;
        }

        if (mounted) {
          setState(() {
            _page++;
            _articles.addAll(newArts);
            _hasNextPage = hasNext;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadMoreRunning = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _errorMessage = '';
    });
    await _fetchCategories();
    await _fetchFeaturedArticles();
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
      appBar: AppBar(
        title: const Text(
          "Edukasi Orang Tua",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
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

                    if (_searchQuery.isEmpty && _featuredArticles.isNotEmpty)
                      SliverToBoxAdapter(child: _buildFeaturedSlider(context)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Bacaan Terkini'
                              : 'Hasil Pencarian untuk "$_searchQuery"',
                          style: theme.textTheme.titleMedium?.copyWith(
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mari belajar bersama untuk tumbuh kembang anak.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        controller: _searchController,
        onSubmitted: (val) {
          setState(() {
            _searchQuery = val.trim();
            _page = 1;
            _hasNextPage = true;
          });
          _fetchFirstBatch();
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari topik atau judul...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _page = 1;
                      _hasNextPage = true;
                    });
                    _fetchFirstBatch();
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _searchQuery = _searchController.text.trim();
                    _page = 1;
                    _hasNextPage = true;
                  });
                  _fetchFirstBatch();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                  _searchController.clear();
                });
                _fetchFirstBatch();
              }
            },
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide.none,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }

  Widget _buildFeaturedSlider(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _featuredArticles.length,
            onPageChanged: (index) {
              setState(() => _currentFeaturedIndex = index);
            },
            itemBuilder: (context, index) {
              return _buildFeaturedArticleCard(
                context,
                article: _featuredArticles[index],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _featuredArticles.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentFeaturedIndex == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentFeaturedIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
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
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Stack(
            children: [
              Positioned.fill(child: _buildNetworkImage(article.imageUrl)),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
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
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: theme.textTheme.titleMedium?.copyWith(
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'art_img_${article.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: _buildNetworkImage(
                  article.imageUrl,
                  width: 90,
                  height: 90,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readTime} mnt baca',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
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
