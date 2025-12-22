import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AuthenticatedClient {
  final AuthService _authService = AuthService();

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<http.Response> get(Uri url) async {
    String? token = await _getAccessToken();

    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
      }
    }

    return response;
  }

  Future<http.Response> post(Uri url, {Object? body}) async {
    String? token = await _getAccessToken();

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: body,
        );
      }
    }
    return response;
  }

  Future<http.Response> put(Uri url, {Object? body}) async {
    String? token = await _getAccessToken();

    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: body,
        );
      }
    }
    return response;
  }

  Future<http.Response> patch(Uri url, {Object? body}) async {
    String? token = await _getAccessToken();

    var response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        response = await http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: body,
        );
      }
    }
    return response;
  }

  Future<http.Response> delete(Uri url, {Object? body}) async {
    String? token = await _getAccessToken();

    var response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 401) {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        response = await http.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: body,
        );
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
