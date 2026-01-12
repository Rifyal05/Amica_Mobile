import 'dart:convert';
import '../services/api_config.dart';
import '../models/comment_model.dart';
import 'authenticated_client.dart';

class CommentService {
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/comments/$postId/comments'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createComment(
    String postId,
    String text, {
    String? parentId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/comments/$postId/comments'),
        body: jsonEncode({'text': text, 'parent_comment_id': parentId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'status': 'approved',
          'message': 'Komentar berhasil dikirim.',
          'comment_id': data['comment_id'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'status': 'rejected',
          'message': data['message'] ?? 'Komentar melanggar aturan.',
          'reason': data['reason'],
        };
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': data['error'] ?? 'Gagal mengirim komentar.',
        };
      }
    } catch (e) {
      return {'success': false, 'status': 'error', 'message': e.toString()};
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/comments/$commentId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
