// lib/features/widgets/date_header.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';

class DateHeader extends StatefulWidget {
  const DateHeader({super.key});

  @override
  State<DateHeader> createState() => _DateHeaderState();
}

class _DateHeaderState extends State<DateHeader> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateTimeHelper.formatFullDate(_now);
    final timeText = DateTimeHelper.formatTime12(_now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color.AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: space.s),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 14,
              color: color.AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
