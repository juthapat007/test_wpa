import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class AuthInterceptor extends Interceptor {
//   @override
//   Future<void> onRequest(
//     RequestOptions options,
//     RequestInterceptorHandler handler,
//   ) async {
//     // ดึง token จาก secure storage
//     final storage = Modular.get<FlutterSecureStorage>();
//     final token = await storage.read(key: 'auth_token');

//     // ถ้ามี token ให้แนบไปกับ header
//     if (token != null && token.isNotEmpty) {
//       options.headers['Authorization'] = 'Bearer $token';
//       print('Token attached: Bearer ${token.substring(0, 20)}...');
//     } else {
//       print('No token found');
//     }

//     handler.next(options);
//   }
// }

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/login')) {
      print('Skip auth for login');
      return handler.next(options);
    }

    final storage = Modular.get<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('Token attached: Bearer ${token.substring(0, 20)}...');
    } else {
      print('No token found');
    }

    handler.next(options);
  }
}

//หน้านี้เอาไว้เช็ค token ว่าาโดนส่งมามั้ย
