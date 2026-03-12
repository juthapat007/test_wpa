import 'package:dio/dio.dart';

class ConnectionApi {
  final Dio dio;

  ConnectionApi(this.dio);

  /// GET /api/v1/requests/my_received
  Future<List<dynamic>> getReceivedRequests() async {
    final response = await dio.get('/requests/my_received');
    return response.data as List<dynamic>;
  }

  ///    ให้แจ้งทีม backend เพิ่ม GET /api/v1/connections
  Future<List<dynamic>> getFriends() async {
    final response = await dio.get('/connections');
    return response.data as List<dynamic>;
  }

  /// POST /api/v1/requests
  Future<Response> sendConnectionRequest(int targetId) async {
    try {
      final response = await dio.post(
        '/requests',
        data: {'target_id': targetId},
      );
      return response;
    } catch (e) {
      print(' ConnectionApi.sendRequest error: $e');
      rethrow;
    }
  }

  /// PATCH /api/v1/requests/:id/accept
  Future<Response> acceptRequest(int requestId) async {
    final response = await dio.patch('/requests/$requestId/accept');
    return response;
  }

  /// PATCH /api/v1/requests/:id/reject
  Future<Response> rejectRequest(int requestId) async {
    final response = await dio.patch('/requests/$requestId/reject');
    return response;
  }

  /// DELETE /api/v1/requests/:target_id/cancel
  Future<void> cancelRequest(int requestId) async {
    try {
      await dio.delete('/requests/$requestId/cancel');
    } catch (e) {
      print('ConnectionApi.cancelRequest error: $e');
      rethrow;
    }
  }

  /// DELETE /api/v1/connections/:delegate_id
  Future<void> unfriend(int delegateId) async {
    try {
      await dio.delete('/networking/unfriend/$delegateId');
    } catch (e) {
      print(' ConnectionApi.unfriend error: $e');
      rethrow;
    }
  }
}
