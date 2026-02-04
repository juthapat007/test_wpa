import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:test_wpa/features/profile/data/repository/service/profile_api.dart';
import 'package:test_wpa/features/profile/domain/repository/profile_repository.dart';
import 'package:test_wpa/features/profile/presentation/page/profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi api;

  ProfileRepositoryImpl({required this.api});

  @override
  Future<Profile> getProfile() async {
    try {
      final json = await api.getProfile();
      final model = ProfileModel.fromJson(json);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to load profile');
    }
  }
}

