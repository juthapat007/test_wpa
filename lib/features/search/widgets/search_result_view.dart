import 'package:flutter/material.dart';
import 'package:test_wpa/features/search/presentation/bloc/search_bloc.dart';
import 'package:test_wpa/features/search/views/search_page.dart';
import 'package:test_wpa/features/search/widgets/delegate_list_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/search/widgets/search_empty_view.dart';
import 'package:test_wpa/features/search/widgets/search_error_view.dart';
import 'package:test_wpa/features/search/widgets/search_initial_view.dart';

class SearchResultView extends StatelessWidget {
  final ScrollController scrollController;

  const SearchResultView({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SearchError) {
          return SearchErrorView(message: state.message);
        }

        if (state is SearchLoaded) {
          if (state.response.delegates.isEmpty) {
            return const SearchEmptyView();
          }

          return DelegateListView(
            response: state.response,
            scrollController: scrollController,
            isLoadingMore: state.isLoadingMore,
          );
        }

        return const SearchInitialView();
      },
    );
  }
}
