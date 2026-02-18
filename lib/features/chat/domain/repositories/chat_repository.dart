import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/data/services/chat_websocket_service.dart'
    show ReadReceiptEvent, MessageDeletedEvent, MessageUpdatedEvent;

abstract class ChatRepository {
  // WebSocket
  Future<void> connectWebSocket();
  Future<void> disconnectWebSocket();
  Stream<ChatMessage> get messageStream;
  Stream<bool> get connectionStream;
  Stream<ReadReceiptEvent> get readReceiptStream;
  Stream<MessageDeletedEvent> get messageDeletedStream;
  Stream<MessageUpdatedEvent> get messageUpdatedStream;
  Stream<TypingEvent> get typingStream; // 🆕 NEW
  Future<void> sendMessage(ChatMessage message);

  // REST API
  Future<List<ChatRoom>> getChatRooms();

  // ✨ UPDATED: Return Map ที่มี messages และ metadata สำหรับ pagination
  Future<Map<String, dynamic>> getChatHistory(
    String roomId, {
    int? page,
    int? limit,
  });

  Future<ChatRoom> createChatRoom(String participantId, {String title = ''});
  Future<void> markAsRead(String roomId);

  /// Mark a single message as read by its ID
  Future<void> markMessageAsRead(String messageId);

  // 🆕 NEW: Message actions
  Future<void> updateMessage(String messageId, String content);
  Future<void> deleteMessage(String messageId);
}

// 🆕 NEW: Typing event data class
class TypingEvent {
  final String userId;
  final bool isTyping;

  TypingEvent({required this.userId, required this.isTyping});
}
