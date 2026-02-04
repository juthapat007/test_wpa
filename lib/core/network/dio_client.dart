import 'package:dio/dio.dart';
import 'package:test_wpa/core/constants/setup_Logger.dart';
import 'package:test_wpa/core/interceptors/auth_interceptor.dart';

class DioClient {
  // Dio instance (global)
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://wpa-docker.onrender.com/api/v1',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    dio.interceptors.add(setupLogger());
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }
}
