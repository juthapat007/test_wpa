import 'package:dio/dio.dart';

class ConnectionApi {
  final Dio dio;

  ConnectionApi(this.dio);

  /// GET /api/v1/requests/my_received - ดึงคำขอเชื่อมต่อที่ได้รับ
  Future<List<dynamic>> getReceivedRequests() async {
    final response = await dio.get('/requests/my_received');
    return response.data as List<dynamic>;
  }

  /// PATCH /api/v1/requests/:id/accept - ยอมรับคำขอเชื่อมต่อ
  Future<Map<String, dynamic>> acceptRequest(int id) async {
    final response = await dio.patch('/requests/$id/accept');
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /api/v1/requests/:id/reject - ปฏิเสธคำขอเชื่อมต่อ
  Future<Map<String, dynamic>> rejectRequest(int id) async {
    final response = await dio.patch('/requests/$id/reject');
    return response.data as Map<String, dynamic>;
  }

  // Future<Response> sendConnectionRequest(int delegateId) async {
  //   try {
  //     final response = await dio.post('/connections/requests/$delegateId');
  //     return response;
  //   } catch (e) {
  //     print('❌ ConnectionApi.sendConnectionRequest error: $e');
  //     rethrow;
  //   }
  // }
  Future<Response> sendConnectionRequest(int delegateId) async {
    try {
      final response = await dio.post(
        '/requests',
        data: {'target_id': delegateId},
      );
      return response;
    } catch (e) {
      print('❌ ConnectionApi.sendConnectionRequest error: $e');
      rethrow;
    }
  }
}
