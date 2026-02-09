import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:dio/dio.dart';
import 'package:test_wpa/features/profile/domain/entities/profile.dart';
import 'package:test_wpa/features/profile/presentation/page/profile_widget.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
}
