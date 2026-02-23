import 'package:dio/dio.dart';

class ScheduleOthersApi {
  final Dio dio;

  ScheduleOthersApi({required this.dio});

  // Future<List<Map<String, dynamic>>> getScheduleOthers(int delegateId) async {
  //   try {
  //     final response = await dio.get(
  //       '/schedules/schedule_others',
  //       queryParameters: {'delegate_id': delegateId},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = response.data;
  //       if (data is List) {
  //         return List<Map<String, dynamic>>.from(data);
  //       } else if (data is Map && data['schedules'] != null) {
  //         return List<Map<String, dynamic>>.from(data['schedules']);
  //       }
  //       return [];
  //     } else {
  //       throw Exception('Failed to fetch schedule: ${response.statusCode}');
  //     }
  //   } on DioException catch (e) {
  //     print('❌ ScheduleOthersApi error: ${e.message}');
  //     rethrow;
  //   }
  // }

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
