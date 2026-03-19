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

// ─── Booth Owner ─────────────────────────────────────────────────────────────

class BoothOwner {
  final List<int> teamIds;
  final List<String> companies;
  final List<String> ownerTeams;

  BoothOwner({
    required this.teamIds,
    required this.companies,
    required this.ownerTeams,
  });

  String get displayName => companies.join(' & ');
}

// ─────────────────────────────────────────────────────────────────────────────

class TableInfo {
  final int tableId;
  final String tableNumber;
  final List<TableDelegate> delegates;
  final List<String> nearTables;
  final List<TableMeeting> meetings;
  final BoothOwner? boothOwner; 

  TableInfo({
    required this.tableId,
    required this.tableNumber,
    required this.delegates,
    this.nearTables = const [],
    this.meetings = const [],
    this.boothOwner,
  });

  bool get isOccupied => delegates.isNotEmpty;
  bool get isBooth => tableNumber.startsWith('Booth') || boothOwner != null;
}

// ─────────────────────────────────────────────────────────────────────────────

class TableLayout {
  final String type;
  final int rows;
  final int columns;

  TableLayout({required this.type, required this.rows, required this.columns});
}

// ─────────────────────────────────────────────────────────────────────────────

class TableViewResponse {
  final int year;
  final String date;
  final String time;
  final String myTable;
  final List<TableInfo> tables;
  final List<String> timesToday;
  final List<String> days;
  final TableLayout? layout;

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

// ─────────────────────────────────────────────────────────────────────────────

class ScheduleWithStatus {
  final Schedule schedule;
  final ScheduleStatus status;

  ScheduleWithStatus({required this.schedule, required this.status});
}

// ─────────────────────────────────────────────────────────────────────────────

class MeetingMember {
  final int id;
  final String name;
  final String? title;
  final String avatarUrl;

  MeetingMember({
    required this.id,
    required this.name,
    this.title,
    required this.avatarUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class MeetingSideA {
  final int delegateId;
  final String name;
  final String? title;
  final String company;
  final String avatarUrl;

  MeetingSideA({
    required this.delegateId,
    required this.name,
    this.title,
    required this.company,
    required this.avatarUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class MeetingSideB {
  final int teamId;
  final String teamName;
  final String company;
  final List<MeetingMember> members;

  MeetingSideB({
    required this.teamId,
    required this.teamName,
    required this.company,
    required this.members,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

enum MeetingRole { ownerHosting, ownerAsTarget, ownerInternal, normal }

class TableMeeting {
  final int scheduleId;
  final DateTime startAt;
  final DateTime endAt;
  final MeetingSideA sideA;
  final MeetingSideB sideB;
  final MeetingRole meetingRole;
  final bool bookerIsOwner;
  final bool targetIsOwner;
  final String? ownerCompany;
  final String? guestCompany;

  TableMeeting({
    required this.scheduleId,
    required this.startAt,
    required this.endAt,
    required this.sideA,
    required this.sideB,
    this.meetingRole = MeetingRole.normal,
    this.bookerIsOwner = false,
    this.targetIsOwner = false,
    this.ownerCompany,
    this.guestCompany,
  });

  String get hostLabel {
    switch (meetingRole) {
      case MeetingRole.ownerHosting:
        return 'Host';
      case MeetingRole.ownerAsTarget:
        return 'Owner';
      default:
        return 'Booker';
    }
  }

  String get guestLabel {
    switch (meetingRole) {
      case MeetingRole.ownerHosting:
        return 'Guest';
      case MeetingRole.ownerAsTarget:
        return 'Visitor';
      default:
        return 'Team';
    }
  }
}
