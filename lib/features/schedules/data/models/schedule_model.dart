import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/views/schedule_status.dart';

class ScheduleModel {
  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final String tableNumber;
  final String country;
  final String conferenceDate;
  final ScheduleDelegateModel? delegate;
  final int? durationMinutes;

  ScheduleModel({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.tableNumber,
    required this.country,
    required this.conferenceDate,
    this.delegate,
    this.durationMinutes,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      tableNumber: json['table_number'] ?? '',
      country: json['country'] ?? '',
      conferenceDate: json['conference_date'] ?? '',
      delegate: ScheduleDelegateModel.fromJson(json['delegate']),
      durationMinutes: json['duration_minutes'], // null
    );
  }

  Schedule toEntity() {
    return Schedule(
      id: id,
      startAt: startAt,
      endAt: endAt,
      tableNumber: tableNumber,
      country: country,
      conferenceDate: conferenceDate,
      delegate: delegate?.toEntity(), // ✅ สำคัญมาก
      durationMinutes: durationMinutes,
    );
  }
}

class ScheduleDelegateModel {
  final int? id;
  final String? name;
  final String? company;

  ScheduleDelegateModel({this.id, this.name, this.company});

  factory ScheduleDelegateModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ScheduleDelegateModel();
    }

    return ScheduleDelegateModel(
      id: json['id'],
      name: json['name'],
      company: json['company'],
    );
  }

  ScheduleDelegate toEntity() {
    return ScheduleDelegate(id: id, name: name, company: company);
  }
}

class ScheduleResponseModel {
  final List<String> availableYears;
  final String year;
  final List<String> availableDates;
  final String date;
  final List<ScheduleModel> schedules;

  ScheduleResponseModel({
    required this.availableYears,
    required this.year,
    required this.availableDates,
    required this.date,
    required this.schedules,
  });

  factory ScheduleResponseModel.fromJson(Map<String, dynamic> json) {
    return ScheduleResponseModel(
      availableYears: List<String>.from(json['available_years'] ?? []),
      year: json['year'] ?? '',
      availableDates: List<String>.from(json['available_dates'] ?? []),
      date: json['date'] ?? '',
      schedules:
          (json['schedules'] as List?)
              ?.map((e) => ScheduleModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  ScheduleResponse toEntity({ScheduleStatus status = ScheduleStatus.success}) {
    return ScheduleResponse(
      status: status,
      availableYears: availableYears,
      year: year,
      availableDates: availableDates,
      date: date,
      schedules: schedules.map((s) => s.toEntity()).toList(),
    );
  }
}
