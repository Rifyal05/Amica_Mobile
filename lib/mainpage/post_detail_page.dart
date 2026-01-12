import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_config.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../provider/auth_provider.dart';
import '../provider/comment_provider.dart';
import '../provider/post_provider.dart';
import '../services/report_serices.dart';
import 'helper/utils_helper.dart';
import 'widgets/post_card.dart';
import 'user_profile_page.dart';
import 'widgets/verified_badge.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Comment? _replyingToComment;
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<CommentProvider>().loadComments(widget.post.id);
  }

  void _startReply(Comment comment) {
    setState(() => _replyingToComment = comment);
    _focusNode.requestFocus();
    _commentController.text = "@${comment.user.username} ";
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  void _cancelReply() {
    setState(() => _replyingToComment = null);
    _commentController.clear();
    _focusNode.unfocus();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    setState(() => _isSending = true);
    _focusNode.unfocus();

    String? finalParentId = _replyingToComment?.id;

    final result = await context.read<CommentProvider>().createComment(
      widget.post.id,
      text,
      parentId: finalParentId,
    );

    setState(() => _isSending = false);

    if (result['success']) {
      if (mounted) {
        context.read<PostProvider>().incrementCommentCount(widget.post.id);
      }

      if (finalParentId == null) {
        await _onRefresh();
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      } else {
        final String newCommentId =
            result['comment_id'] ?? DateTime.now().toString();

        final newLocalComment = Comment(
          id: newCommentId,
          user: currentUser,
          text: text,
          timestamp: DateTime.now(),
          parentId: finalParentId,
          replies: [],
        );

        context.read<CommentProvider>().addLocalComment(
          newLocalComment,
          finalParentId,
        );

        await context.read<CommentProvider>().loadComments(widget.post.id);
      }

      _commentController.clear();
      _cancelReply();
    } else if (result['status'] == 'rejected') {
      _showModerationDialog(result['reason']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Gagal"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showModerationDialog(String? reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gagal', style: TextStyle(color: Colors.red)),
        content: Text('Komentar ditolak: ${reason ?? "Melanggar aturan."}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentProvider = context.watch<CommentProvider>();
    final livePost = context.select<PostProvider, Post>(
      (p) => p.posts.firstWhere(
        (element) => element.id == widget.post.id,
        orElse: () => widget.post,
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text("Postingan"), scrolledUnderElevation: 0),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: PostCard(post: livePost, isDetailView: true),
                  ),
                  SliverToBoxAdapter(
                    child: Divider(
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Text(
                        "Komentar",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (commentProvider.isLoading &&
                      commentProvider.comments.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (commentProvider.comments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            "Belum ada komentar.",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final comment = commentProvider.comments[index];
                        return _CommentTree(
                          comment: comment,
                          onReply: _startReply,
                          postId: widget.post.id,
                        );
                      }, childCount: commentProvider.comments.length),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyingToComment != null)
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.turn_right,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Membalas ${_replyingToComment!.user.displayName}",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _cancelReply,
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      enabled: !_isSending,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _replyingToComment != null
                            ? "Tulis balasan..."
                            : "Tulis komentar...",
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _sendComment,
                          icon: Icon(
                            Icons.send_rounded,
                            color: theme.colorScheme.primary,
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

class _ReplyContextOverlay extends StatelessWidget {
  final Comment comment;
  final VoidCallback onClose;

  const _ReplyContextOverlay({required this.comment, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Membalas ${comment.user.displayName}",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Text(
                      comment.text,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTree extends StatefulWidget {
  final Comment comment;
  final Function(Comment) onReply;
  final String postId;

  const _CommentTree({
    required this.comment,
    required this.onReply,
    required this.postId,
  });

  @override
  State<_CommentTree> createState() => _CommentTreeState();
}

class _CommentTreeState extends State<_CommentTree> {
  int _visibleRepliesCount = 1;
  static const int _batchSize = 10;

  List<Comment> _getAllDescendants(Comment parent) {
    List<Comment> all = [];
    parent.replies.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var child in parent.replies) {
      all.add(child);
      all.addAll(_getAllDescendants(child));
    }
    return all;
  }

  void _loadMoreReplies() {
    setState(() {
      _visibleRepliesCount += _batchSize;
    });
  }

  void _hideReplies() {
    setState(() {
      _visibleRepliesCount = 1;
    });
  }

  void _navigateToProfile(User user) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UserProfilePage(user: user)));
  }

  void _showCommentMenu(Comment comment, User? currentUser) {
    final ReportService reportService = ReportService();
    bool isMyComment = currentUser?.id == comment.user.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Lihat Profil"),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToProfile(comment.user);
              },
            ),
            if (isMyComment)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Hapus Komentar",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final postProvider = context.read<PostProvider>();
                  final commentProvider = context.read<CommentProvider>();

                  final success = await commentProvider.deleteComment(
                    comment.id,
                    widget.postId,
                  );

                  if (mounted) {
                    if (success) {
                      postProvider.decrementCommentCount(widget.postId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Komentar berhasil dihapus"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Gagal menghapus komentar"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            if (!isMyComment)
              ListTile(
                leading: const Icon(
                  Icons.report_gmailerrorred_outlined,
                  color: Colors.red,
                ),
                title: const Text(
                  "Laporkan Komentar",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);

                  final reason = await showReportReasonDialog(context);

                  if (reason != null && reason.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mengirim laporan...")),
                    );

                    final result = await reportService.submitReport(
                      targetType: 'comment',
                      targetId: comment.id,
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

  void _showContext(Comment comment) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return _ReplyContextOverlay(
          comment: comment,
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Comment? _findCommentById(String targetId, List<Comment> comments) {
    for (var comment in comments) {
      if (comment.id == targetId) {
        return comment;
      }
      Comment? found = _findCommentById(targetId, comment.replies);
      if (found != null) return found;
    }
    return null;
  }

  String? _getAvatarUrl(String? url) {
    return ApiConfig.getFullUrl(url);
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inSeconds < 60) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}j';
    if (difference.inDays < 7) return '${difference.inDays}h';
    return DateFormat('d MMM yy').format(timestamp);
  }

  Widget _buildCommentTile(
    Comment comment,
    ThemeData theme, {
    bool isReply = false,
  }) {
    final avatarUrl = _getAvatarUrl(comment.user.avatarUrl);
    final currentUser = context.read<AuthProvider>().currentUser;

    String commentText = comment.text.trim();
    Comment? contextComment;

    if (isReply && comment.parentId != null) {
      List<Comment> rootList = context.read<CommentProvider>().comments;
      contextComment = _findCommentById(comment.parentId!, rootList);

      if (contextComment != null && comment.text.startsWith('@')) {
        int spaceIndex = comment.text.indexOf(' ');
        if (spaceIndex != -1) {
          commentText = comment.text.substring(spaceIndex + 1).trim();
        }
      }
    }

    return GestureDetector(
      onLongPress: () => _showCommentMenu(comment, currentUser),
      child: InkWell(
        onTap: () => widget.onReply(comment),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(comment.user),
                child: CircleAvatar(
                  radius: isReply ? 14 : 18,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: isReply ? 16 : 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToProfile(comment.user),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  comment.user.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (comment.user.isVerified)
                                const VerifiedBadge(size: 14),
                            ],
                          ),
                        ),
                        Text(
                          _formatTimeAgo(comment.timestamp),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (contextComment != null)
                      GestureDetector(
                        onTap: () => _showContext(contextComment!),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Membalas ${contextComment.user.displayName}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (contextComment.user.isVerified)
                                const VerifiedBadge(size: 12),
                            ],
                          ),
                        ),
                      ),
                    Text(
                      commentText,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => widget.onReply(comment),
                      child: Text(
                        "Balas",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allReplies = _getAllDescendants(widget.comment);
    final totalReplies = allReplies.length;

    final shownReplies = allReplies.take(_visibleRepliesCount).toList();
    final remainingCount = totalReplies - shownReplies.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentTile(widget.comment, theme),
        if (totalReplies > 0) ...[
          ...shownReplies.map(
            (reply) => Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: _buildCommentTile(reply, theme, isReply: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60.0, bottom: 8.0, top: 4.0),
            child: Row(
              children: [
                if (remainingCount > 0) ...[
                  Container(
                    width: 20,
                    height: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _loadMoreReplies,
                    child: Text(
                      "Lihat $remainingCount balasan lainnya",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (_visibleRepliesCount > 1) ...[
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: _hideReplies,
                    child: Text(
                      "Sembunyikan",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        Divider(
          height: 1,
          indent: 64,
          color: theme.colorScheme.outlineVariant.withOpacity(0.1),
        ),
      ],
    );
  }
}
