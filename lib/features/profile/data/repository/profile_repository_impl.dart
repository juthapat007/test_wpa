import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:test_wpa/features/profile/data/repository/service/profile_api.dart';
import 'package:test_wpa/features/profile/domain/entities/profile.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi api;

  // ✅ CHANGED: from ProfileRepositoryImpl(this.api) to:
  ProfileRepositoryImpl({required this.api});

  @override
  Future<Profile> getProfile() async {
    try {
      final json = await api.getProfile();
      print('📦 API Response: $json');
      
      final model = ProfileModel.fromJson(json);
      print('✅ Model created: ${model.name}');
      
      final entity = model.toEntity();
      print('✅ Entity created: ${entity.name}');
      
      return entity;
    } catch (e, stackTrace) {
      print('❌ ProfileRepositoryImpl error: $e');
      print('📍 StackTrace: $stackTrace');
      throw Exception('Failed to load profile: $e');
    }
  }
}