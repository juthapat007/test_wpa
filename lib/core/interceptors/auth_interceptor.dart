import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  bool _isRedirecting = false;
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/login')) {
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

  @override
  // Future<void> onError(
  //   DioException err,
  //   ErrorInterceptorHandler handler,
  // ) async {
  //   if (err.response?.statusCode == 401 && !_isRedirecting) {
  //     _isRedirecting = true;
  //     final storage = Modular.get<FlutterSecureStorage>();
  //     await storage.delete(key: 'auth_token');
  //     await storage.delete(key: 'user_data');
  //     await storage.delete(key: 'delegate_id');
  //     Modular.to.navigate('/login');
  //     Future.delayed(const Duration(seconds: 1), () {
  //       _isRedirecting = false;
  //     });
  //   }
  //   handler.next(err);
  // }
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;

    final is401 = status == 401;

    final isSslError =
        err.type == DioExceptionType.unknown &&
        err.error.toString().contains('CERTIFICATE_VERIFY_FAILED');

    if ((is401 || isSslError) && !_isRedirecting) {
      _isRedirecting = true;

      final storage = Modular.get<FlutterSecureStorage>();
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'user_data');
      await storage.delete(key: 'delegate_id');

      Modular.to.navigate('/login');

      Future.delayed(const Duration(seconds: 1), () {
        _isRedirecting = false;
      });
    }

    handler.next(err);
  }
}

//หน้านี้เอาไว้เช็ค token ว่าโดนส่งมามั้ย
