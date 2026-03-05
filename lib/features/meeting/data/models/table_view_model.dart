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
      // delegateId: json['delegate_id'],
      // delegateName: json['delegate_name'] ?? '',
      delegateId: json['id'],
      delegateName: json['name'],
      company: json['company'],
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
      tableId: json['table_id'],
      tableNumber: json['table_number'] ?? '',
      delegates:
          (json['delegates'] as List?)
              ?.map((e) => TableDelegateModel.fromJson(e))
              .toList() ??
          [],
      nearTables:
          (json['adjacent_tables'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      meetings:
          (json['meetings'] as List?)
              ?.map((e) => TableMeetingModel.fromJson(e))
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
      layout: json['layout'] != null
          ? TableLayoutModel.fromJson(json['layout'])
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
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'],
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
  MeetingMember toEntity() =>
      MeetingMember(id: id, name: name, title: title, avatarUrl: avatarUrl);
}

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
      // delegateId: json['delegate_id'],
      delegateId: json['id'],
      name: json['name'] ?? '',
      title: json['title'],
      company: json['company'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }

  MeetingSideA toEntity() => MeetingSideA(
    delegateId: delegateId,
    name: name,
    title: title,
    company: company,
    avatarUrl: avatarUrl,
  );
}

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
      teamId: json['team_id'],
      teamName: json['team_name'] ?? '',
      company: json['company'] ?? '',
      members:
          (json['members'] as List?)
              ?.map((e) => MeetingMemberModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  MeetingSideB toEntity() => MeetingSideB(
    teamId: teamId,
    teamName: teamName,
    company: company,
    members: members.map((m) => m.toEntity()).toList(),
  );
}

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
    return TableMeetingModel(
      scheduleId: json['schedule_id'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      // sideA: MeetingSideAModel.fromJson(json['side_a']),
      // sideB: MeetingSideBModel.fromJson(json['side_b']),
      sideA: MeetingSideAModel.fromJson(json['booker']),
      sideB: MeetingSideBModel.fromJson(json['target_team']),
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
