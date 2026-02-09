import 'package:test_wpa/features/schedules/data/models/schedule_model.dart';
import 'package:test_wpa/features/schedules/data/services/schedule_api.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:dio/dio.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleApi api;

  ScheduleRepositoryImpl({required this.api});

  @override
  Future<ScheduleResponse> getSchedule({String? year, String? date}) async {
    try {
      final response = await api.getMySchedule(year: year, date: date);

      return ScheduleResponseModel.fromJson(
        response.data,
      ).toEntity(status: ScheduleStatus.success);

      // return ScheduleResponseModel.fromJson(
      //   response.data,
      // ).toEntity().copyWith(status: ScheduleStatus.success);
    } on DioException catch (e) {
      final code = e.response?.statusCode;

      if (code == 404) {
        return ScheduleResponse.empty(year: year, date: date);
      }

      if (code == 401) {
        return const ScheduleResponse(
          status: ScheduleStatus.unauthorized,
          availableYears: [],
          year: '',
          availableDates: [],
          date: '',
          schedules: [],
          message: 'Unauthorized',
        );
      }

      return const ScheduleResponse(
        status: ScheduleStatus.error,
        availableYears: [],
        year: '',
        availableDates: [],
        date: '',
        schedules: [],
        message: 'Something went wrong',
      );
    }
  }
}
