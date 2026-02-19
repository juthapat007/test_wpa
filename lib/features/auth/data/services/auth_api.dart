import 'dart:io';

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
      debugPrint('API response: ${response.data}');
      return response;
    } catch (e, s) {
      debugPrint('API error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// PATCH /api/v1/device_token
  /// ส่ง FCM token หลัง login สำเร็จ
  /// body: { "device": { "device_token": "xxx" } }
  Future<void> registerDeviceToken(String token) async {
    try {
      await dio.patch(
        '/device_token',
        data: {
          'device': {
            'device_token': token,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          },
        },
      );
      debugPrint('✅ Device token registered');
    } catch (e) {
      // ไม่ throw — ถ้าส่งไม่ได้แค่ไม่ได้รับ push ไม่ให้ login พัง
      debugPrint('⚠️ Failed to register device token: $e');
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

  /// PUT /change_password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await dio.put(
      '/change_password',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }
}