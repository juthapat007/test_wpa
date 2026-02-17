

import 'package:test_wpa/features/schedules/data/services/schedule_others_api.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_others_repository.dart';
import 'package:test_wpa/features/schedules/data/models/schedule_item_model.dart';
class ScheduleOthersRepositoryImpl implements ScheduleOthersRepository {
  final ScheduleOthersApi api;

  ScheduleOthersRepositoryImpl({required this.api});

  @override
  Future<List<ScheduleItem>> getScheduleOthers(int delegateId) async {
    try {
      final jsonList = await api.getScheduleOthers(delegateId);
      return jsonList
          .map((json) => ScheduleItemModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      print('❌ ScheduleOthersRepositoryImpl error: $e');
      throw Exception('Failed to get schedule: $e');
    }
  }
}