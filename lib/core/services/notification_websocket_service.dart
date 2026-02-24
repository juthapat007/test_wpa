import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

// ─── Event types ─────────────────────────────────────────────────────────────

enum WsEventType {
  friendRequest, // มีคนส่ง friend request มา
  requestAccepted, // request ถูก accept
  requestRejected, // request ถูก reject
  notificationBadge, // unread count เปลี่ยน
  unknown,
}

class WsEvent {
  final WsEventType type;
  final Map<String, dynamic> data;

  WsEvent(this.type, this.data);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class NotificationWebSocketService {
  NotificationWebSocketService._();
  static final NotificationWebSocketService instance =
      NotificationWebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _disposed = false;
  bool _subscribed = false;
  String? _token;

  static const _wsBase = 'wss://wpa-docker.onrender.com/cable';
  static const _channelName = 'NotificationChannel';
  static const _reconnectDelay = Duration(seconds: 5);
  static const _pingInterval = Duration(seconds: 30);

  // Stream ที่ Bloc ต่างๆ จะ listen
  final _eventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get events => _eventController.stream;

  // ─── Public API ────────────────────────────────────────────────────────────

  void connect(String token) {
    _token = token;
    _disposed = false;
    _log('Connecting...');
    _connect();
  }

  void disconnect() {
    _disposed = true;
    _log('Disconnecting...');
    _cleanup();
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  void _connect() {
    if (_disposed) return;
    _cleanup(keepToken: true);

    final url = '$_wsBase?token=$_token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _subscribed = false;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _startPing();
      _log('WebSocket connected');
    } catch (e) {
      _log('Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    _log('← $raw');

    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = json['type'] as String?;

    // ActionCable protocol messages
    if (type == 'welcome') {
      _log('Welcome received, subscribing...');
      _subscribe();
      return;
    }

    if (type == 'confirm_subscription') {
      _subscribed = true;
      _log('Subscribed to $_channelName ✓');
      return;
    }

    if (type == 'ping') return; // ignore heartbeat

    if (type == 'reject_subscription') {
      _log('Subscription rejected — token may be invalid');
      return;
    }

    // Data messages from the channel
    final message = json['message'] as Map<String, dynamic>?;
    if (message == null) return;

    _parseAndEmit(message);
  }

  void _parseAndEmit(Map<String, dynamic> message) {
    final eventType = message['type'] as String? ?? '';
    _log('Event: $eventType → $message');

    final wsEventType = switch (eventType) {
      'friend_request' => WsEventType.friendRequest,
      'request_accepted' => WsEventType.requestAccepted,
      'request_rejected' => WsEventType.requestRejected,
      'notification_badge' => WsEventType.notificationBadge,
      _ => WsEventType.unknown,
    };

    _eventController.add(WsEvent(wsEventType, message));
  }

  void _subscribe() {
    final identifier = jsonEncode({'channel': _channelName});
    final command = jsonEncode({
      'command': 'subscribe',
      'identifier': identifier,
    });
    _send(command);
  }

  void _send(String message) {
    _log('→ $message');
    try {
      _channel?.sink.add(message);
    } catch (e) {
      _log('Send failed: $e');
    }
  }

  void _onError(dynamic error) {
    _log('Error: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    _log('Connection closed');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _log('Reconnecting in ${_reconnectDelay.inSeconds}s...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, _connect);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_subscribed) {
        final identifier = jsonEncode({'channel': _channelName});
        final ping = jsonEncode({
          'command': 'message',
          'identifier': identifier,
          'data': jsonEncode({'action': 'ping'}),
        });
        _send(ping);
      }
    });
  }

  void _cleanup({bool keepToken = false}) {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscribed = false;
    if (!keepToken) _token = null;
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[WS] $message');
  }
}
