import 'package:dio/dio.dart';

class ScheduleOthersApi {
  final Dio dio;

  ScheduleOthersApi({required this.dio});

  /// GET /api/v1/schedules/schedule_others?delegate_id=:id&date=:date
  Future<Map<String, dynamic>> getScheduleOthers(
    int delegateId, {
    String? date,
  }) async {
    final params = <String, dynamic>{'delegate_id': delegateId};
    if (date != null && date.isNotEmpty) params['date'] = date;

    final response = await dio.get(
      '/schedules/schedule_others',
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }
}
