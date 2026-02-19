// lib/features/notification/data/services/connection_api.dart

import 'package:dio/dio.dart';

class ConnectionApi {
  final Dio dio;

  ConnectionApi(this.dio);

  /// GET /api/v1/requests/my_received
  Future<List<dynamic>> getReceivedRequests() async {
    final response = await dio.get('/requests/my_received');
    return response.data as List<dynamic>;
  }

  /// POST /api/v1/requests — ส่ง friend request
  Future<Response> sendConnectionRequest(int targetId) async {
    try {
      final response = await dio.post(
        '/requests',
        data: {'target_id': targetId},
      );
      return response;
    } catch (e) {
      print('❌ ConnectionApi.sendConnectionRequest error: $e');
      rethrow;
    }
  }

  /// PATCH /api/v1/requests/:id/accept — ยอมรับคำขอ
  Future<Map<String, dynamic>> acceptRequest(int id) async {
    final response = await dio.patch('/requests/$id/accept');
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /api/v1/requests/:id/reject — ปฏิเสธคำขอ (status กลับเป็น none)
  Future<Map<String, dynamic>> rejectRequest(int id) async {
    final response = await dio.patch('/requests/$id/reject');
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /api/v1/connections/:delegateId — ยกเลิกเพื่อน (unfriend)
  Future<void> unfriend(int delegateId) async {
    try {
      await dio.delete('/networking/unfriend/$delegateId');
    } catch (e) {
      print('❌ ConnectionApi.unfriend error: $e');
      rethrow;
    }
  }
}
