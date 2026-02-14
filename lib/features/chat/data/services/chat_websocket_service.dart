import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:logger/logger.dart';
import 'package:test_wpa/core/constants/print_logger.dart';

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

  /// เชื่อมต่อ ActionCable WebSocket
  Future<void> connect(String token) async {
    _lastToken = token;
    _reconnectAttempts = 0;
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
    // Subscribe ChatChannel
    _chatChannelIdentifier = jsonEncode({'channel': 'ChatChannel'});
    _sendCommand('subscribe', _chatChannelIdentifier!);
    debugPrint('📡 Subscribed to ChatChannel');

    // Subscribe NotificationChannel
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

      // 🔥 DEBUG: แสดงทุก message ที่ได้รับ
      print('🔍 [WebSocket Raw Message] Type: $type');
      print('🔍 [WebSocket Raw Data] ${jsonEncode(data)}');
      

      // ActionCable system messages
      switch (type) {
        case 'welcome':
          debugPrint('Welcome to WebSocket');
          break;

        case 'ping':
          // ping ไม่ต้อง print
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
          // ActionCable data messages
          if (data['message'] != null && data['message'] is Map) {
            _handleActionCableDataMessage(data['message']);
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

    // 🔥 DEBUG: แสดง message type และ content
    // print('📨 [Data Message] Type: $messageType');
    // print('📨 [Data Content] ${jsonEncode(message)}');
    log.i('📨 [Data Message] Type: $messageType');
    log.d('📨 [Data Content] ${jsonEncode(message)}');

    switch (messageType) {
      case 'new_message':
        final msgData = message['message'];
        if (msgData is Map<String, dynamic>) {
          _handleNewMessage(msgData);
        } else {
          _handleNewMessage(message);
        }
        break;

      // 🔥 FIX: Backend ส่งทั้ง "message_read" (single) และ "bulk_read" (array)
      case 'message_read':
        print('✅ [READ RECEIPT] Received message_read event!');
        _handleMessageRead(message);
        break;
      case 'messages_read':
        print('✅ [READ RECEIPT] Received messages_read event!');
        _handleMessagesRead(message);
        break;

      case 'bulk_read':
        print('✅ [BULK READ RECEIPT] Received bulk_read event!');
        _handleBulkRead(message);
        break;

      // 🔥 NEW: Handle ทุก possible format ของ read receipt
      case 'read_receipt':
        print('✅ [READ RECEIPT] Received read_receipt event!');
        _handleReadReceipt(message);
        break;

      case 'message_status_update':
        print('✅ [READ RECEIPT] Received message_status_update event!');
        _handleMessageStatusUpdate(message);
        break;

      case 'typing_start':
        debugPrint('User is typing...');
        break;

      case 'typing_stop':
        debugPrint('User stopped typing');
        break;

      case 'message_deleted':
        _handleMessageDeleted(message);
        break;

      case 'message_updated':
        _handleMessageUpdated(message);
        break;

      case 'new_notification':
        debugPrint('New notification: ${message['notification']}');
        break;

      case 'announcement':
        debugPrint('Announcement: ${message['content']}');
        break;

      default:
        // บาง ActionCable server ส่ง message โดยไม่มี 'type' wrapper
        if (message.containsKey('sender') && message.containsKey('content')) {
          _handleNewMessage(message);
        }
        // 🔥 NEW: ตรวจสอบว่ามี read_at field หรือไม่ (อาจเป็น read receipt)
        else if (message.containsKey('read_at') ||
            message.containsKey('is_read')) {
          print('🔍 [Possible Read Receipt] Found read_at or is_read field');
          _handlePossibleReadReceipt(message);
        } else {
          print('⚠️ [Unknown Message Type] $messageType');
          print('⚠️ [Unknown Message Data] ${jsonEncode(message)}');
        }
    }
  }

  /// 🔥 NEW: Handle possible read receipt format
  void _handlePossibleReadReceipt(Map<String, dynamic> data) {
    try {
      String? messageId;
      DateTime? readAt;

      // Try different field names
      if (data['id'] != null) messageId = data['id'].toString();
      if (data['message_id'] != null) messageId = data['message_id'].toString();

      if (data['read_at'] != null) {
        readAt = DateTime.parse(data['read_at']);
      } else if (data['is_read'] == true) {
        readAt = DateTime.now();
      }

      if (messageId != null && readAt != null) {
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

  /// 🔥 NEW: Handle read_receipt type
  void _handleReadReceipt(Map<String, dynamic> data) {
    try {
      final msgData = data['message'] ?? data['data'] ?? data;
      _handlePossibleReadReceipt(msgData);
    } catch (e) {
      print('❌ [Error handling read_receipt] $e');
    }
  }

  /// 🔥 NEW: Handle message_status_update type
  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    try {
      final msgData = data['message'] ?? data['data'] ?? data;
      if (msgData['status'] == 'read' || msgData['is_read'] == true) {
        _handlePossibleReadReceipt(msgData);
      }
    } catch (e) {
      print('❌ [Error handling message_status_update] $e');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final messageId = (data['message_id'] ?? data['id'] ?? '').toString();
      final readAtStr = data['read_at'] as String?;
      final readAt = readAtStr != null
          ? DateTime.parse(readAtStr)
          : DateTime.now();

      if (messageId.isNotEmpty) {
        print('📗 [Processing Read Receipt] Message $messageId at $readAt');
        _readReceiptController.add(
          ReadReceiptEvent(messageId: messageId, readAt: readAt),
        );
        debugPrint('✅ Read receipt received for message $messageId');
      } else {
        print(
          '⚠️ [Read Receipt] Empty message ID in data: ${jsonEncode(data)}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error handling message_read: $e');
      print('❌ [Error Data] ${jsonEncode(data)}');
    }
  }

  void _handleBulkRead(Map<String, dynamic> data) {
    try {
      final messageIds = data['message_ids'];
      final readAtStr = data['read_at'] as String?;
      final readAt = readAtStr != null
          ? DateTime.parse(readAtStr)
          : DateTime.now();

      if (messageIds is List && messageIds.isNotEmpty) {
        print(
          '📗 [Processing Bulk Read Receipt] ${messageIds.length} messages at $readAt',
        );

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

  /// Handle message_deleted event from WebSocket
  void _handleMessageDeleted(Map<String, dynamic> data) {
    try {
      // Format: {"type":"message_deleted","message_id":123}
      // or nested: {"type":"message_deleted","message":{"id":123}}
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

  /// Handle message_updated event from WebSocket
  void _handleMessageUpdated(Map<String, dynamic> data) {
    try {
      // Format: {"type":"message_updated","message":{"id":123,"content":"new text","edited_at":"..."}}
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
      } else {
        print(
          'message_updated: could not extract message ID or content from $data',
        );
      }
    } catch (e) {
      print('Error handling message_updated: $e');
    }
  }

  /// Handle bulk messages read receipt from WebSocket
  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      final messages = data['messages'] ?? data['message_ids'];
      if (messages is List) {
        print('📗 [Processing Bulk Read Receipt] ${messages.length} messages');
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
        debugPrint('Bulk read receipt: ${messages.length} messages');
      } else {
        print(
          '⚠️ [Bulk Read Receipt] messages is not a List: ${messages.runtimeType}',
        );
      }
    } catch (e) {
      debugPrint('Error handling messages_read: $e');
      print('❌ [Error Data] ${jsonEncode(data)}');
    }
  }

  /// จัดการข้อความใหม่
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

  /// ส่งข้อความผ่าน ActionCable
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
      'action': 'typing_start',
      'recipient_id': int.parse(recipientId),
      'typing_start': isTyping,
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

  /// ปิดการเชื่อมต่อ
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts;

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
  }
}
