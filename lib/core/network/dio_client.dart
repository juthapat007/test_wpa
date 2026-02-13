import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/core/constants/setup_Logger.dart';
import 'package:test_wpa/core/interceptors/auth_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();
  //internal

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://wpa-docker.onrender.com/api/v1',
      connectTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  //dio ตัวนี้จะถูกใช้ทั้งแอป

  Future<void> init() async {
    dio.interceptors.clear();
    dio.interceptors.add(setupLogger());
    dio.interceptors.add(AuthInterceptor());
  }

  //  ADD THIS METHOD

  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://wpa-docker.onrender.com/api/v1',
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    dio.interceptors.add(setupLogger());
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }

  //สว่น dio ตัวนี้จะถูกใช้ในแต่ละ feature
}
