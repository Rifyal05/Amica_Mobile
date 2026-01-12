import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_config.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/authenticated_client.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();
  final AuthenticatedClient _authClient = AuthenticatedClient();

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  String _currentFilter = 'latest';

  bool _isUploading = false;
  Map<String, dynamic>? _moderationError;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get isUploading => _isUploading;
  Map<String, dynamic>? get moderationError => _moderationError;
  String get currentFilter => _currentFilter;

  Future<void> setFilter(String filter) async {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _currentPage = 1;
    _posts = [];
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
    await fetchPosts();
  }

  void clearModerationError() {
    _moderationError = null;
  }

  Future<void> refreshPosts() async {
    _currentPage = 1;
    _hasMore = true;
    _posts.clear();
    await fetchPosts();
  }

  Future<void> fetchPosts() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    if (_posts.isEmpty) notifyListeners();
    final result = await _postService.getPosts(
      page: _currentPage,
      perPage: 10,
      filter: _currentFilter,
    );
    _isLoading = false;
    if (result['success']) {
      final newPosts = result['posts'] as List<Post>;
      if (_currentPage == 1) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }
      _hasMore = result['has_next'];
      if (_hasMore) _currentPage++;
      _errorMessage = null;
    } else {
      _errorMessage = result['message'];
    }
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    Post? oldPost;
    if (index != -1) {
      oldPost = _posts[index];
      final newIsLiked = !oldPost.isLiked;
      final newLikesCount = newIsLiked
          ? oldPost.likesCount + 1
          : (oldPost.likesCount > 0 ? oldPost.likesCount - 1 : 0);
      _posts[index] = oldPost.copyWith(
        isLiked: newIsLiked,
        likesCount: newLikesCount,
      );
      notifyListeners();
    }
    final success = await _postService.likePost(postId);
    if (!success && index != -1 && oldPost != null) {
      _posts[index] = oldPost;
      notifyListeners();
    }
  }

  Future<void> toggleSave(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    Post? oldPost;
    if (index != -1) {
      oldPost = _posts[index];
      _posts[index] = oldPost.copyWith(isSaved: !oldPost.isSaved);
      notifyListeners();
    }
    final success = await _postService.toggleSave(postId);
    if (!success && index != -1 && oldPost != null) {
      _posts[index] = oldPost;
      notifyListeners();
    }
  }

  void incrementCommentCount(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final oldPost = _posts[index];
      _posts[index] = Post(
        id: oldPost.id,
        author: oldPost.author,
        caption: oldPost.caption,
        imageUrl: oldPost.imageUrl,
        timestamp: oldPost.timestamp,
        likesCount: oldPost.likesCount,
        commentsCount: oldPost.commentsCount + 1,
        tags: oldPost.tags,
        isLiked: oldPost.isLiked,
        isSaved: oldPost.isSaved,
      );
      notifyListeners();
    }
  }

  void decrementCommentCount(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final oldPost = _posts[index];
      _posts[index] = oldPost.copyWith(
        commentsCount: (oldPost.commentsCount > 0)
            ? oldPost.commentsCount - 1
            : 0,
      );
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String caption,
    required List<String> tags,
    File? imageFile,
  }) async {
    _isUploading = true;
    _moderationError = null;
    notifyListeners();
    final result = await _postService.createPost(
      caption: caption,
      tags: tags,
      imageFile: imageFile,
    );
    _isUploading = false;
    if (result['success'] == true) {
      await refreshPosts();
    } else if (result['is_moderated'] == true) {
      _moderationError = result;
    }
    notifyListeners();
    return result;
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
    final success = await _postService.deletePost(postId);
    if (!success) {
      await fetchPosts();
    }
  }

  final UserService _userService = UserService();

  Future<void> toggleFollowFromFeed(String targetUserId) async {
    await _userService.followUser(targetUserId);
    await refreshPosts();
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final cleanId = postId.trim();
      try {
        final existingPost = _posts.firstWhere((p) => p.id == cleanId);
        return existingPost;
      } catch (_) {
      }


      final url = Uri.parse('${ApiConfig.baseUrl}/api/posts/detail/$cleanId');
      final response = await _authClient.get(url);

      if (response.statusCode == 200) {
        return Post.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
