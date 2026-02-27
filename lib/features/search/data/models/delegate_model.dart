// lib/features/search/data/models/delegate_model.dart

import 'package:test_wpa/features/search/domain/entities/delegate.dart';

class DelegateModel {
  final int id;
  final String name;
  final String? title;
  final String email;
  final String companyName;
  final String avatarUrl;
  final String countryCode;
  final bool isConnected;
  final int? teamId;
  final bool? firstLogin;
  // ✅ เพิ่ม connection_status
  final String connectionStatus;

  DelegateModel({
    required this.id,
    required this.name,
    this.title,
    required this.email,
    required this.companyName,
    required this.avatarUrl,
    required this.countryCode,
    required this.isConnected,
    this.teamId,
    this.firstLogin,
    this.connectionStatus = 'none',
  });

  factory DelegateModel.fromJson(Map<String, dynamic> json) {
    return DelegateModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      title: json['title'],
      email: json['email'] ?? '',
      companyName: json['company_name'] ?? '',
      avatarUrl: _resolveUrl(json['avatar_url']), // ✅ แก้ตรงนี้
      countryCode: json['country_code'] ?? '',
      isConnected: json['is_connected'] ?? false,
      teamId: json['team_id'],
      firstLogin: json['first_login'],
      connectionStatus: json['connection_status'] ?? 'none',
    );
  }

  // ✅ เพิ่ม helper นี้ใน DelegateModel
  static String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://wpa-docker.onrender.com$url';
  }

  Delegate toEntity() {
    return Delegate(
      id: id,
      name: name,
      title: title ?? '',
      email: email,
      companyName: companyName,
      avatarUrl: avatarUrl,
      countryCode: countryCode,
      isConnected: isConnected,
      teamId: teamId ?? 0,
      firstLogin: firstLogin ?? false,
      connectionStatus: connectionStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'email': email,
      'company_name': companyName,
      'avatar_url': avatarUrl,
      'country_code': countryCode,
      'is_connected': isConnected,
      'team_id': teamId,
      'first_login': firstLogin,
      'connection_status': connectionStatus,
    };
  }
}

class DelegateMetaModel {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  DelegateMetaModel({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory DelegateMetaModel.fromJson(Map<String, dynamic> json) {
    return DelegateMetaModel(
      page: json['page'],
      perPage: json['per_page'],
      total: json['total'],
      totalPages: json['total_pages'],
    );
  }

  DelegateMeta toEntity() {
    return DelegateMeta(
      page: page,
      perPage: perPage,
      total: total,
      totalPages: totalPages,
    );
  }
}

class DelegateSearchResponseModel {
  final List<DelegateModel> delegates;
  final DelegateMetaModel meta;

  DelegateSearchResponseModel({required this.delegates, required this.meta});

  factory DelegateSearchResponseModel.fromJson(Map<String, dynamic> json) {
    return DelegateSearchResponseModel(
      delegates: (json['data'] as List)
          .map((e) => DelegateModel.fromJson(e))
          .toList(),
      meta: DelegateMetaModel.fromJson(json['meta']),
    );
  }

  DelegateSearchResponse toEntity() {
    return DelegateSearchResponse(
      delegates: delegates.map((d) => d.toEntity()).toList(),
      meta: meta.toEntity(),
    );
  }
}
