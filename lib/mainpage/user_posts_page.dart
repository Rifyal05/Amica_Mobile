import 'package:amica/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'widgets/post_card.dart';
import 'create_post_page.dart';

class UserPostsFeedPage extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;
  final String username;

  const UserPostsFeedPage({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.username,
    required ProfileProvider profileProvider,
  });

  @override
  State<UserPostsFeedPage> createState() => _UserPostsFeedPageState();
}

class _UserPostsFeedPageState extends State<UserPostsFeedPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && widget.initialIndex > 0) {
        double estimatedOffset = widget.initialIndex * 500.0;
        _scrollController.jumpTo(estimatedOffset);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              "Postingan",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
            Text(
              widget.username,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            _openCreatePost();
          }
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.posts.length,
          itemBuilder: (context, index) {
            final post = widget.posts[index];
            return PostCard(
              key: ValueKey(post.id),
              post: post,
              isDetailView: false,
            );
          },
        ),
      ),
    );
  }
}
