import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/domain/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository})
    : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<MarkNotificationRead>(_onMarkRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final notifications = await notificationRepository.getNotifications(
        type: event.type,
      );
      final unreadCount = await notificationRepository.getUnreadCount();
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await notificationRepository.getUnreadCount();
      final currentState = state;
      if (currentState is NotificationLoaded) {
        emit(
          NotificationLoaded(
            notifications: currentState.notifications,
            unreadCount: count,
          ),
        );
      } else {
        emit(UnreadCountLoaded(count));
      }
    } catch (_) {
      // Silently fail for badge count
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.markAllAsRead(type: event.type);
      final currentState = state;
      if (currentState is NotificationLoaded) {
        final updatedNotifications = currentState.notifications.map((n) {
          return NotificationItem(
            id: n.id,
            type: n.type,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
            isUnread: false,
            notifiable: n.notifiable,
          );
        }).toList();
        emit(
          NotificationLoaded(
            notifications: updatedNotifications,
            unreadCount: 0,
          ),
        );
      }
    } catch (e) {
      emit(NotificationError('Failed to mark all as read: $e'));
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.markAsRead(event.id);
      final currentState = state;
      if (currentState is NotificationLoaded) {
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == event.id) {
            return NotificationItem(
              id: n.id,
              type: n.type,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
              isUnread: false,
              notifiable: n.notifiable,
            );
          }
          return n;
        }).toList();
        final newUnread = updatedNotifications.where((n) => n.isUnread).length;
        emit(
          NotificationLoaded(
            notifications: updatedNotifications,
            unreadCount: newUnread,
          ),
        );
      }
    } catch (e) {
      emit(NotificationError('Failed to mark as read: $e'));
    }
  }
}
