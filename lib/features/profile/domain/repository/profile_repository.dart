import 'package:test_wpa/features/auth/data/models/login_response.dart';
import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:dio/dio.dart';
import 'package:test_wpa/features/profile/presentation/page/profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
}
