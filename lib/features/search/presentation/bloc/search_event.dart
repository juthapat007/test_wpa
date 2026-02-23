part of 'search_bloc.dart';

@immutable
sealed class SearchEvent {}

class SearchDelegates extends SearchEvent {
  final String? keyword;
  final int page;
  final int perPage;
  final bool friendsOnly;

  SearchDelegates({
    this.keyword,
    this.page = 1,
    this.perPage = 50,
    this.friendsOnly = false,
  });
}

class LoadMoreDelegates extends SearchEvent {}

class ResetSearch extends SearchEvent {}
