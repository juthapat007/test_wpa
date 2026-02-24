import 'dart:async';
import 'package:test_wpa/core/constants/print_logger.dart';

// ─── Event types ─────────────────────────────────────────────────────────────

enum WsEventType {
  notificationBadge, // unread count อัปเดต
  friendRequest,     // connection_request ใหม่
  requestAccepted,   // คนอื่น accept request เรา
  requestRejected,   // คนอื่น reject request เรา
  unknown,
}

class WsEvent {
  final WsEventType type;
  final Map<String, dynamic> data;
  WsEvent({required this.type, required this.data});
}

// ─── Service (Pure Event Bus — ไม่เปิด WS เอง) ────────────────────────────────
//
// ChatWebSocketService เป็นคนเปิด connection และ subscribe NotificationChannel
// แล้ว forward event มาให้ผ่าน handleIncomingEvent()
// ─────────────────────────────────────────────────────────────────────────────

class NotificationWebSocketService {
  NotificationWebSocketService._();
  static final instance = NotificationWebSocketService._();

  final _eventController = StreamController<WsEvent>.broadcast();

  Stream<WsEvent> get events => _eventController.stream;

  // ─── Entry point จาก ChatWebSocketService ──────────────────────────────────

  /// เรียกจาก ChatWebSocketService._handleActionCableDataMessage()
  /// เมื่อได้รับ type == 'new_notification'
  void handleIncomingEvent(Map<String, dynamic> message) {
    final notifType = _extractNotifType(message);
    log.i('[NotificationWS] handleIncomingEvent notif.type=$notifType');

    switch (notifType) {
      case 'connection_request':
        _emit(WsEventType.friendRequest, message);
        _emit(WsEventType.notificationBadge, message);

      case 'connection_accepted':
        _emit(WsEventType.requestAccepted, message);
        _emit(WsEventType.notificationBadge, message);

      case 'connection_rejected':
        _emit(WsEventType.requestRejected, message);
        _emit(WsEventType.notificationBadge, message);

      default:
        // schedule_reminder, announcement, etc.
        _emit(WsEventType.notificationBadge, message);
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _extractNotifType(Map<String, dynamic> message) {
    // รูปแบบ: { type: "new_notification", notification: { type: "connection_request" } }
    final notification = message['notification'];
    if (notification is Map<String, dynamic>) {
      return notification['type'] as String? ?? '';
    }
    return '';
  }

  void _emit(WsEventType type, Map<String, dynamic> data) {
    if (!_eventController.isClosed) {
      _eventController.add(WsEvent(type: type, data: data));
    }
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────────

  void dispose() {
    _eventController.close();
  }
}