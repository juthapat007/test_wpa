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
  Stream<TypingEvent> get typingStream;
  Stream<String> get roomDeletedStream;

  Future<void> sendMessage(ChatMessage message, {String? imageBase64});

  // REST API
  Future<List<ChatRoom>> getChatRooms();
  Future<Map<String, dynamic>> getChatHistory(
    String roomId, {
    int? page,
    int? limit,
  });
  Future<ChatRoom> createChatRoom(String participantId, {String title = ''});
  Future<void> markAsRead(String roomId);
  Future<void> markMessageAsRead(String messageId);
  Future<void> updateMessage(String messageId, String content);
  Future<void> deleteMessage(String messageId);

  Future<int> deleteConversation(String partnerId);
}

class TypingEvent {
  final String userId;
  final bool isTyping;

  TypingEvent({required this.userId, required this.isTyping});
}
