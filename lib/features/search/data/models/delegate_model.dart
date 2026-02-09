import 'package:test_wpa/features/search/domain/entities/delegate.dart';

class DelegateModel {
  final int id;
  final String name;
  final String? title;
  final String email;
  final String companyName;
  final String avatarUrl;
  final String countryCode;
  final int teamId;
  final bool firstLogin;
  final bool isConnected;

  DelegateModel({
    required this.id,
    required this.name,
    this.title,
    required this.email,
    required this.companyName,
    required this.avatarUrl,
    required this.countryCode,
    required this.teamId,
    required this.firstLogin,
    required this.isConnected,
  });

  factory DelegateModel.fromJson(Map<String, dynamic> json) {
    return DelegateModel(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'],
      email: json['email'] ?? '',
      companyName: json['company_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      countryCode: json['country_code'] ?? '',
      teamId: json['team_id'],
      firstLogin: json['first_login'] ?? false,
      isConnected: json['is_connected'] ?? false,
    );
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
      teamId: teamId,
      firstLogin: firstLogin,
      isConnected: isConnected,
    );
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
