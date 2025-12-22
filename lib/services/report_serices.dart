import 'dart:convert';
import '../services/api_config.dart';
import 'authenticated_client.dart';

class ReportService {
  final AuthenticatedClient _client = AuthenticatedClient();
  final String _reportUrl = '${ApiConfig.baseUrl}/api/report';

  Future<Map<String, dynamic>> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(_reportUrl),
        body: jsonEncode({
          'target_type': targetType,
          'target_id': targetId,
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengirim laporan.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
