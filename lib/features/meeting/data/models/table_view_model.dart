import 'package:flutter/foundation.dart';
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
      delegateId: json['id'] as int? ?? 0,
      delegateName: json['name'] ?? '',
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

// ─────────────────────────────────────────────────────────────────────────────

class TableInfoModel {
  final int tableId;
  final String tableNumber;
  final List<TableDelegateModel> delegates;
  final List<String> nearTables;
  final List<TableMeetingModel> meetings;

  TableInfoModel({
    required this.tableId,
    required this.tableNumber,
    required this.delegates,
    this.nearTables = const [],
    required this.meetings,
  });

  factory TableInfoModel.fromJson(Map<String, dynamic> json) {
    return TableInfoModel(
      tableId: json['table_id'] as int? ?? 0,
      tableNumber: json['table_number'] ?? '',
      delegates:
          (json['delegates'] as List?)
              ?.map(
                (e) => TableDelegateModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      nearTables:
          (json['adjacent_tables'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      meetings:
          (json['meetings'] as List?)
              ?.map(
                (e) => TableMeetingModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  TableInfo toEntity() {
    return TableInfo(
      tableId: tableId,
      tableNumber: tableNumber,
      delegates: delegates.map((d) => d.toEntity()).toList(),
      nearTables: nearTables,
      meetings: meetings.map((m) => m.toEntity()).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class TableLayoutModel {
  final String type;
  final int rows;
  final int columns;

  TableLayoutModel({
    required this.type,
    required this.rows,
    required this.columns,
  });

  factory TableLayoutModel.fromJson(Map<String, dynamic> json) {
    return TableLayoutModel(
      type: json['type'] ?? 'grid',
      rows: json['rows'] ?? 0,
      columns: json['columns'] ?? 0,
    );
  }

  TableLayout toEntity() {
    return TableLayout(type: type, rows: rows, columns: columns);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class TableViewResponseModel {
  final int year;
  final String date;
  final String time;
  final String myTable;
  final List<TableInfoModel> tables;
  final List<String> timesToday;
  final List<String> days;
  final TableLayoutModel? layout;

  TableViewResponseModel({
    required this.year,
    required this.date,
    required this.time,
    required this.myTable,
    required this.tables,
    required this.timesToday,
    required this.days,
    this.layout,
  });

  factory TableViewResponseModel.fromJson(Map<String, dynamic> json) {
    return TableViewResponseModel(
      year: json['year'] as int? ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      myTable: json['my_table'] ?? '',
      tables:
          (json['tables'] as List?)
              ?.map((e) => TableInfoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timesToday: List<String>.from(json['times_today'] ?? []),
      days: List<String>.from(json['days'] ?? []),
      layout: json['layout'] != null
          ? TableLayoutModel.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
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
      layout: layout?.toEntity(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MeetingMemberModel {
  final int id;
  final String name;
  final String? title;
  final String avatarUrl;

  MeetingMemberModel({
    required this.id,
    required this.name,
    this.title,
    required this.avatarUrl,
  });

  factory MeetingMemberModel.fromJson(Map<String, dynamic> json) {
    return MeetingMemberModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? '',
      title: json['title'],
      avatarUrl: json['avatar_url'] ?? '',
    );
  }

  MeetingMember toEntity() =>
      MeetingMember(id: id, name: name, title: title, avatarUrl: avatarUrl);
}

// ─────────────────────────────────────────────────────────────────────────────

class MeetingSideAModel {
  final int delegateId;
  final String name;
  final String? title;
  final String company;
  final String avatarUrl;

  MeetingSideAModel({
    required this.delegateId,
    required this.name,
    this.title,
    required this.company,
    required this.avatarUrl,
  });

  factory MeetingSideAModel.fromJson(Map<String, dynamic> json) {
    return MeetingSideAModel(
      delegateId: json['id'] as int? ?? 0,
      name: json['name'] ?? '',
      title: json['title'],
      company: json['company'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }

  factory MeetingSideAModel.empty() => MeetingSideAModel(
    delegateId: 0,
    name: 'Unknown',
    company: '',
    avatarUrl: '',
  );

  MeetingSideA toEntity() => MeetingSideA(
    delegateId: delegateId,
    name: name,
    title: title,
    company: company,
    avatarUrl: avatarUrl,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class MeetingSideBModel {
  final int teamId;
  final String teamName;
  final String company;
  final List<MeetingMemberModel> members;

  MeetingSideBModel({
    required this.teamId,
    required this.teamName,
    required this.company,
    required this.members,
  });

  factory MeetingSideBModel.fromJson(Map<String, dynamic> json) {
    return MeetingSideBModel(
      teamId: json['team_id'] as int? ?? 0,
      teamName: json['team_name'] ?? '',
      company: json['company'] ?? '',
      members:
          (json['members'] as List?)
              ?.map(
                (e) => MeetingMemberModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  factory MeetingSideBModel.empty() => MeetingSideBModel(
    teamId: 0,
    teamName: 'Unknown',
    company: '',
    members: [],
  );

  MeetingSideB toEntity() => MeetingSideB(
    teamId: teamId,
    teamName: teamName,
    company: company,
    members: members.map((m) => m.toEntity()).toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class TableMeetingModel {
  final int scheduleId;
  final DateTime startAt;
  final DateTime endAt;
  final MeetingSideAModel sideA;
  final MeetingSideBModel sideB;

  TableMeetingModel({
    required this.scheduleId,
    required this.startAt,
    required this.endAt,
    required this.sideA,
    required this.sideB,
  });

  factory TableMeetingModel.fromJson(Map<String, dynamic> json) {
    final booker = json['booker'] as Map<String, dynamic>?;
    final targetTeam = json['target_team'] as Map<String, dynamic>?;

    if (booker == null || targetTeam == null) {
      debugPrint(
        'TableMeetingModel: missing booker/target_team | keys: ${json.keys.toList()}',
      );
    }

    return TableMeetingModel(
      scheduleId: json['schedule_id'] as int? ?? 0,
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : DateTime.now(),
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : DateTime.now(),
      sideA: booker != null
          ? MeetingSideAModel.fromJson(booker)
          : MeetingSideAModel.empty(),
      sideB: targetTeam != null
          ? MeetingSideBModel.fromJson(targetTeam)
          : MeetingSideBModel.empty(),
    );
  }

  TableMeeting toEntity() => TableMeeting(
    scheduleId: scheduleId,
    startAt: startAt,
    endAt: endAt,
    sideA: sideA.toEntity(),
    sideB: sideB.toEntity(),
  );
}
