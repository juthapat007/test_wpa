import 'package:dio/dio.dart';

class ScheduleApi {
  final Dio dio;
  ScheduleApi(this.dio);

  // 🔧 เอา year params ออกเพราะ backend fix ปีไว้ที่ 2025 แล้ว
  Future<Response> getMySchedule({String? date}) {
    return dio.get(
      '/schedules/my_schedule',
      queryParameters: {'date': ?date},
    );
  }
}
