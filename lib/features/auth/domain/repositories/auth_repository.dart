import 'package:test_wpa/features/auth/data/models/login_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({
    required String email,
    required String password,
  });
  Future<void> logout();
  // bool get isLoggedIn;

  Future<String?> getToken();
}
