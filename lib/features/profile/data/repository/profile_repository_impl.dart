import 'package:test_wpa/features/auth/data/models/login_response.dart';
import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:dio/dio.dart';
import 'package:test_wpa/features/profile/data/repository/service/profile_api.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';
import 'package:test_wpa/features/profile/presentation/page/profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi api;

  ProfileRepositoryImpl(this.api);

  @override
  Future<ProfileModel> getProfile() async {
    final data = await api.getProfile();
    return ProfileModel.fromJson(data);
  }
}
