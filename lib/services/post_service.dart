import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../models/post_model.dart';
import 'authenticated_client.dart';

class PostService {
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int perPage = 10,
    String? userId,
    String filter = 'latest',
  }) async {
    try {
      String url =
          '${ApiConfig.baseUrl}/api/posts/?page=$page&per_page=$perPage&filter=$filter';
      if (userId != null) url += '&user_id=$userId';
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> postsJson = data['posts'];
        return {
          'success': true,
          'posts': postsJson.map((json) => Post.fromJson(json)).toList(),
          'has_next': data['pagination']['has_next'],
        };
      } else {
        return {'success': false, 'message': 'Gagal memuat postingan'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/detail/$postId'),
      );
      if (response.statusCode == 200) {
        return Post.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> likePost(String postId) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/$postId/like'),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleSave(String postId) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/$postId/save'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String caption,
    required List<String> tags,
    File? imageFile,
  }) async {
    try {
      final streamedResponse = await _client.sendMultipartRequest(() async {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/posts/'),
        );
        request.fields['caption'] = caption;
        for (var tag in tags) {
          request.files.add(http.MultipartFile.fromString('tags', tag));
        }
        if (imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );
        }
        return request;
      });
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        Post? fullPost;
        if (data['post_id'] != null) {
          fullPost = await getPostById(data['post_id']);
        }
        return {
          'success': response.statusCode == 201,
          'is_moderated': data['status'] == 'rejected',
          'message': data['message'],
          'moderation_details': data['moderation_details'],
          'post': fullPost,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'is_moderated': true,
          'message': data['error'] ?? 'Konten ditolak moderasi.',
          'moderation_details': data['moderation_details'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat postingan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/$postId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Post>> getMyModerationPosts() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/my-moderation'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitAppeal(
    String postId,
    String justification,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/$postId/appeal'),
        body: jsonEncode({'justification': justification}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['message'] ?? data['error'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> acknowledgeRejection(String postId) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/$postId/acknowledge'),
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }
}
