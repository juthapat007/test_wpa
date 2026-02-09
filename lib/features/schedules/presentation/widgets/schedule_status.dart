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

class ScheduleWithStatus {
  final Schedule schedule;
  final ScheduleStatus status;

  ScheduleWithStatus(this.schedule, this.status);
}

List<ScheduleWithStatus> getSchedulesWithStatus(List<Schedule> schedules) {
  final now = DateTime.now();
  final result = <ScheduleWithStatus>[];

  Schedule? nextFound;

  for (var schedule in schedules) {
    ScheduleStatus status;

    if (now.isBefore(schedule.startAt)) {
      // ยังไม่ถึง
      if (nextFound == null) {
        status = ScheduleStatus.next; // ตัวถัดไปที่จะเจอ
        nextFound = schedule;
      } else {
        status = ScheduleStatus.upcoming;
      }
    } else if (now.isAfter(schedule.endAt)) {
      // ผ่านไปแล้ว
      status = ScheduleStatus.past;
    } else {
      // กำลังเกิดขึ้น (now)
      status = ScheduleStatus.now;
    }

    result.add(ScheduleWithStatus(schedule, status));
  }

  return result;
}
