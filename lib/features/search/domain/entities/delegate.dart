// delegate.dart — entity

class Delegate {
  final int id;
  final String name;
  final String title;
  final String email;
  final String companyName;
  final String avatarUrl;
  final String countryCode;
  final int? teamId;
  final bool firstLogin;
  final bool isConnected;
  final String connectionStatus;

  Delegate({
    required this.id,
    required this.name,
    this.title = '',
    required this.email,
    this.companyName = '',
    this.avatarUrl = '',
    required this.countryCode,
    this.teamId,
    required this.firstLogin,
    required this.isConnected,
    this.connectionStatus = 'none',
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
