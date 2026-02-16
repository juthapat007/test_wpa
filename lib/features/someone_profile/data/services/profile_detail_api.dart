// lib/features/someone_profile/data/services/profile_detail_api.dart

import 'package:dio/dio.dart';

class ProfileDetailApi {
  final Dio dio;

  ProfileDetailApi(this.dio);

  /// Get someone profile detail
  Future<Map<String, dynamic>> getProfileDetail(int delegateId) async {
    try {
      final response = await dio.get('/delegates/$delegateId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ ProfileDetailApi error: $e');
      rethrow;
    }
  }
}
