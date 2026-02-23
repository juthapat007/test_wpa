// lib/features/schedules/domain/entities/schedule_others_response.dart

import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';

class ScheduleOthersResponse {
  final List<String> availableDates; // ["2025-10-12", "2025-10-13", ...]
  final String selectedDate; // วันที่ที่ API ส่งกลับมาเป็น default
  final List<Schedule> schedules; // schedules ของวันที่เลือก

  ScheduleOthersResponse({
    required this.availableDates,
    required this.selectedDate,
    required this.schedules,
  });
}
