import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/core/services/notification_websocket_service.dart';
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/domain/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;
  StreamSubscription<WsEvent>? _wsSubscription;

  NotificationBloc({required this.notificationRepository})
    : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<MarkNotificationRead>(_onMarkRead);
    on<WsNotificationReceived>(_onWsReceived);

    _listenToWebSocket();
  }

  // ─── WebSocket listener ────────────────────────────────────────────────────

  void _listenToWebSocket() {
    _wsSubscription = NotificationWebSocketService.instance.events.listen((
      event,
    ) {
      switch (event.type) {
        case WsEventType.notificationBadge:
        case WsEventType.friendRequest:
        case WsEventType.requestAccepted:
        case WsEventType.requestRejected:
          add(WsNotificationReceived(event));
        case WsEventType.unknown:
          break;
      }
    });
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onWsReceived(
    WsNotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notifications = await notificationRepository.getNotifications();
      final systemUnread = notifications
          .where((n) => n.isUnread && !_excludeFromBadge.contains(n.type))
          .length;
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: systemUnread,
        ),
      );
    } catch (_) {}
  }

  static const _excludeFromBadge = {
    'connection_request',
    'connection_accepted',
    'connection_rejected',
    'new_message',
  };
  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final notifications = await notificationRepository.getNotifications();

      final systemUnread = notifications
          .where((n) => n.isUnread && !_excludeFromBadge.contains(n.type))
          .length;

      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: systemUnread,
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
      final count = await notificationRepository.getUnreadCount(type: 'system');
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
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.markAllAsRead(type: event.type);
      final notifications = await notificationRepository.getNotifications();
      final systemUnread = notifications
          .where((n) => n.isUnread && !_excludeFromBadge.contains(n.type))
          .length;

      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: systemUnread,
        ),
      );
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
        final updated = currentState.notifications.map((n) {
          if (n.id != event.id) return n;
          return NotificationItem(
            id: n.id,
            type: n.type,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
            isUnread: false,
            notifiable: n.notifiable,
          );
        }).toList();

        final freshCount = updated
            .where((n) => n.isUnread && !_excludeFromBadge.contains(n.type))
            .length;

        emit(
          NotificationLoaded(notifications: updated, unreadCount: freshCount),
        );
      }
    } catch (e) {
      print('⚠️ markAsRead failed: $e');
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
