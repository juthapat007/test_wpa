import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/data/services/chat_api.dart';
import 'package:test_wpa/features/chat/data/services/chat_websocket_service.dart';
import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatApi api;
  final ChatWebSocketService webSocketService;
  final FlutterSecureStorage storage;

  ChatRepositoryImpl({
    required this.api,
    required this.webSocketService,
    required this.storage,
  });

  @override
  Future<void> connectWebSocket() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No auth token found');
    }
    await webSocketService.connect(token);
  }

  @override
  Future<void> disconnectWebSocket() async {
    await webSocketService.disconnect();
  }

  @override
  Stream<ChatMessage> get messageStream => webSocketService.messageStream;

  @override
  Stream<bool> get connectionStream => webSocketService.connectionStream;

  @override
  Future<void> sendMessage(ChatMessage message) async {
    // ส่งผ่าน WebSocket (real-time)
    await webSocketService.sendMessage(message);

    // หรือใช้ REST API (ถ้า WebSocket ไม่ได้เชื่อมต่อ)
    // try {
    //   await api.sendMessage(
    //     recipientId: message.receiverId,
    //     content: message.content,
    //   );
    // } catch (e) {
    //   throw Exception('Failed to send message: $e');
    // }
  }

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await api.getChatRooms();
      final List<dynamic> data = response.data;

      final rooms = data.map((json) {
        // แปลง API response เป็น ChatRoom model
        final delegate = json['delegate'];
        final lastMessageText = json['last_message'] as String?;
        final lastMessageAt = json['last_message_at'] as String?;

        return ChatRoom(
          id: delegate['id'].toString(),
          participantId: delegate['id'].toString(),
          participantName: delegate['name'] ?? 'Unknown',
          participantAvatar: delegate['avatar_url'], // อาจจะไม่มีใน response
          lastMessage: lastMessageText != null && lastMessageAt != null
              ? ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  senderId: delegate['id'].toString(),
                  senderName: delegate['name'] ?? '',
                  receiverId: '', // ไม่ทราบจาก response นี้
                  content: lastMessageText,
                  createdAt: DateTime.parse(lastMessageAt),
                )
              : null,
          unreadCount: json['unread_count'] ?? 0,
          lastActiveAt: lastMessageAt != null
              ? DateTime.parse(lastMessageAt)
              : null,
        );
      }).toList();

      // 📌 เรียงตาม lastActiveAt (ล่าสุดก่อน)
      rooms.sort((a, b) {
        if (a.lastActiveAt == null && b.lastActiveAt == null) return 0;
        if (a.lastActiveAt == null) return 1;
        if (b.lastActiveAt == null) return -1;
        return b.lastActiveAt!.compareTo(a.lastActiveAt!);
      });

      return rooms;
    } catch (e) {
      throw Exception('Failed to load chat rooms: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory(
    String partnerId, {
    int? limit,
  }) async {
    try {
      final response = await api.getChatHistory(partnerId: partnerId);
      final List<dynamic> data = response.data;

      final messages = data.map((json) {
        return ChatMessage(
          id: json['id'].toString(),
          senderId: json['sender']['id'].toString(),
          senderName: json['sender']['name'] ?? '',
          senderAvatar: json['sender']['avatar_url'],
          receiverId: json['recipient']['id'].toString(),
          content: json['content'] ?? '',
          createdAt: DateTime.parse(json['created_at']),
          isRead: json['read_at'] != null,
        );
      }).toList();

      // 📌 เรียงตาม createdAt (เก่าสุดก่อน เพื่อแสดงจากบนลงล่าง)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return messages;
    } catch (e) {
      throw Exception('Failed to load chat history: $e');
    }
  }

  @override
  Future<ChatRoom> createChatRoom(String participantId) async {
    // สำหรับ 1:1 chat ไม่จำเป็นต้องสร้างห้อง
    // แค่ส่งข้อความไปหาคนนั้นเลย
    // ระบบจะสร้างห้องอัตโนมัติ

    return ChatRoom(
      id: participantId,
      participantId: participantId,
      participantName: 'New Chat',
      unreadCount: 0,
    );
  }

  @override
  Future<void> markAsRead(String partnerId) async {
    try {
      await api.markAllAsRead(partnerId);
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// เพิ่ม methods สำหรับ typing indicator
  Future<void> sendTypingIndicator(String recipientId, bool isTyping) async {
    await webSocketService.sendTypingIndicator(recipientId, isTyping);
  }

  /// เข้า/ออกจากห้องแชท
  Future<void> enterRoom(String userId) async {
    await webSocketService.enterRoom(userId);
  }

  Future<void> leaveRoom(String userId) async {
    await webSocketService.leaveRoom(userId);
  }

  /// แก้ไข/ลบข้อความ
  Future<void> updateMessage(String messageId, String content) async {
    try {
      await api.updateMessage(messageId: messageId, content: content);
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await api.deleteMessage(messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
