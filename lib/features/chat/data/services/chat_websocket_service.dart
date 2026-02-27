import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:test_wpa/core/constants/print_logger.dart';
import 'package:test_wpa/core/services/notification_websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart'
    show TypingEvent;

class ReadReceiptEvent {
  final String messageId;
  final DateTime readAt;
  ReadReceiptEvent({required this.messageId, required this.readAt});
}

class MessageDeletedEvent {
  final String messageId;
  MessageDeletedEvent({required this.messageId});
}

class MessageUpdatedEvent {
  final String messageId;
  final String content;
  final DateTime editedAt;
  MessageUpdatedEvent({
    required this.messageId,
    required this.content,
    required this.editedAt,
  });
}

class ChatWebSocketService with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _readReceiptController = StreamController<ReadReceiptEvent>.broadcast();
  final _messageDeletedController =
      StreamController<MessageDeletedEvent>.broadcast();
  final _messageUpdatedController =
      StreamController<MessageUpdatedEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ✅ เพิ่ม: ติดตามว่าแอพอยู่ foreground หรือเปล่า
  bool _isAppInForeground = true;

  String? _chatChannelIdentifier;
  String? _notificationChannelIdentifier;

  String? _lastToken;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  Timer? _reconnectTimer;

  //  Heartbeat — ส่ง ping ทุก 25 วิ ป้องกัน proxy ตัด connection
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 25);

  //  Watchdog — ถ้าไม่ได้รับ ping จาก server นานกว่า 65 วิ = connection ตายแล้ว
  Timer? _watchdogTimer;
  static const Duration _watchdogTimeout = Duration(seconds: 65);
  DateTime? _lastPingReceived;

  // ✅ ลงทะเบียน lifecycle observer ตอน constructor
  ChatWebSocketService() {
    WidgetsBinding.instance.addObserver(this);
  }

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<ReadReceiptEvent> get readReceiptStream =>
      _readReceiptController.stream;
  Stream<MessageDeletedEvent> get messageDeletedStream =>
      _messageDeletedController.stream;
  Stream<MessageUpdatedEvent> get messageUpdatedStream =>
      _messageUpdatedController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;

  // ─── AppLifecycle ─────────────────────────────────────────────────────────
  //
  // ✅ จุดสำคัญ: ป้องกัน reconnect ตอน FCM ปลุกแอพ background

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // user เปิดแอพจริงๆ → reconnect ได้
        _isAppInForeground = true;
        log.i('[Lifecycle] App resumed → foreground');
        if (!_isConnected && _lastToken != null) {
          _reconnectAttempts = 0;
          connect(_lastToken!);
        }

      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // แอพเข้า background (รวมถึงตอน FCM ปลุก) → หยุด timer ทั้งหมด
        _isAppInForeground = false;
        log.i('[Lifecycle] App backgrounded → cancel timers');
        _cancelTimers();
        _reconnectTimer?.cancel();

      default:
        break;
    }
  }

  // ─── Connect ─────────────────────────────────────────────────────────────

  Future<void> connect(String token) async {
    if (_isConnected && _channel != null) {
      log.i('WebSocket already connected, skipping reconnect');
      return;
    }
    _lastToken = token;
    _reconnectAttempts = 0;
    _cancelTimers();

    try {
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
      final wsUrl = 'wss://wpa-docker.onrender.com/cable?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          log.e('WebSocket error', error: error);
          _onDisconnected();
        },
        onDone: () {
          log.w('WebSocket disconnected');
          _onDisconnected();
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      log.i('WebSocket connected ✅');

      await Future.delayed(const Duration(milliseconds: 500));
      await _subscribeChannels();

      _startHeartbeat();
      _startWatchdog();
    } catch (e) {
      log.e('Failed to connect WebSocket', error: e);
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
    _cancelTimers();
    _scheduleReconnect();
  }

  // ─── Heartbeat ────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (!_isConnected || _channel == null) return;
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
        log.v('[Heartbeat] ping sent');
      } catch (e) {
        log.w('[Heartbeat] failed to send ping: $e');
        _onDisconnected();
      }
    });
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _lastPingReceived = DateTime.now();
    _watchdogTimer = Timer.periodic(_watchdogTimeout, (_) {
      if (_lastPingReceived == null) return;
      final elapsed = DateTime.now().difference(_lastPingReceived!);
      if (elapsed > _watchdogTimeout) {
        log.w(
          '[Watchdog] No ping from server for ${elapsed.inSeconds}s → reconnecting',
        );
        _onDisconnected();
      }
    });
  }

  void _cancelTimers() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  // ─── Reconnect ────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    if (_lastToken == null || _reconnectAttempts >= _maxReconnectAttempts) {
      log.w('Max reconnect attempts reached');
      return;
    }

    // ✅ ถ้าอยู่ background → ไม่ schedule เลย รอ resumed แทน
    if (!_isAppInForeground) {
      log.i('[Reconnect] App in background → skip, will reconnect on resume');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(2, 30));
    log.i('Reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      // ✅ เช็คซ้ำตอน Timer ยิง เผื่อแอพ background ไปแล้วระหว่างรอ
      if (!_isConnected && _lastToken != null && _isAppInForeground) {
        connect(_lastToken!);
      }
    });
  }

  // ─── Subscribe ────────────────────────────────────────────────────────────

  Future<void> _subscribeChannels() async {
    _chatChannelIdentifier = jsonEncode({'channel': 'ChatChannel'});
    _sendCommand('subscribe', _chatChannelIdentifier!);
    log.i('Subscribed to ChatChannel');
    await Future.delayed(const Duration(milliseconds: 300));

    _notificationChannelIdentifier = jsonEncode({
      'channel': 'NotificationChannel',
    });
    _sendCommand('subscribe', _notificationChannelIdentifier!);
    log.i('Subscribed to NotificationChannel');
  }

  void _sendCommand(
    String command,
    String identifier, {
    Map<String, dynamic>? data,
  }) {
    if (_channel == null) return;
    final message = {
      'command': command,
      'identifier': identifier,
      if (data != null) 'data': jsonEncode(data),
    };
    _channel!.sink.add(jsonEncode(message));
  }

  // ─── Handle incoming messages ─────────────────────────────────────────────

  void _handleMessage(dynamic rawData) {
    try {
      final data = jsonDecode(rawData.toString());
      final type = data['type'] as String?;

      switch (type) {
        case 'welcome':
          log.d('WebSocket welcome received');
          break;

        case 'ping':
          _lastPingReceived = DateTime.now();
          break;

        case 'confirm_subscription':
          log.d('Subscription confirmed: ${data['identifier']}');
          break;

        case 'disconnect':
          log.w('WebSocket disconnect by server');
          _onDisconnected();
          break;

        default:
          if (data['message'] != null && data['message'] is Map) {
            _handleActionCableDataMessage(
              Map<String, dynamic>.from(data['message'] as Map),
            );
          } else if (type != null) {
            log.w('Unknown system type: $type');
          }
      }
    } catch (e) {
      log.e('Error parsing WebSocket message', error: e);
    }
  }

  void _handleActionCableDataMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    if (type == 'new_notification') {
      log.i('[ChatWS] → NotificationWS: ${message['notification']?['type']}');
      NotificationWebSocketService.instance.handleIncomingEvent(message);
      return;
    }

    log.i('[Data Message] type=$type');

    switch (type) {
      case 'new_message':
        final msgData = message['message'];
        _handleNewMessage(msgData is Map<String, dynamic> ? msgData : message);

      case 'message_read':
        _handleMessageRead(message);

      case 'messages_read':
        _handleMessagesRead(message);

      case 'bulk_read':
        _handleBulkRead(message);

      case 'read_receipt':
        _handleReadReceipt(message);

      case 'message_status_update':
        _handleMessageStatusUpdate(message);

      case 'typing_start':
        final userId = (message['user_id'] ?? message['userId'] ?? '')
            .toString();
        if (userId.isNotEmpty) {
          _typingController.add(TypingEvent(userId: userId, isTyping: true));
        }

      case 'typing_stop':
        final userId = (message['user_id'] ?? message['userId'] ?? '')
            .toString();
        if (userId.isNotEmpty) {
          _typingController.add(TypingEvent(userId: userId, isTyping: false));
        }

      case 'message_deleted':
        _handleMessageDeleted(message);

      case 'message_updated':
        _handleMessageUpdated(message);

      case 'announcement':
        log.d('Announcement: ${message['content']}');

      default:
        if (message.containsKey('sender') && message.containsKey('content')) {
          _handleNewMessage(message);
        } else if (message.containsKey('message_ids')) {
          _handleBulkRead(message);
        } else if (message.containsKey('read_at') ||
            message.containsKey('is_read')) {
          _handlePossibleReadReceipt(message);
        } else {
          log.w('Unknown message type: $type | data: ${jsonEncode(message)}');
        }
    }
  }

  // ─── Read Receipt handlers ────────────────────────────────────────────────

  void _handleBulkRead(Map<String, dynamic> data) {
    try {
      final messageIds = data['message_ids'];
      final readAt = _parseReadAt(data['read_at']);

      if (messageIds is List && messageIds.isNotEmpty) {
        for (final msgId in messageIds) {
          _readReceiptController.add(
            ReadReceiptEvent(messageId: msgId.toString(), readAt: readAt),
          );
        }
      } else {
        _readReceiptController.add(
          ReadReceiptEvent(messageId: '0', readAt: readAt),
        );
      }
    } catch (e) {
      log.e('Error handling bulk_read', error: e);
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final messageId = (data['message_id'] ?? data['id'] ?? '').toString();
      if (messageId.isNotEmpty && messageId != 'null') {
        _readReceiptController.add(
          ReadReceiptEvent(
            messageId: messageId,
            readAt: _parseReadAt(data['read_at']),
          ),
        );
      }
    } catch (e) {
      log.e('Error handling message_read', error: e);
    }
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      final messages = data['messages'] ?? data['message_ids'];
      if (messages is List) {
        for (final item in messages) {
          final messageId = item is Map
              ? item['id'].toString()
              : item.toString();
          final readAtStr = item is Map ? item['read_at'] as String? : null;
          _readReceiptController.add(
            ReadReceiptEvent(
              messageId: messageId,
              readAt: _parseReadAt(readAtStr),
            ),
          );
        }
      }
    } catch (e) {
      log.e('Error handling messages_read', error: e);
    }
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    try {
      final msgData = data['message'] ?? data['data'] ?? data;
      _handlePossibleReadReceipt(Map<String, dynamic>.from(msgData as Map));
    } catch (e) {
      log.e('Error handling read_receipt', error: e);
    }
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    try {
      final msgData = data['message'] ?? data['data'] ?? data;
      final m = Map<String, dynamic>.from(msgData as Map);
      if (m['status'] == 'read' || m['is_read'] == true) {
        _handlePossibleReadReceipt(m);
      }
    } catch (e) {
      log.e('Error handling message_status_update', error: e);
    }
  }

  void _handlePossibleReadReceipt(Map<String, dynamic> data) {
    try {
      final messageId = (data['id'] ?? data['message_id'])?.toString();
      if (messageId == null || messageId == 'null') return;

      DateTime? readAt;
      if (data['read_at'] != null) {
        readAt = DateTime.tryParse(data['read_at'] as String);
      } else if (data['is_read'] == true) {
        readAt = DateTime.now();
      }

      if (readAt != null) {
        _readReceiptController.add(
          ReadReceiptEvent(messageId: messageId, readAt: readAt),
        );
      }
    } catch (e) {
      log.e('Error parsing possible read receipt', error: e);
    }
  }

  DateTime _parseReadAt(dynamic readAtStr) {
    if (readAtStr is String) {
      return DateTime.tryParse(readAtStr) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // ─── Message action handlers ──────────────────────────────────────────────

  void _handleMessageDeleted(Map<String, dynamic> data) {
    try {
      final msgData = data['message'];
      String? messageId;
      if (msgData is Map) {
        messageId = (msgData['id'] ?? msgData['message_id'])?.toString();
      }
      messageId ??= (data['message_id'] ?? data['id'])?.toString();
      if (messageId != null) {
        _messageDeletedController.add(
          MessageDeletedEvent(messageId: messageId),
        );
      }
    } catch (e) {
      log.e('Error handling message_deleted', error: e);
    }
  }

  void _handleMessageUpdated(Map<String, dynamic> data) {
    try {
      final msgData = data['message'] ?? data;
      final messageId =
          (msgData['id'] ?? msgData['message_id'] ?? data['message_id'])
              ?.toString();
      final content = msgData['content'] as String?;
      if (messageId != null && content != null) {
        final editedAt = msgData['edited_at'] != null
            ? DateTime.tryParse(msgData['edited_at'] as String) ??
                  DateTime.now()
            : DateTime.now();
        _messageUpdatedController.add(
          MessageUpdatedEvent(
            messageId: messageId,
            content: content,
            editedAt: editedAt,
          ),
        );
      }
    } catch (e) {
      log.e('Error handling message_updated', error: e);
    }
  }

  // ─── New message ──────────────────────────────────────────────────────────

  void _handleNewMessage(Map<String, dynamic> messageData) {
    try {
      String senderId;
      String senderName;
      String? senderAvatar;
      String receiverId;

      if (messageData['sender'] is Map) {
        senderId = messageData['sender']['id'].toString();
        senderName = messageData['sender']['name'] ?? '';
        senderAvatar = messageData['sender']['avatar_url'];
      } else {
        senderId = (messageData['sender_id'] ?? messageData['senderId'] ?? '')
            .toString();
        senderName =
            messageData['sender_name'] ?? messageData['senderName'] ?? '';
        senderAvatar =
            messageData['sender_avatar'] ?? messageData['senderAvatar'];
      }

      if (messageData['recipient'] is Map) {
        receiverId = messageData['recipient']['id'].toString();
      } else {
        receiverId =
            (messageData['recipient_id'] ?? messageData['receiverId'] ?? '')
                .toString();
      }

      final message = ChatMessage(
        id: messageData['id'].toString(),
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        receiverId: receiverId,
        chatRoomId: messageData['chat_room_id'] as int? ?? 0,
        content: messageData['content'] ?? '',
        createdAt: messageData['created_at'] != null
            ? DateTime.parse(messageData['created_at'])
            : DateTime.now(),
        isRead: messageData['read_at'] != null,
        editedAt: messageData['edited_at'] != null
            ? DateTime.parse(messageData['edited_at'])
            : null,
        isDeleted: messageData['is_deleted'] ?? false,
      );

      _messageController.add(message);
      log.i('New message: "${message.content}" from $senderId');
    } catch (e) {
      log.e('Error handling new message', error: e);
    }
  }

  // ─── Send actions ─────────────────────────────────────────────────────────

  Future<void> sendMessage(ChatMessage message) async {
    if (!_isConnected || _channel == null || _chatChannelIdentifier == null)
      return;
    try {
      _sendCommand(
        'message',
        _chatChannelIdentifier!,
        data: {
          'action': 'send_message',
          'recipient_id': int.parse(message.receiverId),
          'content': message.content,
        },
      );
    } catch (e) {
      log.e('Error sending message', error: e);
    }
  }

  Future<void> sendTypingIndicator(String recipientId, bool isTyping) async {
    if (!_isConnected || _chatChannelIdentifier == null) return;
    _sendCommand(
      'message',
      _chatChannelIdentifier!,
      data: {
        'action': isTyping ? 'typing_start' : 'typing_stop',
        'recipient_id': int.parse(recipientId),
      },
    );
  }

  Future<void> enterRoom(String userId) async {
    if (!_isConnected || _chatChannelIdentifier == null) return;
    _sendCommand(
      'message',
      _chatChannelIdentifier!,
      data: {'action': 'enter_room', 'user_id': int.parse(userId)},
    );
  }

  Future<void> leaveRoom(String userId) async {
    if (!_isConnected || _chatChannelIdentifier == null) return;
    _sendCommand(
      'message',
      _chatChannelIdentifier!,
      data: {'action': 'leave_room', 'user_id': int.parse(userId)},
    );
  }

  Future<void> disconnect() async {
    _reconnectAttempts = _maxReconnectAttempts; // หยุด auto-reconnect
    _cancelTimers();
    _reconnectTimer?.cancel();
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _connectionController.add(false);
    log.i('WebSocket disconnected intentionally');
  }

  // ✅ dispose ต้อง removeObserver ด้วยเสมอ
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastToken = null;
    _cancelTimers();
    _reconnectTimer?.cancel();
    disconnect();
    _messageController.close();
    _connectionController.close();
    _readReceiptController.close();
    _messageDeletedController.close();
    _messageUpdatedController.close();
    _typingController.close();
  }
}
