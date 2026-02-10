import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/core/theme/app_colors.dart';

class DateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onCalendarTap;

  const DateHeader({
    super.key,
    required this.selectedDate,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM yyyy').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            formattedDate,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 16,
              color: AppColors.primary,
              backgroundColor: AppColors.background,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onCalendarTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.today,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
