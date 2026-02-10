import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ActionCable identifiers
  String? _chatChannelIdentifier;
  String? _notificationChannelIdentifier;

  ChatWebSocketService();

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  /// เชื่อมต่อ ActionCable WebSocket
  Future<void> connect(String token) async {
    try {
      final wsUrl = 'wss://wpa-docker.onrender.com/cable?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) {
          debugPrint('❌ WebSocket Error: $error');
          _isConnected = false;
          _connectionController.add(false);
        },
        onDone: () {
          debugPrint('🔌 WebSocket Disconnected');
          _isConnected = false;
          _connectionController.add(false);
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      debugPrint('✅ WebSocket Connected');

      // รอ welcome message แล้ว subscribe channels
      await Future.delayed(const Duration(milliseconds: 500));
      await _subscribeChannels();
    } catch (e) {
      debugPrint('❌ Failed to connect WebSocket: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
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

      // ActionCable system messages (welcome, ping, confirm_subscription)
      // มี 'type' อยู่ที่ root level
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
          // ActionCable data messages มา format:
          // { "identifier": "...", "message": { "type": "new_message", ... } }
          // ไม่มี 'type' ที่ root level (type == null)
          if (data['message'] != null && data['message'] is Map) {
            _handleActionCableDataMessage(data['message']);
          } else if (type != null) {
            debugPrint('Unknown system type: $type');
          }
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  /// จัดการ ActionCable data messages (ข้อความจริงจาก channel)
  void _handleActionCableDataMessage(Map<String, dynamic> message) {
    final messageType = message['type'] as String?;

    switch (messageType) {
      case 'new_message':
        _handleNewMessage(message['message'] ?? message);
        break;

      case 'message_read':
      case 'messages_read':
        debugPrint('Message(s) marked as read');
        break;

      case 'typing_start':
        debugPrint('User is typing...');
        break;

      case 'typing_stop':
        debugPrint('User stopped typing');
        break;

      case 'message_deleted':
        debugPrint('Message deleted: ${message['message_id']}');
        break;

      case 'message_updated':
        debugPrint('Message updated');
        break;

      case 'new_notification':
        debugPrint('New notification: ${message['notification']}');
        break;

      case 'announcement':
        debugPrint('Announcement: ${message['content']}');
        break;

      default:
        // บาง ActionCable server อาจส่ง message โดยไม่มี 'type' wrapper
        // ลองดูว่ามี sender/recipient field หรือไม่ (เป็น chat message โดยตรง)
        if (message.containsKey('sender') && message.containsKey('content')) {
          _handleNewMessage(message);
        } else {
          debugPrint('Unknown data message type: $messageType, data: $message');
        }
    }
  }

  /// จัดการข้อความใหม่
  void _handleNewMessage(Map<String, dynamic> messageData) {
    try {
      final message = ChatMessage(
        id: messageData['id'].toString(),
        senderId: messageData['sender']['id'].toString(),
        senderName: messageData['sender']['name'] ?? '',
        senderAvatar: messageData['sender']['avatar_url'],
        receiverId: messageData['recipient']['id'].toString(),
        content: messageData['content'] ?? '',
        createdAt: DateTime.parse(messageData['created_at']),
        isRead: messageData['read_at'] != null,
      );

      _messageController.add(message);
      debugPrint('📩 Received message: ${message.content}');
    } catch (e) {
      debugPrint('❌ Error handling new message: $e');
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
      'action': 'typing',
      'recipient_id': int.parse(recipientId),
      'typing': isTyping,
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
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _connectionController.add(false);
    debugPrint('🔌 WebSocket Disconnected');
  }

  /// ทำลาย resources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
