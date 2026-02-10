import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/features/search/presentation/bloc/search_bloc.dart';
import 'package:test_wpa/features/search/widgets/delegate_search_bar%20.dart';
import 'package:test_wpa/features/search/widgets/search_result_view.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ReadContext(context).read<SearchBloc>().add(SearchDelegates());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ReadContext(context).read<SearchBloc>().add(LoadMoreDelegates());
    }
  }

  void _onSearch(String keyword) {
    ReadContext(context).read<SearchBloc>().add(
      SearchDelegates(keyword: keyword.isEmpty ? null : keyword),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Search Delegates',
      currentIndex: 1,
      backgroundColor: const Color(0xFFF9FAFB),
      appBarStyle: AppBarStyle.elegant,

      body: Column(
        children: [
          SizedBox(height: space.s),

          DelegateSearchBar(
            controller: _searchController,
            icon: Icons.search,
            label: 'Search by name, email, or company',
            onSearch: _onSearch,
          ),

          SizedBox(height: space.s),

          Expanded(
            child: SearchResultView(scrollController: _scrollController),
          ),
        ],
      ),
    );
  }
}
