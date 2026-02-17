class Delegate {
  final int id;
  final String name;
  final String title; // ✅ non-nullable ตามโค้ดเดิม
  final String email;
  final String companyName;
  final String avatarUrl;
  final String countryCode;
  final int teamId;
  final bool firstLogin;
  final bool isConnected;

  Delegate({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.companyName,
    required this.avatarUrl,
    required this.countryCode,
    required this.teamId,
    required this.firstLogin,
    required this.isConnected,
  });
}

class DelegateSearchResponse {
  final List<Delegate> delegates;
  final DelegateMeta meta;

  DelegateSearchResponse({required this.delegates, required this.meta});
}

class DelegateMeta {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  DelegateMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });
}
