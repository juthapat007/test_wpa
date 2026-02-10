// enum ScheduleStatus { success, empty, unauthorized, error }
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';

enum ScheduleStatus {
  past,
  now,
  next,
  upcoming,
  empty,
  success,
  unauthorized,
  error,
}

enum EventCardType { meeting, empty, breakTime }

enum ScheduleCardStatus { leave, event, free, passed, ongoing, upcoming }
