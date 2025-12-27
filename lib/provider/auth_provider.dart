import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoggedIn = false;
  User? _currentUser;
  String? _token;
  bool _needsPasswordSet = false;

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get needsPasswordSet => _needsPasswordSet;

  AuthProvider() {
    AuthService.sessionExpiredStream.listen((_) {
      performLogout();
    });
  }

  Future<String?> getFreshToken() async {
    final newToken = await _authService.refreshToken();
    if (newToken != null) {
      _token = newToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', newToken);
      notifyListeners();
      return newToken;
    }
    return _token;
  }

  Future<void> _syncOneSignalId() async {
    try {
      String? osUserID = OneSignal.User.pushSubscription.id;
      if (osUserID != null) {
        await _userService.updateDeviceId(osUserID);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userDataString = prefs.getString('user_data');
    final needsPass = prefs.getBool('needs_password_set') ?? false;

    if (token != null) {
      _token = token;
      _isLoggedIn = true;
      _needsPasswordSet = needsPass;

      if (userDataString != null) {
        _currentUser = User.fromJson(jsonDecode(userDataString));
      }
      notifyListeners();

      await refreshCurrentUser();
      await _syncOneSignalId();
    } else {
      _isLoggedIn = false;
      _needsPasswordSet = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentUser() async {
    if (_token == null) return;

    final updatedUser = await _authService.fetchCurrentUser(_token!);
    if (updatedUser != null) {
      _currentUser = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    }
  }

  Future<String?> register(
    String username,
    String displayName,
    String email,
    String password,
  ) async {
    final result = await _authService.register(
      username,
      displayName,
      email,
      password,
    );
    if (result['success']) {
      return null;
    } else {
      return result['message'];
    }
  }

  Future<Map<String, dynamic>> attemptLogin(
    String email,
    String password,
  ) async {
    final result = await _authService.login(email, password);

    if (result['success'] == true) {
      _token = result['access_token'];
      String refreshToken = result['refresh_token'];
      _currentUser = result['user'];
      _isLoggedIn = true;
      _needsPasswordSet = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('needs_password_set', false);

      notifyListeners();
      await _syncOneSignalId();

      return {'success': true};
    } else {
      return {
        'success': false,
        'message': result['message'],
        'status': result['status'],
        'temp_id': result['temp_id'],
        'email': email,
      };
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    final result = await _authService.loginWithGoogle();

    if (result['success'] == true) {
      _token = result['access_token'];
      String refreshToken = result['refresh_token'];
      _currentUser = result['user'];
      _isLoggedIn = true;
      _needsPasswordSet = result['needs_password_set'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('needs_password_set', _needsPasswordSet);

      notifyListeners();
      await _syncOneSignalId();

      return {'success': true};
    } else {
      return {
        'success': false,
        'message': result['message'],
        'status': result['status'],
        'temp_id': result['temp_id'],
        'email': result['email'],
        'needs_password_set': result['needs_password_set'],
      };
    }
  }

  Future<String?> verifyPinLogin(String tempId, String pin) async {
    final result = await _authService.verifyPin(tempId, pin);
    if (result['success'] == true) {
      _token = result['access_token'];
      String refreshToken = result['refresh_token'];
      _currentUser = result['user'];
      _isLoggedIn = true;
      _needsPasswordSet = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('needs_password_set', false);

      notifyListeners();
      await _syncOneSignalId();
      return null;
    }
    return result['message'];
  }

  Future<String?> setPin(String pin) async {
    if (_token == null) return "Token tidak valid";
    final result = await _authService.setPin(pin, _token!);
    if (result['success']) {
      await refreshCurrentUser();
      return null;
    }
    return result['message'];
  }

  Future<String?> removePin(String currentPin) async {
    if (_token == null) return "Token tidak valid";
    final result = await _authService.removePin(currentPin, _token!);
    if (result['success']) {
      await refreshCurrentUser();
      return null;
    }
    return result['message'];
  }

  Future<String?> resetPinByOtp(
    String email,
    String otp,
    String? newPin,
  ) async {
    final result = await _authService.resetPinByOtp(email, otp, newPin);
    if (result['success']) return null;
    return result['message'];
  }

  Future<String?> setPassword(String password) async {
    if (_token == null) return "Token tidak valid";
    final result = await _authService.setPassword(password, _token!);

    if (result['success']) {
      await completePasswordSetup();
      return null;
    } else {
      return result['message'];
    }
  }

  Future<void> completePasswordSetup() async {
    _needsPasswordSet = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('needs_password_set', false);
    notifyListeners();
  }

  Future<String?> sendResetCode(String email) async {
    final result = await _authService.sendPasswordResetCode(email);
    if (result['success']) return null;
    return result['message'];
  }

  Future<String?> verifyResetCode(String email, String code) async {
    final result = await _authService.verifyResetCode(email, code);
    if (result['success']) return null;
    return result['message'];
  }

  Future<String?> resetPasswordFinish(
    String email,
    String code,
    String newPassword,
  ) async {
    final result = await _authService.resetPasswordFinish(
      email,
      code,
      newPassword,
    );
    if (result['success']) return null;
    return result['message'];
  }

  Future<void> performLogout() async {
    OneSignal.logout();
    await _authService.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _currentUser = null;
    _token = null;
    _needsPasswordSet = false;

    notifyListeners();
  }
}
