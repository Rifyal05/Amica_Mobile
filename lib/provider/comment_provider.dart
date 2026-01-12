import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

class CommentProvider with ChangeNotifier {
  final CommentService _service = CommentService();
  List<Comment> _comments = [];
  bool _isLoading = false;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;

  Future<void> loadComments(String postId) async {
    if (_comments.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final List<Comment> result = await _service.getComments(postId);
      _comments = result;
    } catch (e) {
      debugPrint("Error loading comments: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void addLocalComment(Comment newComment, String? parentId) {
    if (parentId == null) {
      _comments.insert(0, newComment);
    } else {
      bool found = _findRootAndAppendReply(_comments, parentId, newComment);
      if (!found) {
      }
    }
    notifyListeners();
  }

  bool _findRootAndAppendReply(
    List<Comment> list,
    String targetId,
    Comment newReply,
  ) {
    for (var comment in list) {
      if (comment.id == targetId) {
        comment.replies.add(newReply);
        return true;
      }

      bool isTargetChild = comment.replies.any((r) => r.id == targetId);
      if (isTargetChild) {
        comment.replies.add(newReply);
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>> createComment(
    String postId,
    String text, {
    String? parentId,
  }) async {
    return await _service.createComment(postId, text, parentId: parentId);
  }

  Future<bool> deleteComment(String commentId, String postId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _service.deleteComment(commentId);
      if (success) {
        _comments.removeWhere((c) => c.id == commentId);
        for (var rootComment in _comments) {
          rootComment.replies.removeWhere((r) => r.id == commentId);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting comment: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
