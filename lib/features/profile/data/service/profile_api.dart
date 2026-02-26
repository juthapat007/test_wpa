import 'dart:core';
import 'dart:io';
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
      // final response = await dio.patch('/profile', data: {'profile': data});
      final response = await dio.patch('/profile', data: data);
      log.d('edited profile: ${response.data}');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  ///update profile
  Future<Response> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });
      final response = await dio.patch('/profile/avatar', data: formData);
      log.d('uploaded avatar: ${response.data}');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
