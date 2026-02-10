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
  Future<List<ChatMessage>> getChatHistory(String roomId, {int? limit});
  Future<ChatRoom> createChatRoom(String participantId);
  Future<void> markAsRead(String roomId);
}
