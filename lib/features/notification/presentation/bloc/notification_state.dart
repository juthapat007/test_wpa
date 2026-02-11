part of 'notification_bloc.dart';

@immutable
sealed class NotificationState {}

final class NotificationInitial extends NotificationState {}

final class NotificationLoading extends NotificationState {}

final class NotificationLoaded extends NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;

  NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });
}

final class UnreadCountLoaded extends NotificationState {
  final int count;
  UnreadCountLoaded(this.count);
}

final class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}
