import 'package:test_wpa/features/search/domain/entities/delegate.dart';

abstract class DelegateRepository {
  Future<DelegateSearchResponse> searchDelegates({
    String? keyword,
    int page = 1,
    int perPage = 50,
  });
}
