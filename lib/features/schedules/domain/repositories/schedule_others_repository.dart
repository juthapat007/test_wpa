import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule_others_response.dart';

// abstract class ScheduleOthersRepository {
//   Future<List<Schedule>> getScheduleOthers(int delegateId);
// }
abstract class ScheduleOthersRepository {
  /// GET /api/v1/schedules/schedule_others?delegate_id=:id&date=:date
  /// date เป็น optional — ถ้าไม่ส่ง backend จะ default วันแรก
  Future<ScheduleOthersResponse> getScheduleOthers(
    int delegateId, {
    String? date,
  });
}
