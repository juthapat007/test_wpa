import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/features/auth/data/models/login_response.dart';
import 'package:test_wpa/features/auth/data/services/auth_api.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi authApi;
  AuthRepositoryImpl(this.authApi);

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await authApi.login(email, password);

      final loginResponse = LoginResponse.fromJson(response.data);

      final storage = Modular.get<FlutterSecureStorage>();
      await storage.write(key: 'auth_token', value: loginResponse.accessToken);

      if (loginResponse.user != null) {
        final userData = {
          'id': loginResponse.user!.id,
          'name': loginResponse.user!.name,
          'email': loginResponse.user!.email,
          'avatar_url': loginResponse.user!.avatarUrl,
        };
        await storage.write(key: 'user_data', value: jsonEncode(userData));
        await storage.write(
          key: 'delegate_id',
          value: loginResponse.user!.id.toString(),
        );
      }

      return loginResponse;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    final storage = Modular.get<FlutterSecureStorage>();
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user_data');
    await storage.delete(key: 'delegate_id');
  }

  @override
  Future<String?> getToken() async {
    final storage = Modular.get<FlutterSecureStorage>();
    return await storage.read(key: 'auth_token');
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await authApi.forgotPassword(email);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await authApi.resetPassword(
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await authApi.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      // ดึง error message จาก API response ถ้ามี
      throw Exception('Failed to change password: $e');
    }
  }
}