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
    bool friendsOnly = false,
  }) async {
    final model = await api.searchDelegates(
      keyword: keyword,
      page: page,
      perPage: perPage,
      friendsOnly: friendsOnly,
    );

    return DelegateSearchResponse(
      meta: DelegateMeta(
        page: model.page,
        perPage: model.perPage,
        total: model.total,
        totalPages: model.totalPages,
      ),

      // delegate_repository_impl.dart — แก้ teamId
      delegates: model.delegates
          .map(
            (d) => Delegate(
              id: d.id,
              name: d.name,
              title: d.title ?? '',
              email: d.email,
              companyName: d.companyName ?? '',
              avatarUrl: d.avatarUrl ?? '',
              countryCode: d.countryCode,
              teamId: d.teamId,
              firstLogin: d.firstLogin,
              isConnected: d.isConnected,
              connectionStatus: d.connectionStatus,
            ),
          )
          .toList(),
    );
  }
}
