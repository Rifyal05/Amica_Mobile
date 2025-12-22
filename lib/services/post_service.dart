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

      if (userId != null) {
        url += '&user_id=$userId';
      }

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
        var uri = Uri.parse('${ApiConfig.baseUrl}/api/posts/');
        var request = http.MultipartRequest('POST', uri);

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

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Postingan berhasil dibuat'};
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'is_moderated': true,
          'message': data['error'] ?? 'Konten ditolak moderasi.',
          'reason': data['reason'] ?? 'Konten melanggar aturan komunitas.',
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
}
