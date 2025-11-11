import 'package:amica/mainpage/comments_page.dart';
import 'package:amica/mainpage/connect.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

class PostDetailPage extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;

  const PostDetailPage({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Postingan ${_currentIndex + 1} dari ${widget.posts.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.posts.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final post = widget.posts[index];
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: PostCard(post: post),
                ),
                const Divider(),
                _buildCommentPreviewSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentPreviewSection(BuildContext context) {
    final comments = Comment.dummyComments;
    final commentsToShow = comments.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komentar Teratas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...commentsToShow.map((comment) => _CommentPreviewTile(comment: comment)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CommentsPage(),
              ));
            },
            child: const Text('Lihat semua komentar...'),
          )
        ],
      ),
    );
  }
}

class _CommentPreviewTile extends StatelessWidget {
  final Comment comment;
  const _CommentPreviewTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment.user.avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${comment.user.displayName} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: comment.text),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}