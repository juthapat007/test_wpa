import 'package:test_wpa/features/auth/data/models/login_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<String?> getToken();
  Future<void> forgotPassword({required String email});
  Future<void> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  });
}
