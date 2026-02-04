import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:dio/dio.dart';
abstract class ProfileRepository {
  ProfileRepository(Dio dio);

  Future<ProfileModel> getProfile();
}