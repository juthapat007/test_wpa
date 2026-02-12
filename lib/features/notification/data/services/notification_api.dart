import 'package:dio/dio.dart';

class NotificationApi {
  final Dio dio;

  NotificationApi(this.dio);

  /// GET /api/v1/notifications
  Future<List<dynamic>> getNotifications() async {
    final response = await dio.get('/notifications');
    return response.data as List<dynamic>;
  }

  /// GET /api/v1/notifications/unread_count
  Future<Map<String, dynamic>> getUnreadCount() async {
    final response = await dio.get('/notifications/unread_count');
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /api/v1/notifications/mark_all_as_read
  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await dio.patch('/notifications/mark_all_as_read');
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /api/v1/notifications/:id/mark_as_read
  Future<Map<String, dynamic>> markAsRead(int id) async {
    final response = await dio.patch('/notifications/$id/mark_as_read');
    return response.data as Map<String, dynamic>;
  }
}
