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
        // ✅ ดักทุก event ที่เกี่ยวกับ notification
        case WsEventType.notificationBadge: // admin / system push
        case WsEventType.friendRequest: // มีคน add เรา
        case WsEventType.requestAccepted: // คนรับ add ของเรา
        case WsEventType.requestRejected: // คนปฏิเสธ add ของเรา
          add(WsNotificationReceived(event));
        case WsEventType.unknown:
          break;
      }
    });
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  /// ✅ WS event → reload ทั้ง list + count (ไม่ใช่แค่ count)
  Future<void> _onWsReceived(
    WsNotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final results = await Future.wait([
        notificationRepository.getNotifications(type: 'system'),
        notificationRepository.getUnreadCount(),
      ]);
      emit(
        NotificationLoaded(
          notifications: results[0] as List<NotificationItem>,
          unreadCount: results[1] as int,
        ),
      );
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
      final results = await Future.wait([
        notificationRepository.getNotifications(type: event.type),
        notificationRepository.getUnreadCount(),
      ]);
      emit(
        NotificationLoaded(
          notifications: results[0] as List<NotificationItem>,
          unreadCount: results[1] as int,
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
      final results = await Future.wait([
        notificationRepository.getNotifications(type: 'system'),
        notificationRepository.getUnreadCount(),
      ]);
      emit(
        NotificationLoaded(
          notifications: results[0] as List<NotificationItem>,
          unreadCount: results[1] as int,
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
      final freshCount = await notificationRepository.getUnreadCount();
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
        emit(
          NotificationLoaded(notifications: updated, unreadCount: freshCount),
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
