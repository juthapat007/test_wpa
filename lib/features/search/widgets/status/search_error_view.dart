import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/search/presentation/bloc/search_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchErrorView extends StatelessWidget {
  final String message;

  const SearchErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: color.AppColors.error,
          ),
          SizedBox(height: space.m),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: color.AppColors.error),
          ),
          SizedBox(height: space.m),
          ElevatedButton(
            onPressed: () {
              context.read<SearchBloc>().add(SearchDelegates());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
