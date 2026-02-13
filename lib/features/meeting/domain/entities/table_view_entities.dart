// lib/features/meeting/domain/entities/table_view_entities.dart

import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class TableDelegate {
  final int delegateId;
  final String delegateName;
  final String company;
  final String avatarUrl;
  final String? title;

  TableDelegate({
    required this.delegateId,
    required this.delegateName,
    required this.company,
    required this.avatarUrl,
    this.title,
  });
}

class TableInfo {
  final int tableId;
  final String tableNumber;
  final List<TableDelegate> delegates;
  final List<String> nearTables; // เพิ่ม field นี้

  TableInfo({
    required this.tableId,
    required this.tableNumber,
    required this.delegates,
    this.nearTables = const [],
  });

  bool get isOccupied => delegates.isNotEmpty;
}

// เพิ่ม class สำหรับ layout
class TableLayout {
  final String type; // "grid", "custom", etc.
  final int rows;
  final int columns;

  TableLayout({required this.type, required this.rows, required this.columns});
}

class TableViewResponse {
  final int year;
  final String date;
  final String time;
  final String myTable;
  final List<TableInfo> tables;
  final List<String> timesToday;
  final List<String> days;
  final TableLayout? layout; // เพิ่ม field นี้

  TableViewResponse({
    required this.year,
    required this.date,
    required this.time,
    required this.myTable,
    required this.tables,
    required this.timesToday,
    required this.days,
    this.layout,
  });
}

class ScheduleWithStatus {
  final Schedule schedule;
  final ScheduleStatus status;

  ScheduleWithStatus({required this.schedule, required this.status});
}
