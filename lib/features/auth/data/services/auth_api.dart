import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthApi {
  final Dio dio;

  AuthApi(this.dio);

  Future<Response> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      debugPrint(' API response: ${response.data}');
      return response;
    } catch (e, s) {
      debugPrint(' API error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// POST /forgot_password
  Future<Response> forgotPassword(String email) async {
    try {
      return await dio.post('/forgot_password', data: {'email': email});
    } catch (e) {
      rethrow;
    }
  }

  /// POST /reset_password
  Future<Response> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      return await dio.post(
        '/reset_password',
        data: {
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST /change_password
  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      return await dio.post(
        '/change_password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}