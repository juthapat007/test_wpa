import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationItem>> getNotifications({String? type});
  Future<int> getUnreadCount();
  Future<void> markAllAsRead({String? type});
  Future<void> markAsRead(int id);
}
