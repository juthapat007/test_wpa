import 'dart:core';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:test_wpa/core/constants/print_logger.dart';

class ProfileApi {
  final Dio dio;

  ProfileApi(this.dio);

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await dio.get('/profile');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await dio.patch('/profile', data: {'profile': data});
      log.d('edited profile: ${response.data}');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
