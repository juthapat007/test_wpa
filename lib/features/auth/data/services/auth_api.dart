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
  /// Body: { token, password, password_confirmation }
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
}
