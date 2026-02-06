import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class Schedule {
  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final String tableNumber;
  final String country;
  final String conferenceDate;
  final ScheduleDelegate? delegate;
  final int? durationMinutes;

  Schedule({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.tableNumber,
    required this.country,
    required this.conferenceDate,
    required this.delegate,
    required this.durationMinutes,
  });
}

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

// class ScheduleResponse {
//   final List<String> availableYears;
//   final String year;
//   final List<String> availableDates;
//   final String date;
//   final List<Schedule> schedules;

//   ScheduleResponse({
//     required this.availableYears,
//     required this.year,
//     required this.availableDates,
//     required this.date,
//     required this.schedules, required status,
//   });
// }

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
