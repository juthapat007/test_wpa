import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class ScheduleModel {
  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final String? tableNumber;
  final String country;
  final String conferenceDate;
  final ScheduleDelegateModel? delegate;
  final List<TeamDelegateModel>? teamDelegates; // ✅ เพิ่ม
  final int? durationMinutes;
  final dynamic leave;
  final String? type;
  final String? title; // ✅ เพิ่ม

  ScheduleModel({
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

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      tableNumber: json['table_number'],
      country: json['country'] ?? '',
      conferenceDate: json['conference_date'] ?? '',
      delegate: json['delegate'] != null
          ? ScheduleDelegateModel.fromJson(json['delegate'])
          : null,
      teamDelegates: json['team_delegates'] != null
          ? (json['team_delegates'] as List)
                .map((e) => TeamDelegateModel.fromJson(e))
                .toList()
          : null,
      durationMinutes: json['duration_minutes'],
      leave: json['leave'],
      type: json['type'],
      title: json['title'], // ✅ สำหรับ event
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
      delegate: delegate?.toEntity(),
      teamDelegates: teamDelegates?.map((d) => d.toEntity()).toList(),
      durationMinutes: durationMinutes,
      leave: leave,
      type: type,
      title: title,
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

// ✅ เพิ่ม TeamDelegateModel
class TeamDelegateModel {
  final int id;
  final String name;
  final String company;

  TeamDelegateModel({
    required this.id,
    required this.name,
    required this.company,
  });

  factory TeamDelegateModel.fromJson(Map<String, dynamic> json) {
    return TeamDelegateModel(
      id: json['id'],
      name: json['name'] ?? '',
      company: json['company'] ?? '',
    );
  }

  TeamDelegate toEntity() {
    return TeamDelegate(id: id, name: name, company: company);
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
