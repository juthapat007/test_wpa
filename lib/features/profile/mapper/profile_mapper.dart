import 'package:test_wpa/features/profile/data/models/profile_view_Model.dart';
import 'package:test_wpa/features/profile/data/models/select_option.dart';
import 'package:test_wpa/features/profile/domain/entities/profile.dart';

extension ProfilePresentationMapper on Profile {
  ProfileViewModel toViewModel() {
    return ProfileViewModel(
      name: name,
      title: title,
      avatarUrl: avatarUrl,
      companyName: company,
      teamName: team,
      pushNotifications: true,
      emailNotifications: true,
    );
  }
}
