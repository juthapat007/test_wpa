import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';

abstract class ScheduleOthersRepository {
  Future<List<Schedule>> getScheduleOthers(int delegateId);
}
