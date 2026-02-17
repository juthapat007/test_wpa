import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';

abstract class ScheduleOthersRepository {
  Future<List<ScheduleItem>> getScheduleOthers(int delegateId);
}
