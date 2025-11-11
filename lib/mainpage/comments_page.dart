import 'package:amica/mainpage/user_profile_page.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import 'package:intl/intl.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _commentController = TextEditingController();
  final List<Comment> _comments = Comment.dummyComments;
  final FocusNode _focusNode = FocusNode();
  Comment? _replyingToComment;

  String formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}d lalu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h lalu';
    } else {
      return DateFormat('d MMM').format(timestamp);
    }
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingToComment = comment;
    });
    _focusNode.requestFocus();
    _commentController.text = '@${comment.user.username} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
    _commentController.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Widget> commentWidgets = [];
    for (var comment in _comments) {
      commentWidgets.add(_CommentTile(
        comment: comment,
        timeAgo: formatTimeAgo(comment.timestamp),
        onTap: () => _startReply(comment),
      ));
      for (var reply in comment.replies) {
        commentWidgets.add(Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: _CommentTile(
            comment: reply,
            timeAgo: formatTimeAgo(reply.timestamp),
            onTap: () => _startReply(reply),
          ),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komentar'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12.0),
              children: commentWidgets,
            ),
          ),
          _buildCommentInput(theme),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToComment != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Membalas kepada ${_replyingToComment!.user.displayName}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: _cancelReply,
                    )
                  ],
                ),
              ),
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: () {
                    _commentController.clear();
                    _cancelReply();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final String timeAgo;
  final VoidCallback onTap;

  const _CommentTile({
    required this.comment,
    required this.timeAgo,
    required this.onTap,
  });

  void _showCommentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Laporkan Komentar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () => _showCommentMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserProfilePage(user: comment.user),
                ));
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(comment.user.avatarUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: '${comment.user.displayName} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: comment.text),
                        ]
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}