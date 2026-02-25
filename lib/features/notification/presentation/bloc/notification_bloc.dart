import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/core/services/notification_websocket_service.dart';
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/domain/repositories/notification_repository.dart';
import 'package:test_wpa/core/services/notification_websocket_service.dart';

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
    on<WsNotificationReceived>(_onWsReceived); // ✅ ใหม่

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
    // reload unread count จาก server เพื่อให้ badge อัปเดต
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
      // silently fail — badge จะยังแสดงค่าเดิม
    }
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
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.markAllAsRead(type: event.type);

      final notifications = await notificationRepository.getNotifications(
        type: 'system',
      );
      final freshCount = await notificationRepository.getUnreadCount();

      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: freshCount,
        ),
      );
    } catch (e) {
      emit(NotificationError('Failed to mark all as read: $e'));
    }
  }

  // ✅ แก้ _onMarkRead — หลัง mark แล้ว refetch count จาก server
  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.markAsRead(event.id);

      // ✅ Refetch count จาก server
      final freshCount = await notificationRepository.getUnreadCount();

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
        emit(
          NotificationLoaded(
            notifications: updatedNotifications,
            unreadCount: freshCount, // ✅ ใช้ค่าจาก server
          ),
        );
      }
    } catch (e) {
      emit(NotificationError('Failed to mark as read: $e'));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
