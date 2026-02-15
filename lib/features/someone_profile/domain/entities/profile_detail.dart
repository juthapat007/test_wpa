// lib/features/someone_profile/domain/entities/profile_detail.dart

class ProfileDetail {
  final int id;
  final String name;
  final String? title;
  final String email;
  final String companyName;
  final String avatarUrl;
  final String countryCode;
  final bool isConnected;

  ProfileDetail({
    required this.id,
    required this.name,
    this.title,
    required this.email,
    required this.companyName,
    required this.avatarUrl,
    required this.countryCode,
    required this.isConnected,
  });
}
