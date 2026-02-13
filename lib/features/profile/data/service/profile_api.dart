import 'package:dio/dio.dart';

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
}
