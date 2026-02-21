import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/login')) {
      // print('Skip auth for login');
      return handler.next(options);
    }

    final storage = Modular.get<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      print('No token found');
    }

    handler.next(options);
  }
}

//หน้านี้เอาไว้เช็ค token ว่าาโดนส่งมามั้ย
