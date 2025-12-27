import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import '../services/api_config.dart';

class AuthService {
  final String baseUrl = '${ApiConfig.baseUrl}/api/auth';
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  static Stream<void> get sessionExpiredStream =>
      _sessionExpiredController.stream;

  Future<Map<String, dynamic>> register(
    String username,
    String displayName,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'display_name': displayName,
          'email': email,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mendaftar.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 'pin_required') {
          return {
            'success': false,
            'status': 'pin_required',
            'temp_id': data['temp_id'],
            'email': email,
            'message': 'PIN Keamanan diperlukan',
          };
        }
        User user = User.fromJson(data['user']);
        return {
          'success': true,
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'user': user,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': data['error'],
          'status': 'suspended',
        };
      } else {
        return {'success': false, 'message': data['error'] ?? 'Login gagal.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final String? serverClientId = dotenv.env['SERVER_CLIENT_ID'];
      if (serverClientId == null) {
        return {
          'success': false,
          'message': 'Konfigurasi SERVER_CLIENT_ID tidak ditemukan',
        };
      }

      await _googleSignIn.initialize(serverClientId: serverClientId);
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
            accessToken: authorization?.accessToken,
            idToken: googleAuth.idToken,
          );

      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        return {
          'success': false,
          'message': 'Gagal mendapatkan token autentikasi',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user-google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 'pin_required') {
          return {
            'success': false,
            'status': 'pin_required',
            'temp_id': data['temp_id'],
            'email': data['email'],
            'needs_password_set': data['needs_password_set'] ?? false,
            'message': 'PIN Keamanan diperlukan',
          };
        }
        User user = User.fromJson(data['user']);
        return {
          'success': true,
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'user': user,
          'needs_password_set': data['needs_password_set'] ?? false,
        };
      } else {
        await _googleSignIn.signOut();
        await _firebaseAuth.signOut();
        return {
          'success': false,
          'message': data['error'] ?? 'Login Google ditolak server.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal Login Google: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyPin(String tempId, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'temp_id': tempId, 'pin': pin}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        User user = User.fromJson(data['user']);
        return {
          'success': true,
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'user': user,
          'message': data['message'],
        };
      } else {
        return {'success': false, 'message': data['error'] ?? 'PIN Salah'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> setPin(String pin, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/set-pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'pin': pin}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['error'] ?? 'Gagal mengatur PIN',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> removePin(
    String currentPin,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/remove-pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'current_pin': currentPin}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['error'] ?? 'Gagal menghapus PIN',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPinByOtp(
    String email,
    String otp,
    String? newPin,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-pin-by-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'new_pin': newPin}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['error'] ?? 'Gagal reset PIN'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) {
      _sessionExpiredController.add(null);
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        await prefs.setString('auth_token', newAccessToken);
        return newAccessToken;
      } else {
        await logout();
        _sessionExpiredController.add(null);
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  Future<User?> fetchCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> setPassword(
    String password,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/set-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['error'] ?? 'Gagal mengatur password',
      };
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/password/forgot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengirim kode',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': code}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': data['error'] ?? 'Kode salah'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordFinish(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': code,
          'new_password': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['error'] ?? 'Gagal reset password',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
