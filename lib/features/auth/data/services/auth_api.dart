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
}
