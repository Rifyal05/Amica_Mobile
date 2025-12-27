import 'dart:convert';
import '../services/authenticated_client.dart';
import '../services/api_config.dart';
import '../models/sdq_model.dart';

class SdqService {
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<SdqFullResult> submitAnswers(List<int> answers) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/sdq/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'answers': answers}),
    );

    if (response.statusCode == 200) {
      return SdqFullResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal mengirim jawaban SDQ');
    }
  }

  Future<List<SdqHistoryItem>> getHistory() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/sdq/history'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SdqHistoryItem.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat riwayat');
    }
  }

  Future<SdqFullResult> getResultDetail(int id) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/sdq/results/$id'),
    );

    if (response.statusCode == 200) {
      return SdqFullResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat detail hasil');
    }
  }
}
