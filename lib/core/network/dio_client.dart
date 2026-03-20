import 'package:dio/dio.dart';
import 'package:test_wpa/core/constants/setup_Logger.dart';
import 'package:test_wpa/core/interceptors/auth_interceptor.dart';

class DioClient {
  static const webAppUrl = 'https://wpaapp2026.web.app';
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  DioClient._internal() {
    dio.interceptors.add(setupLogger());
    dio.interceptors.add(AuthInterceptor());
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://wpadocker-production.up.railway.app/api/v1',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://wpadocker-production.up.railway.app/api/v1',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    dio.interceptors.add(setupLogger());
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }
}
