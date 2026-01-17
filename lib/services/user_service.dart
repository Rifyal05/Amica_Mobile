import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'authenticated_client.dart';
import 'api_config.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../models/post_model.dart';

class UserService {
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 0
  Future<UserProfileData?> getUserProfile(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
      );

      if (response.statusCode == 200) {
        return UserProfileData.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> followUser(String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/follow'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    File? avatarFile,
    File? bannerFile,
    String? practiceAddress,
    String? practiceSchedule,
    String? province,
    bool isProfessional = false,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Unauthorized'};

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConfig.baseUrl}/api/users/update'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['display_name'] = displayName;
      request.fields['username'] = username;
      request.fields['bio'] = bio;

      if (avatarFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', avatarFile.path),
        );
      }
      if (bannerFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('banner', bannerFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update profil',
        };
      }

      if (isProfessional) {
        final proResponse = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/pro/update'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'address': practiceAddress,
            'schedule': practiceSchedule,
            'province': province,
          }),
        );

        if (proResponse.statusCode != 200) {
          final proData = jsonDecode(proResponse.body);
          return {
            'success': true,
            'message':
                'Profil umum diperbarui, namun info profesional gagal: ${proData['error']}',
          };
        }
      }

      return {'success': true, 'message': 'Profil berhasil diperbarui'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> applyVerification({
    required String fullName,
    required String strNumber,
    required String province,
    required String address,
    required String schedule,
    required File strImage,
    required File ktpImage,
    required File selfieImage,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Unauthorized'};

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/pro/apply'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['full_name'] = fullName;
      request.fields['str_number'] = strNumber;
      request.fields['province'] = province;
      request.fields['address'] = address;
      request.fields['schedule'] = schedule;

      request.files.add(
        await http.MultipartFile.fromPath('str_image', strImage.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('ktp_image', ktpImage.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('selfie_image', selfieImage.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Permohonan berhasil dikirim'};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengirim data',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 1
  Future<Map<String, dynamic>> getSavedPosts(String targetUserId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$targetUserId/saved-posts'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Post> posts = (data['posts'] as List)
            .map((json) => Post.fromJson(json))
            .toList();
        return {'success': true, 'posts': posts};
      } else if (response.statusCode == 403) {
        return {'success': false, 'is_private': true};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 2
  Future<bool> updateSavedPrivacy(bool isPublic) async {
    try {
      final response = await _client.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/users/settings/privacy/saved-posts',
        ),
        body: jsonEncode({'is_public': isPublic}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateDeviceId(String playerId) async {
    try {
      await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/device-id'),
        body: jsonEncode({'player_id': playerId}),
      );
    } catch (e) {}
  }

  Future<String?> changePassword(String oldPass, String newPass) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/change-password'),
        body: jsonEncode({'old_password': oldPass, 'new_password': newPass}),
      );
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      return data['error'] ?? 'Gagal mengganti password';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> changeEmail(String newEmail, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/change-email'),
        body: jsonEncode({'new_email': newEmail, 'password': password}),
      );
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      return data['error'] ?? 'Gagal mengganti email';
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<User>> getBlockedUsers() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/blocked_list'),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => User.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> unblockUser(String targetId) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/unblock/$targetId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> blockUser(String targetId) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/block/$targetId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendFeedback(String text) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/feedback/'),
        body: jsonEncode({'feedback_text': text}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3
  Future<Map<String, dynamic>> getFollowers(
    String userId,
    int page,
    String query,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/users/$userId/followers?page=$page&q=$query',
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat pengikut');
  }

  // 4
  Future<Map<String, dynamic>> getFollowing(
    String userId,
    int page,
    String query,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/users/$userId/following?page=$page&q=$query',
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat mengikuti');
  }
}
