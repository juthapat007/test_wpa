// lib/features/other_profile/data/models/profile_detail_model.dart

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
  // ✅ เพิ่ม field นี้ — backend ส่ง connection_request_id มาด้วยเมื่อสถานะเป็น requested_to_me
  final int? connectionRequestId;

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
    this.connectionRequestId,
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
      // ✅ รับ request id จาก backend (ชื่อ field อาจต้องปรับตาม API จริง)
      connectionRequestId: json['connection_request_id'],
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
      connectionRequestId: connectionRequestId,
    );
  }
}