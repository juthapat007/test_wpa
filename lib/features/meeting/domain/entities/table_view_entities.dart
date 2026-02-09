// lib/features/meeting/domain/entities/table_view.dart

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

  TableInfo({
    required this.tableId,
    required this.tableNumber,
    required this.delegates,
  });

  bool get isOccupied => delegates.isNotEmpty;
}

class TableViewResponse {
  final int year;
  final String date;
  final String time;
  final String myTable;
  final List<TableInfo> tables;
  final List<String> timesToday;
  final List<String> days;

  TableViewResponse({
    required this.year,
    required this.date,
    required this.time,
    required this.myTable,
    required this.tables,
    required this.timesToday,
    required this.days,
  });
}
