import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';

class ScheduleItemModel {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? type;

  ScheduleItemModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.type,
  });

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleItemModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.parse(
        json['start_time'] ??
            json['start_at'] ??
            DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        json['end_time'] ?? json['end_at'] ?? DateTime.now().toIso8601String(),
      ),
      location: json['location'],
      type: json['type'],
    );
  }

  ScheduleItem toEntity() {
    return ScheduleItem(
      id: id,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      type: type,
    );
  }
}
