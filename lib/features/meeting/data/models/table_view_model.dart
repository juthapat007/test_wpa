import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

class TableDelegateModel {
  final int delegateId;
  final String delegateName;
  final String company;
  final String avatarUrl;
  final String? title;

  TableDelegateModel({
    required this.delegateId,
    required this.delegateName,
    required this.company,
    required this.avatarUrl,
    this.title,
  });

  factory TableDelegateModel.fromJson(Map<String, dynamic> json) {
    return TableDelegateModel(
      delegateId: json['delegate_id'],
      delegateName: json['delegate_name'] ?? '',
      company: json['company'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      title: json['title'],
    );
  }

  TableDelegate toEntity() {
    return TableDelegate(
      delegateId: delegateId,
      delegateName: delegateName,
      company: company,
      avatarUrl: avatarUrl,
      title: title,
    );
  }
}

class TableInfoModel {
  final int tableId;
  final String tableNumber;
  final List<TableDelegateModel> delegates;

  TableInfoModel({
    required this.tableId,
    required this.tableNumber,
    required this.delegates,
  });

  factory TableInfoModel.fromJson(Map<String, dynamic> json) {
    return TableInfoModel(
      tableId: json['table_id'],
      tableNumber: json['table_number'] ?? '',
      delegates:
          (json['delegates'] as List?)
              ?.map((e) => TableDelegateModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  TableInfo toEntity() {
    return TableInfo(
      tableId: tableId,
      tableNumber: tableNumber,
      delegates: delegates.map((d) => d.toEntity()).toList(),
    );
  }
}

class TableViewResponseModel {
  final int year;
  final String date;
  final String time;
  final String myTable;
  final List<TableInfoModel> tables;
  final List<String> timesToday;
  final List<String> days;

  TableViewResponseModel({
    required this.year,
    required this.date,
    required this.time,
    required this.myTable,
    required this.tables,
    required this.timesToday,
    required this.days,
  });

  factory TableViewResponseModel.fromJson(Map<String, dynamic> json) {
    return TableViewResponseModel(
      year: json['year'],
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      myTable: json['my_table'] ?? '',
      tables:
          (json['tables'] as List?)
              ?.map((e) => TableInfoModel.fromJson(e))
              .toList() ??
          [],
      timesToday: List<String>.from(json['times_today'] ?? []),
      days: List<String>.from(json['days'] ?? []),
    );
  }

  TableViewResponse toEntity() {
    return TableViewResponse(
      year: year,
      date: date,
      time: time,
      myTable: myTable,
      tables: tables.map((t) => t.toEntity()).toList(),
      timesToday: timesToday,
      days: days,
    );
  }
}
