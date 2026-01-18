import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'authenticated_client.dart';
import 'api_config.dart';

class ChatService {
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<Map<String, dynamic>> getOrCreateChat(String targetUserId) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chats/get-or-create/$targetUserId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'chat_id': data['chat_id']};
      }
      return {
        'success': false,
        'message': data['error'] ?? 'Gagal memulai chat',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<User>> getMutualFriends(String query) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/users/mutual-friends?q=$query'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createGroup(
    String name,
    File? image,
    List<String> memberIds,
    bool allowInvites,
  ) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/api/chats/group/create');
    var request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['allow_invites'] = allowInvites.toString();
    request.fields['members'] = jsonEncode(memberIds);

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamed = await _client.sendMultipartRequest(() async => request);
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body);
  }

  Future<void> leaveGroup(String chatId) async {
    await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/leave'),
    );
  }

  Future<void> clearChat(String chatId) async {
    await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/$chatId/clear'),
    );
  }

  Future<void> deleteMessage(String msgId) async {
    await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/message/$msgId'),
    );
  }

  Future<List<dynamic>> getBannedList(String chatId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/banned'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<void> unbanUser(String chatId, String userId) async {
    await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/unban'),
      body: jsonEncode({'user_id': userId}),
    );
  }

  Future<Map<String, dynamic>> getGroupDetails(String chatId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/details'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal memuat info grup');
  }

  Future<void> updateGroupInfo(
    String chatId,
    String name,
    String? imagePath,
  ) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/update'),
    );
    request.fields['name'] = name;
    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }
    await _client.sendMultipartRequest(() async => request);
  }

  Future<Map<String, dynamic>> addMembers(
    String chatId,
    List<String> userIds,
  ) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/add_members'),
      body: jsonEncode({'user_ids': userIds}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal menambahkan anggota');
  }

  Future<void> kickMember(String chatId, String userId) async {
    await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/kick'),
      body: jsonEncode({'user_id': userId}),
    );
  }

  Future<void> banMember(String chatId, String userId) async {
    await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/ban'),
      body: jsonEncode({'user_id': userId}),
    );
  }

  Future<void> setMemberRole(String chatId, String userId, String role) async {
    await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/set-role'),
      body: jsonEncode({'user_id': userId, 'role': role}),
    );
  }

  Future<String> generateInviteLink(String chatId, String type) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/invite-link'),
      body: jsonEncode({'type': type}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body)['url'];
    throw Exception('Gagal');
  }

  Future<void> updateGroupSettings(String chatId, bool allowInvites) async {
    await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/settings'),
      body: jsonEncode({'allow_member_invites': allowInvites}),
    );
  }

  Future<List<dynamic>> getActiveInvites(String chatId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/invites'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<void> revokeInvite(String token) async {
    await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/invite/$token'),
    );
  }

  Future<Map<String, dynamic>> getInviteInfo(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/invite-info/$token'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Link tidak valid");
  }

  Future<Map<String, dynamic>> getGroupPreview(String chatId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/group/$chatId/preview'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Gagal");
  }

  Future<void> joinGroup(String token) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/join/$token'),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? "Gagal bergabung";
      throw Exception(error);
    }
  }

  Future<bool> deleteConversationPermanently(String chatId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/chats/$chatId'),
    );
    return response.statusCode == 200;
  }

  Future<void> markDeliveredBackground(String msgId) async {
    final url = '${ApiConfig.baseUrl}/api/chats/message/$msgId/delivered';
    try {
      await http.post(
        Uri.parse(url),
      );

    } catch (e) {
    }
  }

}
