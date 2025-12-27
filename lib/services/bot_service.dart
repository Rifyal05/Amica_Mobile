import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class BotService {
  Future<http.StreamedResponse> streamChat(String message, String history, String token) async {
    final request = http.Request('POST', Uri.parse('${ApiConfig.baseUrl}/api/bot/send')); // <--- PERBAIKAN DI SINI
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      "message": message,
      "history": history
    });

    return await request.send();
  }
}