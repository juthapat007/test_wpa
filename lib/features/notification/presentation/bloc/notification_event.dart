part of 'notification_bloc.dart';

@immutable
sealed class NotificationEvent {}

class LoadNotifications extends NotificationEvent {}

class LoadUnreadCount extends NotificationEvent {}

class MarkAllNotificationsRead extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final int id;
  MarkNotificationRead(this.id);
}
