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
  LoadChatHistory(this.roomId, { this.limit});
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
