import 'dart:convert';
import '../models/article_model.dart';
import '../services/api_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'authenticated_client.dart';

class DiscoverService {
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<Map<String, dynamic>> getDiscoverDashboard() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/discover/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<User> mapUsers(List list) =>
            list.map((e) => User.fromJson(e)).toList();

        return {
          'success': true,
          'tags': List<String>.from(data['tags']),
          'users': mapUsers(data['users']),
          'articles': data['articles'],
        };
      }
      return {'success': false, 'message': 'Gagal memuat data'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/discover/search?q=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'users': (data['users'] as List)
              .map((e) => User.fromJson(e))
              .toList(),
          'posts': (data['posts'] as List)
              .map((e) => Post.fromJson(e))
              .toList(),
          'articles': data['articles'],
        };
      }
      return {'success': false, 'message': 'Pencarian gagal'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<User>> getUserList({
    String type = 'popular',
    int page = 1,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/discover/users/list?type=$type&page=$page',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['users'] as List).map((e) => User.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Post>> getPostList({String type = 'all', int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/discover/posts/list?type=$type&page=$page',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['posts'] as List).map((e) => Post.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Article>> getArticleList({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/discover/articles/list?page=$page'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['articles'] as List)
            .map((e) => Article.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Article?> getArticleDetail(int id) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/discover/articles/$id'),
      );
      if (response.statusCode == 200) {
        return Article.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Article?> findArticleByUrl(String url) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/discover/articles/lookup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['found'] == true) {
          return Article.fromJson(data['article']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }


}
