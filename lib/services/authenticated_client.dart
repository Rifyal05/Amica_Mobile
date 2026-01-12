import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AuthenticatedClient {
  final AuthService _authService = AuthService();

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    String? token = await _getAccessToken();

    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    var response = await http.get(url, headers: requestHeaders);

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        response = await http.get(url, headers: requestHeaders);
      }
    }

    return response;
  }

  // --- POST ---
  Future<http.Response> post(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    String? token = await _getAccessToken();

    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    var response = await http.post(url, headers: requestHeaders, body: body);

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        response = await http.post(url, headers: requestHeaders, body: body);
      }
    }
    return response;
  }

  // --- PUT ---
  Future<http.Response> put(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    String? token = await _getAccessToken();

    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    var response = await http.put(url, headers: requestHeaders, body: body);

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        response = await http.put(url, headers: requestHeaders, body: body);
      }
    }
    return response;
  }

  Future<http.Response> patch(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    String? token = await _getAccessToken();

    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    var response = await http.patch(url, headers: requestHeaders, body: body);

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        response = await http.patch(url, headers: requestHeaders, body: body);
      }
    }
    return response;
  }

  Future<http.Response> delete(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    String? token = await _getAccessToken();

    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    var response = await http.delete(url, headers: requestHeaders, body: body);

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        response = await http.delete(url, headers: requestHeaders, body: body);
      }
    }
    return response;
  }

  Future<http.StreamedResponse> sendMultipartRequest(
    Future<http.MultipartRequest> Function() requestBuilder,
  ) async {
    String? token = await _getAccessToken();

    var request = await requestBuilder();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    var streamedResponse = await request.send();

    if (streamedResponse.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        var newRequest = await requestBuilder();
        newRequest.headers['Authorization'] = 'Bearer $newToken';
        streamedResponse = await newRequest.send();
      }
    }

    return streamedResponse;
  }
}
