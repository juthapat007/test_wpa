import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/core/constants/setup_Logger.dart';
import 'package:test_wpa/core/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://wpa-docker.onrender.com/api/v1',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> init() async {
    final token = await _storage.read(key: 'token');

    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Modular.to.navigate('/');
          }
          return handler.next(error);
        },
      ),
    );
  }
}
