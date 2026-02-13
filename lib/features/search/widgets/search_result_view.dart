import 'package:flutter/material.dart';
import 'package:test_wpa/features/search/presentation/bloc/search_bloc.dart';
import 'package:test_wpa/features/search/widgets/delegate_list_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/search/widgets/status/search_empty_view.dart';
import 'package:test_wpa/features/search/widgets/status/search_error_view.dart';
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
          //ถ้าอยู่ในสถานะ loading ให้แสดง loading indicator
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
          //ถ้าอยู่ในสถานะ SearchLoaded ให้แสดง DelegateListView
        }

        return const SearchInitialView();
      },
    );
  }
}
