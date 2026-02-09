import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class Schedule {
  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final String? tableNumber;
  final String country;
  final String conferenceDate;
  final ScheduleDelegate? delegate; // เก่า - deprecated
  final List<TeamDelegate>? teamDelegates; // ✅ ใหม่
  final int? durationMinutes;
  final dynamic leave;
  final String? type;
  final String? title; // ✅ เพิ่มสำหรับ event

  Schedule({
    required this.id,
    required this.startAt,
    required this.endAt,
    this.tableNumber,
    required this.country,
    required this.conferenceDate,
    this.delegate,
    this.teamDelegates,
    this.durationMinutes,
    this.leave,
    this.type,
    this.title,
  });
}

// ✅ Delegate แบบเก่า (อาจจะไม่ใช้แล้ว)
class ScheduleDelegate {
  final int? id;
  final String? name;
  final String? company;

  ScheduleDelegate({
    required this.id,
    required this.name,
    required this.company,
  });
}

// ✅ Team Delegate แบบใหม่
class TeamDelegate {
  final int id;
  final String name;
  final String company;

  TeamDelegate({required this.id, required this.name, required this.company});
}

class ScheduleResponse {
  final ScheduleStatus status;
  final List<String> availableYears;
  final String year;
  final List<String> availableDates;
  final String date;
  final List<Schedule> schedules;
  final String? message;

  const ScheduleResponse({
    required this.status,
    required this.availableYears,
    required this.year,
    required this.availableDates,
    required this.date,
    required this.schedules,
    this.message,
  });

  factory ScheduleResponse.empty({String? year, String? date}) {
    return ScheduleResponse(
      status: ScheduleStatus.empty,
      availableYears: [],
      year: year ?? '',
      availableDates: [],
      date: date ?? '',
      schedules: [],
    );
  }
}
