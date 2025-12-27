class ApiConfig {
  static const String baseUrl = "http://192.168.1.10:5000"; // emulator = http://10.0.2.2:5000 or "http://192.168.1.10:5000";

  static String? getFullUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;

    final cleanUrl = url.replaceAll(RegExp(r'^/'), '');
    return "$baseUrl/$cleanUrl";
  }
}