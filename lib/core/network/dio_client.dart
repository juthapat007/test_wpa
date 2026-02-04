import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/core/constants/setup_Logger.dart';
import 'package:test_wpa/core/interceptors/auth_interceptor.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://wpa-docker.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> init() async {
    dio.interceptors.clear();
    dio.interceptors.add(setupLogger());
    dio.interceptors.add(AuthInterceptor());
  }

  // ✅ ADD THIS METHOD
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
