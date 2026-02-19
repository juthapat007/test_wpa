import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';

class ProfileDetailModel {
  final int id;
  final String name;
  final String? title;
  final String email;
  final String companyName;
  final String avatarUrl;
  final String countryCode;
  final bool isConnected;
  final String? connectionStatus;
  final int? teamId;

  ProfileDetailModel({
    required this.id,
    required this.name,
    this.title,
    required this.email,
    required this.companyName,
    required this.avatarUrl,
    required this.countryCode,
    required this.isConnected,
    this.connectionStatus,
    this.teamId,
  });

  factory ProfileDetailModel.fromJson(Map<String, dynamic> json) {
    return ProfileDetailModel(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'],
      email: json['email'] ?? '',
      companyName: json['company_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      countryCode: json['country_code'] ?? '',
      isConnected: json['is_connected'] ?? false,
      connectionStatus: json['connection_status'],
      teamId: json['team_id'],
    );
  }

  ProfileDetail toEntity() {
    return ProfileDetail(
      id: id,
      name: name,
      title: title,
      email: email,
      companyName: companyName,
      avatarUrl: avatarUrl,
      countryCode: countryCode,
      isConnected: isConnected,
      connectionStatus: ProfileDetail.parseConnectionStatus(connectionStatus),
      teamId: teamId,
    );
  }
}
