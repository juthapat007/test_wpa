// import 'dart:async';
// import 'dart:convert';
// import 'package:test_wpa/core/constants/print_logger.dart';
// import 'package:test_wpa/core/services/notification_websocket_service.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:test_wpa/features/chat/data/models/chat_message.dart';
// import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart'
//     show TypingEvent;

// /// Data class for read receipt events from WebSocket
// class ReadReceiptEvent {
//   final String messageId;
//   final DateTime readAt;
//   ReadReceiptEvent({required this.messageId, required this.readAt});
// }

// /// Data class for message deleted events from WebSocket
// class MessageDeletedEvent {
//   final String messageId;
//   MessageDeletedEvent({required this.messageId});
// }

// /// Data class for message updated events from WebSocket
// class MessageUpdatedEvent {
//   final String messageId;
//   final String content;
//   final DateTime editedAt;
//   MessageUpdatedEvent({
//     required this.messageId,
//     required this.content,
//     required this.editedAt,
//   });
// }

// class ChatWebSocketService {
//   WebSocketChannel? _channel;
//   final _messageController = StreamController<ChatMessage>.broadcast();
//   final _connectionController = StreamController<bool>.broadcast();
//   final _readReceiptController = StreamController<ReadReceiptEvent>.broadcast();
//   final _messageDeletedController =
//       StreamController<MessageDeletedEvent>.broadcast();
//   final _messageUpdatedController =
//       StreamController<MessageUpdatedEvent>.broadcast();
//   final _typingController = StreamController<TypingEvent>.broadcast();

//   bool _isConnected = false;
//   bool get isConnected => _isConnected;

//   // ActionCable identifiers
//   String? _chatChannelIdentifier;
//   String? _notificationChannelIdentifier;

//   // Reconnection
//   String? _lastToken;
//   int _reconnectAttempts = 0;
//   static const int _maxReconnectAttempts = 5;
//   Timer? _reconnectTimer;

//   ChatWebSocketService();

//   Stream<ChatMessage> get messageStream => _messageController.stream;
//   Stream<bool> get connectionStream => _connectionController.stream;
//   Stream<ReadReceiptEvent> get readReceiptStream =>
//       _readReceiptController.stream;
//   Stream<MessageDeletedEvent> get messageDeletedStream =>
//       _messageDeletedController.stream;
//   Stream<MessageUpdatedEvent> get messageUpdatedStream =>
//       _messageUpdatedController.stream;
//   Stream<TypingEvent> get typingStream => _typingController.stream;

//   /// เชื่อมต่อ ActionCable WebSocket
//   Future<void> connect(String token) async {
//     _lastToken = token;
//     _reconnectAttempts = 0;
//     _reconnectTimer?.cancel();

//     try {
//       if (_channel != null) {
//         await _channel!.sink.close();
//         _channel = null;
//       }

//       final wsUrl = 'wss://wpa-docker.onrender.com/cable?token=$token';
//       _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
//       _channel!.stream.listen(
//         _handleMessage,
//         onError: (error) {
//           log.e('WebSocket error', error: error);
//           _isConnected = false;
//           _connectionController.add(false);
//           _scheduleReconnect();
//         },
//         onDone: () {
//           log.w('WebSocket disconnected');
//           _isConnected = false;
//           _connectionController.add(false);
//           _scheduleReconnect();
//         },
//       );

//       _isConnected = true;
//       _connectionController.add(true);
//       log.i('WebSocket connected');

//       // Wait for welcome message then subscribe channels
//       await Future.delayed(const Duration(milliseconds: 500));
//       await _subscribeChannels();
//     } catch (e) {
//       log.e('Failed to connect WebSocket', error: e);
//       _isConnected = false;
//       _connectionController.add(false);
//       _scheduleReconnect();
//     }
//   }

//   /// Auto-reconnect with exponential backoff
//   void _scheduleReconnect() {
//     if (_lastToken == null || _reconnectAttempts >= _maxReconnectAttempts) {
//       log.w('Max reconnect attempts reached or no token available');
//       return;
//     }

//     _reconnectAttempts++;
//     final delay = Duration(seconds: _reconnectAttempts * 2);
//     log.i(
//       'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
//     );

//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(delay, () {
//       if (!_isConnected && _lastToken != null) {
//         log.i('Attempting reconnect...');
//         connect(_lastToken!);
//       }
//     });
//   }

//   /// Subscribe ช่องต่างๆ
//   Future<void> _subscribeChannels() async {
//     _chatChannelIdentifier = jsonEncode({'channel': 'ChatChannel'});
//     _sendCommand('subscribe', _chatChannelIdentifier!);
//     log.i('Subscribed to ChatChannel');

//     _notificationChannelIdentifier = jsonEncode({
//       'channel': 'NotificationChannel',
//     });
//     _sendCommand('subscribe', _notificationChannelIdentifier!);
//     log.i('Subscribed to NotificationChannel');
//   }

//   /// ส่ง command ไปยัง ActionCable
//   void _sendCommand(
//     String command,
//     String identifier, {
//     Map<String, dynamic>? data,
//   }) {
//     if (_channel == null) return;

//     final message = {
//       'command': command,
//       'identifier': identifier,
//       if (data != null) 'data': jsonEncode(data),
//     };

//     _channel!.sink.add(jsonEncode(message));
//   }

//   /// จัดการข้อความที่ได้รับ
//   void _handleMessage(dynamic rawData) {
//     try {
//       final data = jsonDecode(rawData.toString());
//       final type = data['type'] as String?;

//       log.v('[WebSocket] type=$type data=${jsonEncode(data)}');

//       switch (type) {
//         case 'welcome':
//           log.d('WebSocket welcome received');
//           break;

//         case 'ping':
//           // ไม่ต้องทำอะไร
//           break;

//         case 'confirm_subscription':
//           log.d('Subscription confirmed: ${data['identifier']}');
//           break;

//         case 'disconnect':
//           log.w('WebSocket disconnect requested by server');
//           _isConnected = false;
//           _connectionController.add(false);
//           break;

//         default:
//           if (data['message'] != null && data['message'] is Map) {
//             _handleActionCableDataMessage(
//               Map<String, dynamic>.from(data['message'] as Map),
//             );
//           } else if (type != null) {
//             log.w('Unknown system type: $type');
//           }
//       }
//     } catch (e) {
//       log.e('Error parsing WebSocket message', error: e);
//     }
//   }

//   /// จัดการ ActionCable data messages
//   void _handleActionCableDataMessage(Map<String, dynamic> message) {
//     final messageType = message['type'] as String?;

//     log.i('[Data Message] type=$messageType');
//     log.d('[Data Content] ${jsonEncode(message)}');

//     switch (messageType) {
//       // ─── ข้อความใหม่ ───────────────────────────────────────────────
//       case 'new_message':
//         final msgData = message['message'];
//         if (msgData is Map<String, dynamic>) {
//           _handleNewMessage(msgData);
//         } else {
//           _handleNewMessage(message);
//         }
//         break;

//       // ─── Read receipts ──────────────────────────────────────────────
//       case 'message_read':
//         log.d('[Read Receipt] message_read');
//         _handleMessageRead(message);
//         break;

//       case 'messages_read':
//         log.d('[Read Receipt] messages_read');
//         _handleMessagesRead(message);
//         break;

//       case 'bulk_read':
//         log.d('[Read Receipt] bulk_read');
//         _handleBulkRead(message);
//         break;

//       case 'read_receipt':
//         log.d('[Read Receipt] read_receipt');
//         _handleReadReceipt(message);
//         break;

//       case 'message_status_update':
//         log.d('[Read Receipt] message_status_update');
//         _handleMessageStatusUpdate(message);
//         break;

//       // ─── Typing ─────────────────────────────────────────────────────
//       case 'typing_start':
//         final userId = (message['user_id'] ?? message['userId'] ?? '')
//             .toString();
//         if (userId.isNotEmpty) {
//           _typingController.add(TypingEvent(userId: userId, isTyping: true));
//         }
//         break;

//       case 'typing_stop':
//         final userId = (message['user_id'] ?? message['userId'] ?? '')
//             .toString();
//         if (userId.isNotEmpty) {
//           _typingController.add(TypingEvent(userId: userId, isTyping: false));
//         }
//         break;

//       // ─── Edit / Delete ───────────────────────────────────────────────
//       case 'message_deleted':
//         _handleMessageDeleted(message);
//         break;

//       case 'message_updated':
//         _handleMessageUpdated(message);
//         break;

//       case 'announcement':
//         log.d('Announcement: ${message['content']}');
//         break;

//       default:
//         // ไม่มี type wrapper — ลอง detect จาก fields
//         if (message.containsKey('sender') && message.containsKey('content')) {
//           _handleNewMessage(message);
//         } else if (message.containsKey('message_ids')) {
//           log.d('Detected bulk_read without type field');
//           _handleBulkRead(message);
//         } else if (message.containsKey('read_at') ||
//             message.containsKey('is_read')) {
//           log.d('Possible read receipt — found read_at or is_read field');
//           _handlePossibleReadReceipt(message);
//         } else {
//           log.w(
//             'Unknown message type: $messageType | data: ${jsonEncode(message)}',
//           );
//         }
//     }
//   }

//   // ─── Read Receipt handlers ──────────────────────────────────────────────

//   void _handleBulkRead(Map<String, dynamic> data) {
//     try {
//       final messageIds = data['message_ids'];
//       final readAtStr = data['read_at'] as String?;
//       final readAt = readAtStr != null
//           ? DateTime.parse(readAtStr)
//           : DateTime.now();

//       if (messageIds is List && messageIds.isNotEmpty) {
//         log.d('[Bulk Read] ${messageIds.length} messages at $readAt');
//         for (final msgId in messageIds) {
//           final messageId = msgId.toString();
//           _readReceiptController.add(
//             ReadReceiptEvent(messageId: messageId, readAt: readAt),
//           );
//         }
//       } else {
//         log.w('[Bulk Read] Invalid message_ids: ${jsonEncode(messageIds)}');
//       }
//     } catch (e) {
//       log.e('Error handling bulk_read', error: e);
//     }
//   }

//   void _handleMessageRead(Map<String, dynamic> data) {
//     try {
//       final messageId = (data['message_id'] ?? data['id'] ?? '').toString();
//       final readAtStr = data['read_at'] as String?;
//       final readAt = readAtStr != null
//           ? DateTime.parse(readAtStr)
//           : DateTime.now();

//       if (messageId.isNotEmpty && messageId != 'null') {
//         log.d('[Message Read] Message $messageId at $readAt');
//         _readReceiptController.add(
//           ReadReceiptEvent(messageId: messageId, readAt: readAt),
//         );
//       } else {
//         log.w('[Message Read] Empty ID in: ${jsonEncode(data)}');
//       }
//     } catch (e) {
//       log.e('Error handling message_read', error: e);
//     }
//   }

//   void _handleMessagesRead(Map<String, dynamic> data) {
//     try {
//       final messages = data['messages'] ?? data['message_ids'];
//       if (messages is List) {
//         log.d('[Messages Read] ${messages.length} messages');
//         for (final item in messages) {
//           final messageId = item is Map
//               ? item['id'].toString()
//               : item.toString();
//           final readAtStr = item is Map ? item['read_at'] as String? : null;
//           final readAt = readAtStr != null
//               ? DateTime.parse(readAtStr)
//               : DateTime.now();
//           _readReceiptController.add(
//             ReadReceiptEvent(messageId: messageId, readAt: readAt),
//           );
//         }
//       }
//     } catch (e) {
//       log.e('Error handling messages_read', error: e);
//     }
//   }

//   void _handleReadReceipt(Map<String, dynamic> data) {
//     try {
//       final msgData = data['message'] ?? data['data'] ?? data;
//       _handlePossibleReadReceipt(Map<String, dynamic>.from(msgData as Map));
//     } catch (e) {
//       log.e('Error handling read_receipt', error: e);
//     }
//   }

//   void _handleMessageStatusUpdate(Map<String, dynamic> data) {
//     try {
//       final msgData = data['message'] ?? data['data'] ?? data;
//       final m = Map<String, dynamic>.from(msgData as Map);
//       if (m['status'] == 'read' || m['is_read'] == true) {
//         _handlePossibleReadReceipt(m);
//       }
//     } catch (e) {
//       log.e('Error handling message_status_update', error: e);
//     }
//   }

//   void _handlePossibleReadReceipt(Map<String, dynamic> data) {
//     try {
//       String? messageId;
//       DateTime? readAt;

//       if (data['id'] != null) messageId = data['id'].toString();
//       if (data['message_id'] != null) messageId = data['message_id'].toString();

//       if (data['read_at'] != null) {
//         readAt = DateTime.parse(data['read_at'] as String);
//       } else if (data['is_read'] == true) {
//         readAt = DateTime.now();
//       }

//       if (messageId != null && messageId != 'null' && readAt != null) {
//         log.d('[Read Receipt] Message $messageId read at $readAt');
//         _readReceiptController.add(
//           ReadReceiptEvent(messageId: messageId, readAt: readAt),
//         );
//       } else {
//         log.w(
//           '[Read Receipt] Failed to parse — messageId: $messageId, readAt: $readAt',
//         );
//       }
//     } catch (e) {
//       log.e('Error parsing possible read receipt', error: e);
//     }
//   }

//   // ─── Message action handlers ────────────────────────────────────────────

//   void _handleMessageDeleted(Map<String, dynamic> data) {
//     try {
//       final msgData = data['message'];
//       String? messageId;

//       if (msgData is Map) {
//         messageId = (msgData['id'] ?? msgData['message_id'])?.toString();
//       }
//       messageId ??= (data['message_id'] ?? data['id'])?.toString();

//       if (messageId != null) {
//         log.i('Message $messageId deleted');
//         _messageDeletedController.add(
//           MessageDeletedEvent(messageId: messageId),
//         );
//       } else {
//         log.w('message_deleted: could not extract message ID from $data');
//       }
//     } catch (e) {
//       log.e('Error handling message_deleted', error: e);
//     }
//   }

//   void _handleMessageUpdated(Map<String, dynamic> data) {
//     try {
//       final msgData = data['message'] ?? data;
//       final messageId =
//           (msgData['id'] ?? msgData['message_id'] ?? data['message_id'])
//               ?.toString();
//       final content = msgData['content'] as String?;
//       final editedAtStr = msgData['edited_at'] as String?;

//       if (messageId != null && content != null) {
//         final editedAt = editedAtStr != null
//             ? DateTime.parse(editedAtStr)
//             : DateTime.now();
//         log.i('Message $messageId updated');
//         _messageUpdatedController.add(
//           MessageUpdatedEvent(
//             messageId: messageId,
//             content: content,
//             editedAt: editedAt,
//           ),
//         );
//       }
//     } catch (e) {
//       log.e('Error handling message_updated', error: e);
//     }
//   }

//   // ─── New message ─────────────────────────────────────────────────────────

//   void _handleNewMessage(Map<String, dynamic> messageData) {
//     try {
//       String senderId;
//       String senderName;
//       String? senderAvatar;
//       String receiverId;

//       if (messageData['sender'] is Map) {
//         senderId = messageData['sender']['id'].toString();
//         senderName = messageData['sender']['name'] ?? '';
//         senderAvatar = messageData['sender']['avatar_url'];
//       } else {
//         senderId = (messageData['sender_id'] ?? messageData['senderId'] ?? '')
//             .toString();
//         senderName =
//             messageData['sender_name'] ?? messageData['senderName'] ?? '';
//         senderAvatar =
//             messageData['sender_avatar'] ?? messageData['senderAvatar'];
//       }

//       if (messageData['recipient'] is Map) {
//         receiverId = messageData['recipient']['id'].toString();
//       } else {
//         receiverId =
//             (messageData['recipient_id'] ?? messageData['receiverId'] ?? '')
//                 .toString();
//       }

//       final message = ChatMessage(
//         id: messageData['id'].toString(),
//         senderId: senderId,
//         senderName: senderName,
//         senderAvatar: senderAvatar,
//         receiverId: receiverId,
//         chatRoomId: messageData['chat_room_id'] as int? ?? 0,
//         content: messageData['content'] ?? '',
//         createdAt: messageData['created_at'] != null
//             ? DateTime.parse(messageData['created_at'])
//             : DateTime.now(),
//         isRead: messageData['read_at'] != null,
//         editedAt: messageData['edited_at'] != null
//             ? DateTime.parse(messageData['edited_at'])
//             : null,
//         isDeleted: messageData['is_deleted'] ?? false,
//       );

//       _messageController.add(message);
//       log.i('New message from $senderId to $receiverId: "${message.content}"');
//     } catch (e) {
//       log.e('Error handling new message', error: e);
//     }
//   }

//   // ─── Send actions ────────────────────────────────────────────────────────

//   /// ส่งข้อความผ่าน ActionCable (WebSocket fallback)
//   Future<void> sendMessage(ChatMessage message) async {
//     if (!_isConnected || _channel == null || _chatChannelIdentifier == null) {
//       log.w('Cannot send message: not connected');
//       return;
//     }

//     try {
//       final data = {
//         'action': 'send_message',
//         'recipient_id': int.parse(message.receiverId),
//         'content': message.content,
//       };

//       _sendCommand('message', _chatChannelIdentifier!, data: data);
//       log.d('Message sent: "${message.content}"');
//     } catch (e) {
//       log.e('Error sending message', error: e);
//     }
//   }

//   /// แจ้งว่ากำลังพิมพ์
//   Future<void> sendTypingIndicator(String recipientId, bool isTyping) async {
//     if (!_isConnected || _chatChannelIdentifier == null) return;

//     final data = {
//       'action': isTyping ? 'typing_start' : 'typing_stop',
//       'recipient_id': int.parse(recipientId),
//     };

//     _sendCommand('message', _chatChannelIdentifier!, data: data);
//   }

//   /// เข้าห้องแชท
//   Future<void> enterRoom(String userId) async {
//     if (!_isConnected || _chatChannelIdentifier == null) return;

//     _sendCommand(
//       'message',
//       _chatChannelIdentifier!,
//       data: {'action': 'enter_room', 'user_id': int.parse(userId)},
//     );
//     log.d('Entered chat room (userId=$userId)');
//   }

//   /// ออกจากห้องแชท
//   Future<void> leaveRoom(String userId) async {
//     if (!_isConnected || _chatChannelIdentifier == null) return;

//     _sendCommand(
//       'message',
//       _chatChannelIdentifier!,
//       data: {'action': 'leave_room', 'user_id': int.parse(userId)},
//     );
//     log.d('Left chat room (userId=$userId)');
//   }

//   /// ปิดการเชื่อมต่อ (intentional — ไม่ reconnect)
//   Future<void> disconnect() async {
//     _reconnectTimer?.cancel();
//     _reconnectAttempts = _maxReconnectAttempts; // หยุด auto-reconnect

//     if (_channel != null) {
//       await _channel!.sink.close();
//       _channel = null;
//     }

//     _isConnected = false;
//     _connectionController.add(false);
//     log.i('WebSocket disconnected');
//   }

//   /// ทำลาย resources
//   void dispose() {
//     _reconnectTimer?.cancel();
//     _lastToken = null;
//     disconnect();
//     _messageController.close();
//     _connectionController.close();
//     _readReceiptController.close();
//     _messageDeletedController.close();
//     _messageUpdatedController.close();
//     _typingController.close();
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:test_wpa/core/constants/print_logger.dart';
import 'package:test_wpa/core/services/notification_websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
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
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

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
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          log.w('WebSocket disconnected');
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      log.i('WebSocket connected');

      // Wait for welcome message then subscribe channels
      await Future.delayed(const Duration(milliseconds: 500));
      await _subscribeChannels();
    } catch (e) {
      log.e('Failed to connect WebSocket', error: e);
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  /// Auto-reconnect with exponential backoff
  void _scheduleReconnect() {
    if (_lastToken == null || _reconnectAttempts >= _maxReconnectAttempts) {
      log.w('Max reconnect attempts reached or no token available');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    log.i(
      'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && _lastToken != null) {
        log.i('Attempting reconnect...');
        connect(_lastToken!);
      }
    });
  }

  /// Subscribe ช่องต่างๆ
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
    log.wtf('[ChatWS RAW] $rawData');
    try {
      final data = jsonDecode(rawData.toString());
      final type = data['type'] as String?;

      log.v('[WebSocket] type=$type data=${jsonEncode(data)}');

      switch (type) {
        case 'welcome':
          log.d('WebSocket welcome received');
          break;

        case 'ping':
          // ไม่ต้องทำอะไร
          break;

        case 'confirm_subscription':
          log.d('Subscription confirmed: ${data['identifier']}');
          break;

        case 'disconnect':
          log.w('WebSocket disconnect requested by server');
          _isConnected = false;
          _connectionController.add(false);
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

  /// จัดการ ActionCable data messages
  void _handleActionCableDataMessage(Map<String, dynamic> message) {
    final messageType = message['type'] as String?;

    log.i('[Data Message] type=$messageType');
    log.d('[Data Content] ${jsonEncode(message)}');

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
        log.d('[Read Receipt] message_read');
        _handleMessageRead(message);
        break;

      case 'messages_read':
        log.d('[Read Receipt] messages_read');
        _handleMessagesRead(message);
        break;

      case 'bulk_read':
        log.d('[Read Receipt] bulk_read');
        _handleBulkRead(message);
        break;

      case 'read_receipt':
        log.d('[Read Receipt] read_receipt');
        _handleReadReceipt(message);
        break;

      case 'message_status_update':
        log.d('[Read Receipt] message_status_update');
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

      // ─── Notification (forward ให้ NotificationWebSocketService) ───────
      case 'new_notification':
        log.i('[ChatWS] forwarding new_notification → NotificationWS');
        NotificationWebSocketService.instance.handleIncomingEvent(message);
        break;

      case 'announcement':
        log.d('Announcement: ${message['content']}');
        break;

      default:
        // ไม่มี type wrapper — ลอง detect จาก fields
        if (message.containsKey('sender') && message.containsKey('content')) {
          _handleNewMessage(message);
        } else if (message.containsKey('message_ids')) {
          log.d('Detected bulk_read without type field');
          _handleBulkRead(message);
        } else if (message.containsKey('read_at') ||
            message.containsKey('is_read')) {
          log.d('Possible read receipt — found read_at or is_read field');
          _handlePossibleReadReceipt(message);
        } else {
          log.w(
            'Unknown message type: $messageType | data: ${jsonEncode(message)}',
          );
        }
    }
  }

  // ─── Read Receipt handlers ──────────────────────────────────────────────

  void _handleBulkRead(Map<String, dynamic> data) {
    try {
      final messageIds = data['message_ids'];
      final readAtStr = data['read_at'] as String?;
      final readAt = readAtStr != null
          ? DateTime.parse(readAtStr)
          : DateTime.now();

      if (messageIds is List && messageIds.isNotEmpty) {
        log.d('[Bulk Read] ${messageIds.length} messages at $readAt');
        for (final msgId in messageIds) {
          final messageId = msgId.toString();
          _readReceiptController.add(
            ReadReceiptEvent(messageId: messageId, readAt: readAt),
          );
        }
      } else {
        log.w('[Bulk Read] Invalid message_ids: ${jsonEncode(messageIds)}');
      }
    } catch (e) {
      log.e('Error handling bulk_read', error: e);
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
        log.d('[Message Read] Message $messageId at $readAt');
        _readReceiptController.add(
          ReadReceiptEvent(messageId: messageId, readAt: readAt),
        );
      } else {
        log.w('[Message Read] Empty ID in: ${jsonEncode(data)}');
      }
    } catch (e) {
      log.e('Error handling message_read', error: e);
    }
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      final messages = data['messages'] ?? data['message_ids'];
      if (messages is List) {
        log.d('[Messages Read] ${messages.length} messages');
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
        log.d('[Read Receipt] Message $messageId read at $readAt');
        _readReceiptController.add(
          ReadReceiptEvent(messageId: messageId, readAt: readAt),
        );
      } else {
        log.w(
          '[Read Receipt] Failed to parse — messageId: $messageId, readAt: $readAt',
        );
      }
    } catch (e) {
      log.e('Error parsing possible read receipt', error: e);
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
        log.i('Message $messageId deleted');
        _messageDeletedController.add(
          MessageDeletedEvent(messageId: messageId),
        );
      } else {
        log.w('message_deleted: could not extract message ID from $data');
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
      final editedAtStr = msgData['edited_at'] as String?;

      if (messageId != null && content != null) {
        final editedAt = editedAtStr != null
            ? DateTime.parse(editedAtStr)
            : DateTime.now();
        log.i('Message $messageId updated');
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
      log.i('New message from $senderId to $receiverId: "${message.content}"');
    } catch (e) {
      log.e('Error handling new message', error: e);
    }
  }

  // ─── Send actions ────────────────────────────────────────────────────────

  /// ส่งข้อความผ่าน ActionCable (WebSocket fallback)
  Future<void> sendMessage(ChatMessage message) async {
    if (!_isConnected || _channel == null || _chatChannelIdentifier == null) {
      log.w('Cannot send message: not connected');
      return;
    }

    try {
      final data = {
        'action': 'send_message',
        'recipient_id': int.parse(message.receiverId),
        'content': message.content,
      };

      _sendCommand('message', _chatChannelIdentifier!, data: data);
      log.d('Message sent: "${message.content}"');
    } catch (e) {
      log.e('Error sending message', error: e);
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

    _sendCommand(
      'message',
      _chatChannelIdentifier!,
      data: {'action': 'enter_room', 'user_id': int.parse(userId)},
    );
    log.d('Entered chat room (userId=$userId)');
  }

  /// ออกจากห้องแชท
  Future<void> leaveRoom(String userId) async {
    if (!_isConnected || _chatChannelIdentifier == null) return;

    _sendCommand(
      'message',
      _chatChannelIdentifier!,
      data: {'action': 'leave_room', 'user_id': int.parse(userId)},
    );
    log.d('Left chat room (userId=$userId)');
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
    log.i('WebSocket disconnected');
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
