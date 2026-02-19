import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:logger/logger.dart';
import 'package:test_wpa/core/constants/print_logger.dart';
import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart'
    show TypingEvent;

/// Data class for read receipt events from WebSocket
class ReadReceiptEvent {
  final String messageId;
  final DateTime readAt;
  ReadReceiptEvent({required this.messageId, required this.readAt});
}

/// Data class for message deleted events from WebSocket
class MessageDeletedEvent {
  final String messageId;
  MessageDeletedEvent({required this.messageId});
}

/// Data class for message updated events from WebSocket
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

class ChatWebSocketService {
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

  // ActionCable identifiers
  String? _chatChannelIdentifier;
  String? _notificationChannelIdentifier;

  // Reconnection
  String? _lastToken;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  ChatWebSocketService();

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<ReadReceiptEvent> get readReceiptStream =>
      _readReceiptController.stream;
  Stream<MessageDeletedEvent> get messageDeletedStream =>
      _messageDeletedController.stream;
  Stream<MessageUpdatedEvent> get messageUpdatedStream =>
      _messageUpdatedController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;

  /// เชื่อมต่อ ActionCable WebSocket
  Future<void> connect(String token) async {
    _lastToken = token;
    _reconnectAttempts = 0; // reset เมื่อ connect ใหม่
    _reconnectTimer?.cancel();

    try {
      // Close any existing connection first
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }

      final wsUrl = 'wss://wpa-docker.onrender.com/cable?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket Disconnected');
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      debugPrint('WebSocket Connected');

      // Wait for welcome message then subscribe channels
      await Future.delayed(const Duration(milliseconds: 500));
      await _subscribeChannels();
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  /// Auto-reconnect with exponential backoff
  void _scheduleReconnect() {
    if (_lastToken == null || _reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached or no token');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    debugPrint(
      'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && _lastToken != null) {
        debugPrint('Attempting reconnect...');
        connect(_lastToken!);
      }
    });
  }

  /// Subscribe ช่องต่างๆ
  Future<void> _subscribeChannels() async {
    _chatChannelIdentifier = jsonEncode({'channel': 'ChatChannel'});
    _sendCommand('subscribe', _chatChannelIdentifier!);
    debugPrint('📡 Subscribed to ChatChannel');

    _notificationChannelIdentifier = jsonEncode({
      'channel': 'NotificationChannel',
    });
    _sendCommand('subscribe', _notificationChannelIdentifier!);
    debugPrint('📡 Subscribed to NotificationChannel');
  }

  /// ส่ง command ไปยัง ActionCable
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

  /// จัดการข้อความที่ได้รับ
  void _handleMessage(dynamic rawData) {
    try {
      final data = jsonDecode(rawData.toString());
      final type = data['type'] as String?;

      print('🔍 [WebSocket Raw Message] Type: $type');
      print('🔍 [WebSocket Raw Data] ${jsonEncode(data)}');

      switch (type) {
        case 'welcome':
          debugPrint('Welcome to WebSocket');
          break;

        case 'ping':
          // ไม่ต้องทำอะไร
          break;

        case 'confirm_subscription':
          debugPrint('Subscription confirmed: ${data['identifier']}');
          break;

        case 'disconnect':
          debugPrint('WebSocket disconnect requested');
          _isConnected = false;
          _connectionController.add(false);
          break;

        default:
          // ActionCable data messages — payload อยู่ใน data['message']
          if (data['message'] != null && data['message'] is Map) {
            _handleActionCableDataMessage(
              Map<String, dynamic>.from(data['message'] as Map),
            );
          } else if (type != null) {
            debugPrint('Unknown system type: $type');
          }
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
      print('❌ Raw data that failed to parse: $rawData');
    }
  }

  /// จัดการ ActionCable data messages
  void _handleActionCableDataMessage(Map<String, dynamic> message) {
    final messageType = message['type'] as String?;

    log.i('📨 [Data Message] Type: $messageType');
    log.d('📨 [Data Content] ${jsonEncode(message)}');

    switch (messageType) {
      // ─── ข้อความใหม่ ───────────────────────────────────────────────
      case 'new_message':
        final msgData = message['message'];
        if (msgData is Map<String, dynamic>) {
          _handleNewMessage(msgData);
        } else {
          _handleNewMessage(message);
        }
        break;

      // ─── Read receipts ──────────────────────────────────────────────
      case 'message_read':
        print('✅ [READ RECEIPT] message_read');
        _handleMessageRead(message);
        break;

      case 'messages_read':
        print('✅ [READ RECEIPT] messages_read');
        _handleMessagesRead(message);
        break;

      // ✅ FIX: bulk_read — server ส่ง message_ids เป็น array
      case 'bulk_read':
        print('✅ [READ RECEIPT] bulk_read');
        _handleBulkRead(message);
        break;

      case 'read_receipt':
        print('✅ [READ RECEIPT] read_receipt');
        _handleReadReceipt(message);
        break;

      case 'message_status_update':
        print('✅ [READ RECEIPT] message_status_update');
        _handleMessageStatusUpdate(message);
        break;

      // ─── Typing ─────────────────────────────────────────────────────
      case 'typing_start':
        final userId = (message['user_id'] ?? message['userId'] ?? '')
            .toString();
        if (userId.isNotEmpty) {
          _typingController.add(TypingEvent(userId: userId, isTyping: true));
        }
        break;

      case 'typing_stop':
        final userId = (message['user_id'] ?? message['userId'] ?? '')
            .toString();
        if (userId.isNotEmpty) {
          _typingController.add(TypingEvent(userId: userId, isTyping: false));
        }
        break;

      // ─── Edit / Delete ───────────────────────────────────────────────
      case 'message_deleted':
        _handleMessageDeleted(message);
        break;

      case 'message_updated':
        _handleMessageUpdated(message);
        break;

      // ─── Notification ────────────────────────────────────────────────
      case 'new_notification':
        debugPrint('New notification: ${message['notification']}');
        break;

      case 'announcement':
        debugPrint('Announcement: ${message['content']}');
        break;

      default:
        // ไม่มี type wrapper — ลอง detect จาก fields
        if (message.containsKey('sender') && message.containsKey('content')) {
          _handleNewMessage(message);
        } else if (message.containsKey('message_ids')) {
          // ✅ FIX: บาง server อาจส่ง bulk_read โดยไม่มี type
          print('🔍 [Detected bulk_read without type field]');
          _handleBulkRead(message);
        } else if (message.containsKey('read_at') ||
            message.containsKey('is_read')) {
          print('🔍 [Possible Read Receipt] Found read_at or is_read field');
          _handlePossibleReadReceipt(message);
        } else {
          print('⚠️ [Unknown Message Type] $messageType');
          print('⚠️ [Unknown Message Data] ${jsonEncode(message)}');
        }
    }
  }

  // ─── Read Receipt handlers ──────────────────────────────────────────────

  /// ✅ FIX: bulk_read — iterate message_ids array
  void _handleBulkRead(Map<String, dynamic> data) {
    try {
      final messageIds = data['message_ids'];
      final readAtStr = data['read_at'] as String?;
      final readAt = readAtStr != null
          ? DateTime.parse(readAtStr)
          : DateTime.now();

      if (messageIds is List && messageIds.isNotEmpty) {
        print('📗 [Bulk Read] ${messageIds.length} messages at $readAt');
        for (final msgId in messageIds) {
          final messageId = msgId.toString();
          print('   → Message $messageId marked as read');
          _readReceiptController.add(
            ReadReceiptEvent(messageId: messageId, readAt: readAt),
          );
        }
        debugPrint('✅ Bulk read receipt: ${messageIds.length} messages');
      } else {
        print('⚠️ [Bulk Read] Invalid message_ids: ${jsonEncode(messageIds)}');
      }
    } catch (e) {
      debugPrint('❌ Error handling bulk_read: $e');
      print('❌ [Error Data] ${jsonEncode(data)}');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final messageId = (data['message_id'] ?? data['id'] ?? '').toString();
      final readAtStr = data['read_at'] as String?;
      final readAt = readAtStr != null
          ? DateTime.parse(readAtStr)
          : DateTime.now();

      if (messageId.isNotEmpty && messageId != 'null') {
        print('📗 [Message Read] Message $messageId at $readAt');
        _readReceiptController.add(
          ReadReceiptEvent(messageId: messageId, readAt: readAt),
        );
      } else {
        print('⚠️ [Message Read] Empty ID in: ${jsonEncode(data)}');
      }
    } catch (e) {
      debugPrint('❌ Error handling message_read: $e');
    }
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      final messages = data['messages'] ?? data['message_ids'];
      if (messages is List) {
        print('📗 [Messages Read] ${messages.length} messages');
        for (final item in messages) {
          final messageId = item is Map
              ? item['id'].toString()
              : item.toString();
          final readAtStr = item is Map ? item['read_at'] as String? : null;
          final readAt = readAtStr != null
              ? DateTime.parse(readAtStr)
              : DateTime.now();
          _readReceiptController.add(
            ReadReceiptEvent(messageId: messageId, readAt: readAt),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling messages_read: $e');
    }
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    try {
      final msgData = data['message'] ?? data['data'] ?? data;
      _handlePossibleReadReceipt(Map<String, dynamic>.from(msgData as Map));
    } catch (e) {
      print('❌ [Error handling read_receipt] $e');
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
      print('❌ [Error handling message_status_update] $e');
    }
  }

  void _handlePossibleReadReceipt(Map<String, dynamic> data) {
    try {
      String? messageId;
      DateTime? readAt;

      if (data['id'] != null) messageId = data['id'].toString();
      if (data['message_id'] != null) messageId = data['message_id'].toString();

      if (data['read_at'] != null) {
        readAt = DateTime.parse(data['read_at'] as String);
      } else if (data['is_read'] == true) {
        readAt = DateTime.now();
      }

      if (messageId != null && messageId != 'null' && readAt != null) {
        print('✅ [Parsed Read Receipt] Message $messageId read at $readAt');
        _readReceiptController.add(
          ReadReceiptEvent(messageId: messageId, readAt: readAt),
        );
      } else {
        print('⚠️ [Failed to parse] messageId: $messageId, readAt: $readAt');
      }
    } catch (e) {
      print('❌ [Error parsing possible read receipt] $e');
    }
  }

  // ─── Message action handlers ────────────────────────────────────────────

  void _handleMessageDeleted(Map<String, dynamic> data) {
    try {
      final msgData = data['message'];
      String? messageId;

      if (msgData is Map) {
        messageId = (msgData['id'] ?? msgData['message_id'])?.toString();
      }
      messageId ??= (data['message_id'] ?? data['id'])?.toString();

      if (messageId != null) {
        print('Received message_deleted for message $messageId');
        _messageDeletedController.add(
          MessageDeletedEvent(messageId: messageId),
        );
      } else {
        print('message_deleted: could not extract message ID from $data');
      }
    } catch (e) {
      print('Error handling message_deleted: $e');
    }
  }

  void _handleMessageUpdated(Map<String, dynamic> data) {
    try {
      final msgData = data['message'] ?? data;
      final messageId =
          (msgData['id'] ?? msgData['message_id'] ?? data['message_id'])
              ?.toString();
      final content = msgData['content'] as String?;
      final editedAtStr = msgData['edited_at'] as String?;

      if (messageId != null && content != null) {
        final editedAt = editedAtStr != null
            ? DateTime.parse(editedAtStr)
            : DateTime.now();
        print('Received message_updated for message $messageId');
        _messageUpdatedController.add(
          MessageUpdatedEvent(
            messageId: messageId,
            content: content,
            editedAt: editedAt,
          ),
        );
      }
    } catch (e) {
      print('Error handling message_updated: $e');
    }
  }

  // ─── New message ─────────────────────────────────────────────────────────

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
      debugPrint(
        'Received message: ${message.content} from $senderId to $receiverId',
      );
    } catch (e) {
      debugPrint('Error handling new message: $e | data: $messageData');
    }
  }

  // ─── Send actions ────────────────────────────────────────────────────────

  /// ส่งข้อความผ่าน ActionCable (WebSocket fallback)
  Future<void> sendMessage(ChatMessage message) async {
    if (!_isConnected || _channel == null || _chatChannelIdentifier == null) {
      debugPrint('❌ Cannot send message: Not connected');
      return;
    }

    try {
      final data = {
        'action': 'send_message',
        'recipient_id': int.parse(message.receiverId),
        'content': message.content,
      };

      _sendCommand('message', _chatChannelIdentifier!, data: data);
      debugPrint('📤 Sent message: ${message.content}');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
    }
  }

  /// แจ้งว่ากำลังพิมพ์
  Future<void> sendTypingIndicator(String recipientId, bool isTyping) async {
    if (!_isConnected || _chatChannelIdentifier == null) return;

    final data = {
      'action': isTyping ? 'typing_start' : 'typing_stop',
      'recipient_id': int.parse(recipientId),
    };

    _sendCommand('message', _chatChannelIdentifier!, data: data);
  }

  /// เข้าห้องแชท
  Future<void> enterRoom(String userId) async {
    if (!_isConnected || _chatChannelIdentifier == null) return;

    final data = {'action': 'enter_room', 'user_id': int.parse(userId)};

    _sendCommand('message', _chatChannelIdentifier!, data: data);
    debugPrint('🚪 Entered chat room');
  }

  /// ออกจากห้องแชท
  Future<void> leaveRoom(String userId) async {
    if (!_isConnected || _chatChannelIdentifier == null) return;

    final data = {'action': 'leave_room', 'user_id': int.parse(userId)};

    _sendCommand('message', _chatChannelIdentifier!, data: data);
    debugPrint('🚪 Left chat room');
  }

  /// ปิดการเชื่อมต่อ (intentional — ไม่ reconnect)
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts; // หยุด auto-reconnect

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _connectionController.add(false);
    debugPrint('WebSocket Disconnected');
  }

  /// ทำลาย resources
  void dispose() {
    _reconnectTimer?.cancel();
    _lastToken = null;
    disconnect();
    _messageController.close();
    _connectionController.close();
    _readReceiptController.close();
    _messageDeletedController.close();
    _messageUpdatedController.close();
    _typingController.close();
  }
}
