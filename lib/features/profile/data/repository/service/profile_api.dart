import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:test_wpa/features/profile/data/repository/profile_repository_impl.dart';
import 'package:test_wpa/features/profile/presentation/page/profile_widget.dart';
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
