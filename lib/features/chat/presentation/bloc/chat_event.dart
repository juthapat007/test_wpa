part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent {}

// WebSocket Events
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

// Chat Room Events
class LoadChatRooms extends ChatEvent {}

/// Resets internal chat room state and reloads from the server.
/// Use this when re-entering the chat tab to get accurate unread counts.
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

// Message Events
class LoadChatHistory extends ChatEvent {
  final String roomId;
  final int? limit;
  LoadChatHistory(this.roomId, {this.limit});
}

// ✨ Event สำหรับโหลดข้อความเก่าเพิ่ม (infinite scroll)
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

/// Handles incoming read receipt from WebSocket (the other user read our message).
class MessageReadReceived extends ChatEvent {
  final String messageId;
  final DateTime readAt;
  MessageReadReceived({required this.messageId, required this.readAt});
}

/// Handles real-time message deletion from WebSocket.
class WebSocketMessageDeleted extends ChatEvent {
  final String messageId;
  WebSocketMessageDeleted({required this.messageId});
}

/// Handles real-time message edit from WebSocket.
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

// ============ 🆕 NEW: Typing Indicator Events ============

/// Received from WebSocket: other started typing
class TypingStarted extends ChatEvent {
  final String userId;
  TypingStarted(this.userId);
}

/// Received from WebSocket: other stopped typing
class TypingStopped extends ChatEvent {
  final String userId;
  TypingStopped(this.userId);
}

/// Send typing indicator to WebSocket
class SendTypingIndicator extends ChatEvent {
  final String recipientId;
  final bool isTyping;
  SendTypingIndicator({required this.recipientId, required this.isTyping});
}

// ============ 🆕 NEW: User Message Actions ============

/// Delete a message (local user action)
class DeleteMessageLocal extends ChatEvent {
  final String messageId;
  DeleteMessageLocal(this.messageId);
}

/// Edit a message (local user action)
class UpdateMessageLocal extends ChatEvent {
  final String messageId;
  final String newContent;
  UpdateMessageLocal({required this.messageId, required this.newContent});
}
