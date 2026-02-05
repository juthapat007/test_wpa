import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';

abstract class ScheduleRepository {
  Future<ScheduleResponse> getSchedule({String? year, String? date});
}
