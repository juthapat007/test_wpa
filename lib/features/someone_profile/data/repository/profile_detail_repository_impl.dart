// lib/features/someone_profile/data/repository/profile_detail_repository_impl.dart

import 'package:test_wpa/features/someone_profile/data/models/profile_detail_model.dart';
import 'package:test_wpa/features/someone_profile/data/services/profile_detail_api.dart';
import 'package:test_wpa/features/someone_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/someone_profile/domain/repositories/profile_detail_repository.dart';

class ProfileDetailRepositoryImpl implements ProfileDetailRepository {
  final ProfileDetailApi api;

  ProfileDetailRepositoryImpl({required this.api});

  @override
  Future<ProfileDetail> getProfileDetail(int delegateId) async {
    try {
      final json = await api.getProfileDetail(delegateId);
      final model = ProfileDetailModel.fromJson(json);
      return model.toEntity();
    } catch (e) {
      print('❌ ProfileDetailRepositoryImpl error: $e');
      throw Exception('Failed to get profile detail: $e');
    }
  }
}
