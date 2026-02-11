import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';

abstract class ChatRepository {
  // WebSocket
  Future<void> connectWebSocket();
  Future<void> disconnectWebSocket();
  Stream<ChatMessage> get messageStream;
  Stream<bool> get connectionStream;
  Future<void> sendMessage(ChatMessage message);

  // REST API
  Future<List<ChatRoom>> getChatRooms();

  // ✨ UPDATED: Return Map ที่มี messages และ metadata สำหรับ pagination
  Future<Map<String, dynamic>> getChatHistory(
    String roomId, {
    int? page,
    int? limit,
  });

  Future<ChatRoom> createChatRoom(String participantId);
  Future<void> markAsRead(String roomId);
}
