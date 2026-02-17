// lib/features/other_profile/domain/repositories/profile_detail_repository.dart

import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';

abstract class ProfileDetailRepository {
  Future<ProfileDetail> getProfileDetail(int delegateId);
}
