class ApiConfig {
  static const String baseUrl = "https://withamica.my.id";

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