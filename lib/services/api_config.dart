import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? "http://192.168.1.12:5000";

  static String? getFullUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http')) return url;

    String cleanPath = url.startsWith('/') ? url.substring(1) : url;

    if (!cleanPath.contains('static/uploads/')) {
      cleanPath = "static/uploads/$cleanPath";
    }

    return "$baseUrl/$cleanPath";
  }
}
