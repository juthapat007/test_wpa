part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent {}

// ─── WebSocket ────────────────────────────────────────────────────────────────

class ConnectWebSocket extends ChatEvent {}

class DisconnectWebSocket extends ChatEvent {}

class WebSocketMessageReceived extends ChatEvent {
  final ChatMessage message;
  WebSocketMessageReceived(this.message);
}

class WebSocketConnectionChanged extends ChatEvent {
  final bool isConnected;
  WebSocketConnectionChanged(this.isConnected);
}

// ─── Chat Rooms ───────────────────────────────────────────────────────────────

class LoadChatRooms extends ChatEvent {}

/// Reset internal state แล้วโหลดใหม่จาก server
/// ใช้เมื่อ re-enter chat tab เพื่อให้ unread count ถูกต้อง
class ResetAndLoadChatRooms extends ChatEvent {}

class SelectChatRoom extends ChatEvent {
  final ChatRoom room;
  SelectChatRoom(this.room);
}

class BackToRoomList extends ChatEvent {}

class CreateChatRoom extends ChatEvent {
  final String participantId;
  final String participantName;
  CreateChatRoom(this.participantId, this.participantName);
}

// ─── Messages ─────────────────────────────────────────────────────────────────

class LoadChatHistory extends ChatEvent {
  final String roomId;
  final int? limit;
  LoadChatHistory(this.roomId, {this.limit});
}

class LoadMoreMessages extends ChatEvent {
  final String roomId;
  final int page;
  final int limit;
  LoadMoreMessages({required this.roomId, required this.page, this.limit = 50});
}

class SendMessage extends ChatEvent {
  final String roomId;
  final String content;
  final MessageType type;

  SendMessage({
    required this.roomId,
    required this.content,
    this.type = MessageType.text,
  });
}

class MarkAsRead extends ChatEvent {
  final String roomId;
  MarkAsRead(this.roomId);
}

class MarkAllChatsRead extends ChatEvent {}

/// Read receipt จาก WebSocket — อีกฝ่ายอ่านข้อความของเราแล้ว
class MessageReadReceived extends ChatEvent {
  final String messageId;
  final DateTime readAt;
  MessageReadReceived({required this.messageId, required this.readAt});
}

/// Real-time message deletion จาก WebSocket
class WebSocketMessageDeleted extends ChatEvent {
  final String messageId;
  WebSocketMessageDeleted({required this.messageId});
}

/// Real-time message edit จาก WebSocket
class WebSocketMessageUpdated extends ChatEvent {
  final String messageId;
  final String content;
  final DateTime editedAt;
  WebSocketMessageUpdated({
    required this.messageId,
    required this.content,
    required this.editedAt,
  });
}

// ─── Typing ───────────────────────────────────────────────────────────────────

/// อีกฝ่ายเริ่มพิมพ์
class TypingStarted extends ChatEvent {
  final String userId;
  TypingStarted(this.userId);
}

/// อีกฝ่ายหยุดพิมพ์
class TypingStopped extends ChatEvent {
  final String userId;
  TypingStopped(this.userId);
}

/// ส่ง typing indicator ไปยัง WebSocket
class SendTypingIndicator extends ChatEvent {
  final String recipientId;
  final bool isTyping;
  SendTypingIndicator({required this.recipientId, required this.isTyping});
}

// ─── User Actions ─────────────────────────────────────────────────────────────

/// ลบข้อความ (action จาก user ฝั่งเรา)
class DeleteMessageLocal extends ChatEvent {
  final String messageId;
  DeleteMessageLocal(this.messageId);
}

/// แก้ไขข้อความ (action จาก user ฝั่งเรา)
class UpdateMessageLocal extends ChatEvent {
  final String messageId;
  final String newContent;
  UpdateMessageLocal({required this.messageId, required this.newContent});
}
