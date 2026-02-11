part of 'chat_bloc.dart';

@immutable
sealed class ChatState {}

final class ChatInitial extends ChatState {}

final class ChatLoading extends ChatState {}

// WebSocket States
final class WebSocketConnected extends ChatState {}

final class WebSocketDisconnected extends ChatState {}

// Chat Rooms States
final class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> rooms;
  final bool isWebSocketConnected;

  ChatRoomsLoaded({required this.rooms, this.isWebSocketConnected = false});
}

final class ChatRoomSelected extends ChatState {
  final ChatRoom room;
  final List<ChatMessage> messages;
  final bool isWebSocketConnected;
  final bool hasMoreMessages; // ✨ NEW: บอกว่ายังมีข้อความเก่าให้โหลดอีกหรือไม่
  final int currentPage; // ✨ NEW: เก็บ page ปัจจุบัน

  ChatRoomSelected({
    required this.room,
    required this.messages,
    this.isWebSocketConnected = false,
    this.hasMoreMessages = true,
    this.currentPage = 1,
  });
}

// ✨ NEW: State สำหรับกำลังโหลดข้อความเก่าเพิ่ม
final class LoadingMoreMessages extends ChatState {
  final ChatRoom room;
  final List<ChatMessage> messages;
  final int currentPage;

  LoadingMoreMessages({
    required this.room,
    required this.messages,
    required this.currentPage,
  });
}

// Message States
final class MessageSending extends ChatState {
  final ChatRoom room;
  final List<ChatMessage> messages;

  MessageSending({required this.room, required this.messages});
}

final class MessageSent extends ChatState {
  final ChatRoom room;
  final List<ChatMessage> messages;

  MessageSent({required this.room, required this.messages});
}

final class NewMessageReceived extends ChatState {
  final ChatMessage message;
  final ChatRoom room;
  final List<ChatMessage> messages;

  NewMessageReceived({
    required this.message,
    required this.room,
    required this.messages,
  });
}

// Error State
final class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
