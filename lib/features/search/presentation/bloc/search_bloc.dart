import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';
import 'package:test_wpa/features/search/domain/repositories/delegate_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final DelegateRepository delegateRepository;

  String? _currentKeyword;
  int _currentPage = 1;
  List<Delegate> _allDelegates = [];

  SearchBloc({required this.delegateRepository}) : super(SearchInitial()) {
    on<SearchDelegates>(_onSearchDelegates);
    on<LoadMoreDelegates>(_onLoadMore);
    on<ResetSearch>(_onReset);
  }

  Future<void> _onSearchDelegates(
    SearchDelegates event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      _currentKeyword = event.keyword;
      _currentPage = event.page;

      final response = await delegateRepository.searchDelegates(
        keyword: event.keyword,
        page: event.page,
        perPage: event.perPage,
      );

      _allDelegates = response.delegates;
      emit(SearchLoaded(response));
    } catch (e) {
      print('❌ SearchBloc error: $e');
      emit(SearchError('Cannot search delegates: $e'));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreDelegates event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded) return;

    // Check if there are more pages
    if (_currentPage >= currentState.response.meta.totalPages) return;

    emit(SearchLoaded(currentState.response, isLoadingMore: true));

    try {
      _currentPage++;
      final response = await delegateRepository.searchDelegates(
        keyword: _currentKeyword,
        page: _currentPage,
        perPage: 50,
      );

      _allDelegates.addAll(response.delegates);

      final newResponse = DelegateSearchResponse(
        delegates: _allDelegates,
        meta: response.meta,
      );

      emit(SearchLoaded(newResponse));
    } catch (e) {
      emit(SearchError('Cannot load more: $e'));
    }
  }

  void _onReset(ResetSearch event, Emitter<SearchState> emit) {
    _currentKeyword = null;
    _currentPage = 1;
    _allDelegates = [];
    emit(SearchInitial());
  }
}
