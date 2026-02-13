// part of 'chat_bloc.dart';

// @immutable
// sealed class ChatEvent {}

// // WebSocket Events
// class ConnectWebSocket extends ChatEvent {}

// class DisconnectWebSocket extends ChatEvent {}

// class WebSocketMessageReceived extends ChatEvent {
//   final ChatMessage message;
//   WebSocketMessageReceived(this.message);
// }

// class WebSocketConnectionChanged extends ChatEvent {
//   final bool isConnected;
//   WebSocketConnectionChanged(this.isConnected);
// }

// // Chat Room Events
// class LoadChatRooms extends ChatEvent {}

// /// Resets internal chat room state and reloads from the server.
// /// Use this when re-entering the chat tab to get accurate unread counts.
// class ResetAndLoadChatRooms extends ChatEvent {}

// class SelectChatRoom extends ChatEvent {
//   final ChatRoom room;
//   SelectChatRoom(this.room);
// }

// class BackToRoomList extends ChatEvent {}

// class CreateChatRoom extends ChatEvent {
//   final String participantId;
//   CreateChatRoom(this.participantId);
// }

// // Message Events
// class LoadChatHistory extends ChatEvent {
//   final String roomId;
//   final int? limit;
//   LoadChatHistory(this.roomId, {this.limit});
// }

// // ✨ NEW: Event สำหรับโหลดข้อความเก่าเพิ่ม (infinite scroll)
// class LoadMoreMessages extends ChatEvent {
//   final String roomId;
//   final int page;
//   final int limit;

//   LoadMoreMessages({required this.roomId, required this.page, this.limit = 50});
// }

// class SendMessage extends ChatEvent {
//   final String roomId;
//   final String content;
//   final MessageType type;

//   SendMessage({
//     required this.roomId,
//     required this.content,
//     this.type = MessageType.text,
//   });
// }

// class MarkAsRead extends ChatEvent {
//   final String roomId;
//   MarkAsRead(this.roomId);
// }

// /// Marks individual unread messages as read when entering a conversation.
// class MarkMessagesAsReadInConversation extends ChatEvent {
//   final List<String> messageIds;
//   MarkMessagesAsReadInConversation(this.messageIds);
// }

// /// Handles incoming read receipt from WebSocket (the other user read our message).
// class MessageReadReceived extends ChatEvent {
//   final String messageId;
//   final DateTime readAt;
//   MessageReadReceived({required this.messageId, required this.readAt});
// }
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
  CreateChatRoom(this.participantId);
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
