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

      // เก็บ token ใน secure storage
      final storage = Modular.get<FlutterSecureStorage>();
      await storage.write(key: 'auth_token', value: loginResponse.accessToken);

      //  เก็บ delegate/user data ไว้ด้วย
      if (loginResponse.user != null) {
        final userData = {
          'id': loginResponse.user!.id,
          'name': loginResponse.user!.name,
          'email': loginResponse.user!.email,
          'avatar_url': loginResponse.user!.avatarUrl,
        };
        await storage.write(key: 'user_data', value: jsonEncode(userData));
        
        // 🔥 เก็บ delegate_id สำหรับดึง QR Code
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
    await storage.delete(key: 'delegate_id'); // 🔥 ลบ delegate_id ด้วย
  }

  @override
  Future<String?> getToken() async {
    final storage = Modular.get<FlutterSecureStorage>();
    return await storage.read(key: 'auth_token');
  }
}