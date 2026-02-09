import 'package:test_wpa/features/search/data/models/delegate_model.dart';
import 'package:test_wpa/features/search/data/services/delegate_api.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';
import 'package:test_wpa/features/search/domain/repositories/delegate_repository.dart';

class DelegateRepositoryImpl implements DelegateRepository {
  final DelegateApi api;

  DelegateRepositoryImpl({required this.api});

  @override
  Future<DelegateSearchResponse> searchDelegates({
    String? keyword,
    int page = 1,
    int perPage = 50,
  }) 
  async {
    try {
      final json = await api.searchDelegates(
        keyword: keyword,
        page: page,
        perPage: perPage,
      );

      final model = DelegateSearchResponseModel.fromJson(json);
      return model.toEntity();
    } catch (e) {
      print('❌ DelegateRepositoryImpl error: $e');
      throw Exception('Failed to search delegates: $e');
    }
  }
}
