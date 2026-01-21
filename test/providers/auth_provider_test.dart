import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amica/provider/auth_provider.dart';
import 'package:amica/services/auth_service.dart';
import 'package:amica/services/user_service.dart';
import 'package:amica/models/user_model.dart';

@GenerateNiceMocks([MockSpec<AuthService>(), MockSpec<UserService>()])
import 'auth_provider_test.mocks.dart';

void main() {
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;
  late MockUserService mockUserService;

  final dummyUser = User(
    id: '1',
    username: 'clover',
    displayName: 'Clover User',
    email: 'clover@test.com',
    role: 'user',
  );

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('OneSignal'),
          (MethodCall methodCall) async {
        return null;
      },
    );

    mockAuthService = MockAuthService();
    mockUserService = MockUserService();

    authProvider = AuthProvider(
      authService: mockAuthService,
      userService: mockUserService,
    );
  });


  group('AuthProvider Tests', () {
    test('Initial state harus logged out', () {
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.token, null);
    });

    test(
      'attemptLogin Sukses: harus mengubah state menjadi isLoggedIn = true',
      () async {
        when(
          mockAuthService.login('clover@test.com', 'password123'),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'access_token': 'fake_token_abc',
            'refresh_token': 'fake_refresh_xyz',
            'user': dummyUser,
          },
        );

        when(
          mockAuthService.fetchCurrentUser(any),
        ).thenAnswer((_) async => dummyUser);

        final result = await authProvider.attemptLogin(
          'clover@test.com',
          'password123',
        );

        expect(result['success'], true);
        expect(authProvider.isLoggedIn, true);
      },
    );

    test('attemptLogin Gagal: state harus tetap logged out', () async {
      when(mockAuthService.login('wrong@test.com', 'wrongpass')).thenAnswer(
        (_) async => {'success': false, 'message': 'Password salah'},
      );

      final result = await authProvider.attemptLogin(
        'wrong@test.com',
        'wrongpass',
      );

      expect(result['success'], false);
      expect(authProvider.isLoggedIn, false);
    });

    test('performLogout: harus membersihkan data', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'abc'});
      await authProvider.checkAuthStatus();

      await authProvider.performLogout();

      expect(authProvider.isLoggedIn, false);
      expect(authProvider.token, null);
    });
  });
}
