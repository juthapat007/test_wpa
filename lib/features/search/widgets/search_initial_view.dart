import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;

//เริ่มต้นกการค้นหา
class SearchInitialView extends StatelessWidget {
  const SearchInitialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: color.AppColors.textSecondary),
          SizedBox(height: space.m),
          Text(
            'Search for delegates',
            style: TextStyle(
              fontSize: 16,
              color: color.AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
