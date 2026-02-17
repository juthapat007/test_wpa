// lib/features/Other_profile/domain/entities/schedule_item.dart

class ScheduleItem {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? type;

  ScheduleItem({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.type,
  });
}
