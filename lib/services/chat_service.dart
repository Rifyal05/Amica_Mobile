import 'dart:convert';
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
}
