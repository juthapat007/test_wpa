import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/widgets/app_scaffold.dart';

class AttendanceStatus extends StatelessWidget {
  const AttendanceStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Attendance Status',
      currentIndex: -1,
      showAvatar: false,
    );
  }
}
