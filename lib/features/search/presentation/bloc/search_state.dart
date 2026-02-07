part of 'search_bloc.dart';

@immutable
sealed class SearchState {}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchLoaded extends SearchState {
  final DelegateSearchResponse response;
  final bool isLoadingMore;

  SearchLoaded(this.response, {this.isLoadingMore = false});
}

final class SearchError extends SearchState {
  final String message;

  SearchError(this.message);
}