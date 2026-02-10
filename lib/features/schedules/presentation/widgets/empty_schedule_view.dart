import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;

class EmptyScheduleView extends StatelessWidget {
  const EmptyScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: color.AppColors.textSecondary,
          ),
          SizedBox(height: space.m),
          Text(
            'No schedules for this date',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 16,
              color: color.AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
