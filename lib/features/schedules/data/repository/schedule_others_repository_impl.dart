import 'package:test_wpa/features/schedules/data/models/schedule_model.dart';
import 'package:test_wpa/features/schedules/data/services/schedule_others_api.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_others_repository.dart';

class ScheduleOthersRepositoryImpl implements ScheduleOthersRepository {
  final ScheduleOthersApi api;

  ScheduleOthersRepositoryImpl({required this.api});

  @override
  Future<List<Schedule>> getScheduleOthers(int delegateId) async {
    try {
      final jsonList = await api.getScheduleOthers(delegateId);
      return jsonList
          .map((json) => ScheduleModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      print('❌ ScheduleOthersRepositoryImpl error: $e');
      throw Exception('Failed to get schedule: $e');
    }
  }
}
