import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class ModerationProvider with ChangeNotifier {
  final PostService _service = PostService();
  final PostService _postService = PostService();


  List<Post> _moderatedPosts = [];
  bool _isLoading = false;

  List<Post> get moderatedPosts => _moderatedPosts;
  bool get isLoading => _isLoading;

  Future<void> fetchModeratedPosts() async {
    _isLoading = true;
    notifyListeners();
    _moderatedPosts = await _service.getMyModerationPosts();
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> sendAppeal(String postId, String reason) async {
    final result = await _service.submitAppeal(postId, reason);
    if (result['success']) {
      await fetchModeratedPosts();
    }
    return result;
  }

  Future<bool> acceptDecision(String postId) async {
    final result = await _postService.acknowledgeRejection(postId);

    if (result['success']) {
      _moderatedPosts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    }
    return false;
  }
}