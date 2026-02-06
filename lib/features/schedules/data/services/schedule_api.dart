import 'package:dio/dio.dart';
import 'package:test_wpa/features/schedules/data/models/schedule_model.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class ScheduleApi {
  final Dio dio;
  ScheduleApi(this.dio);

  Future<Response> getMySchedule({String? year, String? date}) {
    return dio.get(
      '/schedules/my_schedule',
      queryParameters: {
        if (year != null) 'year': year,
        if (date != null) 'date': date,
      },
    );
  }
}
