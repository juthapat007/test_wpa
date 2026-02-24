part of 'notification_bloc.dart';

@immutable
sealed class NotificationEvent {}

class LoadNotifications extends NotificationEvent {
  final String? type; // 'system' or null for all
  LoadNotifications({this.type});
}

class LoadUnreadCount extends NotificationEvent {}

class MarkAllNotificationsRead extends NotificationEvent {
  final String? type; // 'system' or null for all
  MarkAllNotificationsRead({this.type});
}

class MarkNotificationRead extends NotificationEvent {
  final int id;
  MarkNotificationRead(this.id);
}

class WsNotificationReceived extends NotificationEvent {
  final WsEvent event;
  WsNotificationReceived(this.event);
}
