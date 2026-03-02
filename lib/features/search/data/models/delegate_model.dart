import 'package:dio/dio.dart';

// delegate_model.dart

class DelegateModel {
  final int id;
  final String name;
  final String? title; // null ใน API
  final String email;
  final String? companyName;
  final String? avatarUrl;
  final String countryCode;
  final int? teamId; // ✅ null ใน API (เช่น Daniel Johnson)
  final bool firstLogin;
  final bool isConnected;
  final String connectionStatus;

  DelegateModel({
    required this.id,
    required this.name,
    this.title,
    required this.email,
    this.companyName,
    this.avatarUrl,
    required this.countryCode,
    this.teamId, // ✅ optional
    required this.firstLogin,
    required this.isConnected,
    required this.connectionStatus,
  });

  factory DelegateModel.fromJson(Map<String, dynamic> json) => DelegateModel(
    id: json['id'] as int,
    name: json['name'] as String,
    title: json['title'] as String?,
    email: json['email'] as String,
    companyName: json['company_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    countryCode: json['country_code'] as String? ?? 'N/A',
    teamId: json['team_id'] as int?, // ✅ ไม่ crash ถ้า null
    firstLogin: json['first_login'] as bool,
    isConnected: json['is_connected'] as bool,
    connectionStatus: json['connection_status'] as String? ?? 'none',
  );
}

class DelegateResponseModel {
  final int total;
  final int page;
  final int perPage;
  final int totalPages;
  final List<DelegateModel> delegates;

  DelegateResponseModel({
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.delegates,
  });

  factory DelegateResponseModel.fromJson(Map<String, dynamic> json) =>
      DelegateResponseModel(
        total: json['total'] as int,
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        totalPages: json['total_pages'] as int,
        delegates: (json['delegates'] as List<dynamic>)
            .map((e) => DelegateModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get hasNextPage => page < totalPages;
}
