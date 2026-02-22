// lib/features/meeting/data/services/table_api.dart

import 'package:dio/dio.dart';

class TableApi {
  final Dio dio;

  TableApi(this.dio);

  Future<Map<String, dynamic>> getTableView({
    String? date,
    String? time,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (date != null) queryParams['date'] = date;
      if (time != null) queryParams['time'] = time;

      final response = await dio.get(
        '/tables/time_view',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      // print('✅ Table API Response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print(' TableApi error: $e');
      rethrow;
    }
  }

  // Future<Map<String, dynamic>> getTeamSchedules({
  //   required String date,
  //   String? time, // ✅ เพิ่ม
  //   int page = 1,
  // }) async {
  //   final response = await dio.get(
  //     '/schedules',
  //     queryParameters: {
  //       'date': date,
  //       if (time != null) 'time': time, // ✅ ส่งเฉพาะถ้ามีค่า
  //       'page': page,
  //       'per_page': 20,
  //     },
  //   );
  //   return response.data as Map<String, dynamic>;
  // }
}
