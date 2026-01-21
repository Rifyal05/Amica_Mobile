import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../models/post_model.dart';
import '../../provider/auth_provider.dart';
import '../../provider/navigation_provider.dart';
import '../../provider/post_provider.dart';
import '../../provider/profile_provider.dart';
import '../../services/api_config.dart';
import '../../services/report_serices.dart';
import '../../services/custom_cache_manager.dart';
import '../helper/utils_helper.dart';
import '../post_detail_page.dart';
import '../user_profile_page.dart';
import '../create_post_page.dart';
import '../discover_page.dart';
import 'expandable_caption.dart';
import 'adaptive_image_card.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isDetailView;

  const PostCard({super.key, required this.post, this.isDetailView = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<_LikeButtonWithBurstState> _likeButtonKey = GlobalKey();
  double _dragExtent = 0.0;
  final double _slideThreshold = 80.0;

  late bool _isLiked;
  late int _likesCount;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _isSaved = widget.post.isSaved;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      setState(() {
        _isLiked = widget.post.isLiked;
        _likesCount = widget.post.likesCount;
        _isSaved = widget.post.isSaved;
      });
    }
  }

  String? _getAvatarUrl(String? url) {
    final fullUrl = ApiConfig.getFullUrl(url);
    if (fullUrl == null || fullUrl.isEmpty) return null;
    return fullUrl;
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 7) return DateFormat('d MMM yyyy').format(timestamp);
    if (diff.inDays >= 1) return "${diff.inDays}h";
    if (diff.inHours >= 1) return "${diff.inHours}j";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m";
    return "Baru saja";
  }

  Future<void> _navigateToDetail() async {
    if (widget.isDetailView) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailPage(post: widget.post)),
    );

    if (mounted) {
      setState(() {
        _dragExtent = 0.0;
      });
    }
  }

  void _navigateToProfile() {
    final currentUser = context.read<AuthProvider>().currentUser;
    final bool isMe = widget.post.author.id == currentUser?.id;

    if (isMe) {
      context.read<NavigationProvider>().setIndex(3);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserProfilePage(user: widget.post.author),
        ),
      );
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

  void _handleDoubleTap() {
    context.read<PostProvider>().toggleLike(widget.post.id);
    context.read<ProfileProvider>().toggleLikeLocal(widget.post.id);

    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount--;
      } else {
        _isLiked = true;
        _likesCount++;
        _likeButtonKey.currentState?.animateBurst();
      }
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.isDetailView) return;

    if (details.primaryDelta! < 0 || _dragExtent < 0) {
      setState(() {
        _dragExtent += details.primaryDelta!;
        if (_dragExtent < -120) _dragExtent = -120;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isDetailView) return;

    if (details.primaryVelocity! > 1000) {
      _openCreatePost();
      setState(() {
        _dragExtent = 0.0;
      });
      return;
    }

    if (_dragExtent < -_slideThreshold) {
      _navigateToDetail();
    } else {
      setState(() {
        _dragExtent = 0.0;
      });
    }
  }

  void _showAllTags() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Semua Tag",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.post.tags
                  .map((tag) => _buildTagChip(tag, isDialog: true))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(PostProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Postingan?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deletePost(widget.post.id);
              if (widget.isDetailView) {
                Navigator.pop(context);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Postingan dihapus")),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(
    String label, {
    bool isMore = false,
    bool isDialog = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (isMore) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DiscoverPage(initialQuery: label)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isMore
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMore
                ? colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          isMore ? label : "#$label",
          style: TextStyle(
            color: isMore ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isMore ? FontWeight.bold : FontWeight.w500,
            fontSize: isDialog ? 14 : 12,
          ),
        ),
      ),
    );
  }

  void _showPostMenu() {
    final ReportService reportService = ReportService();
    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();

    final currentUser = authProvider.currentUser;
    final bool isMyPost = widget.post.author.id == currentUser?.id;
    final bool isFollowing = widget.post.author.isFollowing;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text("Bagikan"),
              onTap: () async {
                Navigator.pop(ctx);
                _handleShare();
              },
            ),

            if (isMyPost)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Hapus Postingan",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmDialog(postProvider);
                },
              ),

            if (!isMyPost && isFollowing)
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: Colors.orange,
                ),
                title: Text(
                  "Berhenti mengikuti @${widget.post.author.username}",
                  style: const TextStyle(color: Colors.orange),
                ),
                onTap: () async {
                  Navigator.pop(ctx);

                  await postProvider.toggleFollowFromFeed(
                    widget.post.author.id,
                  );

                  if (mounted) {
                    postProvider.refreshPosts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Berhenti mengikuti @${widget.post.author.username}",
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

            if (!isMyPost)
              ListTile(
                leading: const Icon(
                  Icons.report_gmailerrorred_outlined,
                  color: Colors.red,
                ),
                title: const Text(
                  "Laporkan Postingan",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);

                  final reason = await showReportReasonDialog(context);

                  if (reason != null && reason.isNotEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Mengirim laporan...")),
                      );
                    }

                    final result = await reportService.submitReport(
                      targetType: 'post',
                      targetId: widget.post.id,
                      reason: reason,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: result['success']
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String domain = "https://withamica.my.id";
      final String postLink = "$domain/post/${widget.post.id}";

      final String shareText =
          "${widget.post.caption}\n\n"
          "Lihat selengkapnya di Amica: $postLink";

      await Clipboard.setData(ClipboardData(text: shareText));

      if (widget.post.fullImageUrl != null &&
          widget.post.fullImageUrl!.isNotEmpty) {
        final url = Uri.parse(widget.post.fullImageUrl!);
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final path = '${tempDir.path}/share_image.jpg';
          final file = File(path);
          await file.writeAsBytes(response.bodyBytes);

          if (!context.mounted) return;
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Caption disalin! Tempel saat membagikan."),
              duration: Duration(seconds: 2),
            ),
          );

          final params = ShareParams(
            text: shareText,
            subject: 'Postingan dari Amica',
            files: [XFile(path)],
          );
          await SharePlus.instance.share(params);
        } else {
          if (!context.mounted) return;
          Navigator.pop(context);
          _shareTextOnly(shareText);
        }
      } else {
        if (!context.mounted) return;
        Navigator.pop(context);
        _shareTextOnly(shareText);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membagikan konten")),
        );
      }
    }
  }

  Future<void> _shareTextOnly(String text) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Link disalin! Tempel saat membagikan."),
        duration: Duration(seconds: 2),
      ),
    );

    final params = ShareParams(text: text, subject: 'Postingan dari Amica');
    await SharePlus.instance.share(params);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage =
        widget.post.fullImageUrl != null &&
        widget.post.fullImageUrl!.isNotEmpty;
    final String? avatarUrl = _getAvatarUrl(widget.post.author.avatarUrl);

    return Stack(
      children: [
        if (!widget.isDetailView)
          Positioned.fill(
            child: Container(
              color: colorScheme.surface,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 32.0),
              child: Opacity(
                opacity: (_dragExtent.abs() / _slideThreshold).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale:
                      0.8 +
                      ((_dragExtent.abs() / _slideThreshold) * 0.4).clamp(
                        0.0,
                        0.5,
                      ),
                  child: Icon(
                    Icons.mode_comment_outlined,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 1),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _navigateToProfile,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            child: ClipOval(
                              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      cacheManager:
                                          ProfileCacheManager.instance,
                                      fit: BoxFit.cover,
                                      width: 36,
                                      height: 36,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(
                                            strokeWidth: 1,
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.person,
                                            size: 20,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _navigateToProfile,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.post.author.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.post.author.isVerified) ...[
                                      const SizedBox(width: 4),
                                      Image.asset(
                                        'source/images/verified.png',
                                        width: 14,
                                        height: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _formatTimeAgo(widget.post.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.more_horiz,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: _showPostMenu,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  if (widget.post.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...widget.post.tags
                              .take(2)
                              .map((tag) => _buildTagChip(tag)),
                          if (widget.post.tags.length > 2)
                            InkWell(
                              onTap: _showAllTags,
                              borderRadius: BorderRadius.circular(20),
                              child: _buildTagChip(
                                "+${widget.post.tags.length - 2}",
                                isMore: true,
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (widget.post.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ExpandableCaption(
                        text: widget.post.caption,
                        isExpanded: false,
                        onToggle: () {},
                        stepLimit: 100,
                      ),
                    ),

                  if (hasImage)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: GestureDetector(
                        onDoubleTap: _handleDoubleTap,
                        onTap: () {
                          if (widget.post.fullImageUrl != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _FullScreenImagePage(
                                  imageUrl: widget.post.fullImageUrl!,
                                ),
                              ),
                            );
                          }
                        },
                        child: AdaptiveImageCard(
                          imageUrl: widget.post.fullImageUrl!,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LikeButtonWithBurst(
                          key: _likeButtonKey,
                          isLiked: _isLiked,
                          likesCount: _likesCount,
                          onTap: () {
                            context.read<PostProvider>().toggleLike(
                              widget.post.id,
                            );
                            context.read<ProfileProvider>().toggleLikeLocal(
                              widget.post.id,
                            );

                            setState(() {
                              _isLiked = !_isLiked;
                              _likesCount += _isLiked ? 1 : -1;
                            });
                          },
                        ),
                        const SizedBox(width: 20),

                        if (!widget.isDetailView) ...[
                          InkWell(
                            onTap: _navigateToDetail,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mode_comment_outlined,
                                  size: 24,
                                  color: colorScheme.onSurface,
                                ),
                                if (widget.post.commentsCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.post.commentsCount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],

                        IconButton(
                          onPressed: _handleShare,
                          icon: Icon(
                            Icons.share_rounded,
                            size: 24,
                            color: colorScheme.onSurface,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                        const Spacer(),

                        IconButton(
                          onPressed: () {
                            context.read<PostProvider>().toggleSave(
                              widget.post.id,
                            );
                            context.read<ProfileProvider>().toggleSaveLocal(
                              widget.post.id,
                            );

                            setState(() {
                              _isSaved = !_isSaved;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isSaved
                                      ? "Disimpan ke koleksi"
                                      : "Dihapus dari simpanan",
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: Icon(
                            _isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                            size: 26,
                            color: _isSaved
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LikeButtonWithBurst extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback onTap;

  const _LikeButtonWithBurst({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.onTap,
  });

  @override
  State<_LikeButtonWithBurst> createState() => _LikeButtonWithBurstState();
}

class _LikeButtonWithBurstState extends State<_LikeButtonWithBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HeartParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateBurst() {
    if (_controller.isAnimating) _controller.reset();
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < 5; i++) {
      _particles.add(
        _HeartParticle(
          angle: (random.nextDouble() * 90) - 45,
          speed: random.nextDouble() * 50 + 20,
          scale: random.nextDouble() * 0.5 + 0.5,
        ),
      );
    }
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: () {
        if (!widget.isLiked) animateBurst();
        widget.onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_controller.isAnimating)
            ..._particles.map((p) {
              final double progress = _controller.value;
              final double bottomOffset = 15 + (progress * p.speed);
              final double sideOffset = (progress * p.angle);
              final double opacity = (1.0 - progress).clamp(0.0, 1.0);
              return Positioned(
                bottom: bottomOffset,
                left: sideOffset,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: p.scale,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 14,
                    ),
                  ),
                ),
              );
            }),
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  widget.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(widget.isLiked),
                  size: 26,
                  color: widget.isLiked ? Colors.red : themeColor,
                ),
              ),
              if (widget.likesCount > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '${widget.likesCount}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isLiked ? Colors.red : themeColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeartParticle {
  final double angle;
  final double speed;
  final double scale;
  _HeartParticle({
    required this.angle,
    required this.speed,
    required this.scale,
  });
}

class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) =>
                const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
