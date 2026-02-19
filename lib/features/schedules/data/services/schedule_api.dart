import 'package:dio/dio.dart';

class ScheduleApi {
  final Dio dio;
  ScheduleApi(this.dio);

  // 🔧 เอา year params ออกเพราะ backend fix ปีไว้ที่ 2025 แล้ว
  Future<Response> getMySchedule({String? date}) {
    return dio.get('/schedules/my_schedule', queryParameters: {'date': date});
  }

  /// ดึงรายการประเภทการลา
  /// GET /api/v1/leave_types
  Future<Response> getLeaveTypes() {
    return dio.get('/leave_types');
  }

  /// ดึงข้อมูล leave type ตาม ID
  /// GET /api/v1/leave_types/{id}
  Future<Response> getLeaveTypeById(int id) {
    return dio.get('/leave_types/$id');
  }

  // ส่งข้อมูลการแจ้งลา
  // Future<Response> submitLeaveForms(Map<String, dynamic> data) {
  //   return dio.post('/leave_forms', data: {'leave_form': data});
  // }
  // Future<Response> submitLeaveForms(List<Map<String, dynamic>> leaves) {
  //   return dio.post(
  //     '/leave_forms',
  //     data: {
  //       'leave_form': {
  //         'leaves': leaves, // ✅ array ข้างใน
  //       },
  //     },
  //   );
  // }
  Future<Response> submitLeaveForms(Map<String, dynamic> data) {
    return dio.post(
      '/leave_forms',
      data: {
        'leave_form': {
          'leaves': data['leaves'], // ✅ ดึง leaves array จาก map
        },
      },
    );
  }
}
