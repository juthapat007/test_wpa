import 'package:test_wpa/features/notification/data/models/notification_model.dart';
import 'package:test_wpa/features/notification/data/services/notification_api.dart';
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApi api;

  NotificationRepositoryImpl({required this.api});

  @override
  Future<List<NotificationItem>> getNotifications({String? type}) async {
    try {
      final data = await api.getNotifications(type: type);
      return data
          .map(
            (json) => NotificationItemModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final data = await api.getUnreadCount();
      return data['unread_count'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> markAllAsRead({String? type}) async {
    try {
      await api.markAllAsRead(type: type);
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      await api.markAsRead(id);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}
