import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:test_wpa/features/profile/data/service/profile_api.dart';
import 'package:test_wpa/features/profile/domain/entities/profile.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi api;

  ProfileRepositoryImpl({required this.api});

  @override
  Future<Profile> getProfile() async {
    try {
      final json = await api.getProfile();

      final model = ProfileModel.fromJson(json);

      final entity = model.toEntity();

      return entity;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}
