import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;

  // Local state
  List<ChatRoom> _chatRooms = [];
  ChatRoom? _selectedRoom;
  List<ChatMessage> _messages = [];
  bool _isWebSocketConnected = false;
  String? _currentUserId; // จะได้จาก auth

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    // WebSocket Events
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<WebSocketMessageReceived>(_onWebSocketMessageReceived);
    on<WebSocketConnectionChanged>(_onWebSocketConnectionChanged);

    // Chat Room Events
    on<LoadChatRooms>(_onLoadChatRooms);
    on<SelectChatRoom>(_onSelectChatRoom);
    on<BackToRoomList>(_onBackToRoomList);
    on<CreateChatRoom>(_onCreateChatRoom);

    // Message Events
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
  }

  // ==================== WebSocket Handlers ====================

  Future<void> _onConnectWebSocket(
    ConnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.connectWebSocket();

      // ฟังข้อความที่เข้ามา
      _messageSubscription = chatRepository.messageStream.listen(
        (message) => add(WebSocketMessageReceived(message)),
      );

      // ฟังสถานะการเชื่อมต่อ
      _connectionSubscription = chatRepository.connectionStream.listen(
        (isConnected) => add(WebSocketConnectionChanged(isConnected)),
      );
    } catch (e) {
      emit(ChatError('Failed to connect WebSocket: $e'));
    }
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await chatRepository.disconnectWebSocket();
    _isWebSocketConnected = false;
    emit(WebSocketDisconnected());
  }

  void _onWebSocketMessageReceived(
    WebSocketMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final message = event.message;

    // 📩 ถ้ากำลังอยู่ในห้องแชทนั้น
    if (_selectedRoom != null &&
        (message.senderId == _selectedRoom!.participantId ||
            message.receiverId == _selectedRoom!.participantId)) {
      // เพิ่มข้อความเข้าไปใน list
      _messages = [..._messages, message];

      // Update chat room's last message
      final updatedRoom = _selectedRoom!.copyWith(
        lastMessage: message,
        lastActiveAt: message.createdAt,
      );
      _selectedRoom = updatedRoom;

      emit(
        NewMessageReceived(
          message: message,
          room: updatedRoom,
          messages: _messages,
        ),
      );

      // 📖 Mark as read ถ้าข้อความมาจากคนอื่น
      if (message.senderId == _selectedRoom!.participantId) {
        add(MarkAsRead(_selectedRoom!.participantId));
      }
    }
    // 🔔 ถ้าไม่ได้อยู่ในห้องนั้น = เพิ่ม unread count
    else {
      _updateChatRoomsWithNewMessage(message, emit);
    }
  }

  // 🔔 Update chat rooms เมื่อมีข้อความใหม่เข้ามา (แต่ไม่ได้อยู่ในห้องนั้น)
  void _updateChatRoomsWithNewMessage(
    ChatMessage message,
    Emitter<ChatState> emit,
  ) {
    // หา room ที่ข้อความมาจาก
    final roomIndex = _chatRooms.indexWhere(
      (room) => room.participantId == message.senderId,
    );

    if (roomIndex != -1) {
      // อัพเดท room นั้น
      final room = _chatRooms[roomIndex];
      final updatedRoom = room.copyWith(
        lastMessage: message,
        lastActiveAt: message.createdAt,
        unreadCount: room.unreadCount + 1, // 🔔 เพิ่ม unread
      );

      // ย้าย room นี้ขึ้นไปอันดับแรก (เรียงตาม lastActiveAt)
      _chatRooms.removeAt(roomIndex);
      _chatRooms.insert(0, updatedRoom);

      // Emit state ใหม่
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    } else {
      // ถ้าไม่มี room นี้ (คนใหม่ส่งข้อความมา) ให้โหลด rooms ใหม่
      add(LoadChatRooms());
    }
  }

  void _onWebSocketConnectionChanged(
    WebSocketConnectionChanged event,
    Emitter<ChatState> emit,
  ) {
    _isWebSocketConnected = event.isConnected;

    if (event.isConnected) {
      emit(WebSocketConnected());
    } else {
      emit(WebSocketDisconnected());
    }
  }

  // ==================== Chat Room Handlers ====================

  Future<void> _onLoadChatRooms(
    LoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _chatRooms = await chatRepository.getChatRooms();
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    } catch (e) {
      emit(ChatError('Failed to load chat rooms: $e'));
      emit(
        ChatRoomsLoaded(rooms: [], isWebSocketConnected: _isWebSocketConnected),
      );
    }
  }

  void _onBackToRoomList(BackToRoomList event, Emitter<ChatState> emit) {
    // Clear selected room
    _selectedRoom = null;
    _messages = [];

    // กลับไปหน้า list โดยไม่ต้องโหลดใหม่
    emit(
      ChatRoomsLoaded(
        rooms: _chatRooms,
        isWebSocketConnected: _isWebSocketConnected,
      ),
    );
  }

  Future<void> _onSelectChatRoom(
    SelectChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _selectedRoom = event.room;
      _messages = await chatRepository.getChatHistory(event.room.id);

      // Mark as read
      if (event.room.unreadCount > 0) {
        add(MarkAsRead(event.room.id));
      }

      emit(
        ChatRoomSelected(
          room: event.room,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    } catch (e) {
      emit(ChatError('Failed to load chat history: $e'));
      // กลับไปที่ ChatRoomsLoaded แทนการค้างที่ Error
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    }
  }

  Future<void> _onCreateChatRoom(
    CreateChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final newRoom = await chatRepository.createChatRoom(event.participantId);
      _chatRooms = [newRoom, ..._chatRooms];

      // Auto-select the new room
      add(SelectChatRoom(newRoom));
    } catch (e) {
      emit(ChatError('Failed to create chat room: $e'));
    }
  }

  // ==================== Message Handlers ====================

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final messages = await chatRepository.getChatHistory(
        event.roomId,
        limit: event.limit,
      );
      _messages = messages;

      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
          ),
        );
      }
    } catch (e) {
      emit(ChatError('Failed to load messages: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_selectedRoom == null) return;

    // สร้าง message object
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId ?? '1', // TODO: ดึงจาก AuthBloc
      senderName: 'Me',
      receiverId: _selectedRoom!.participantId,
      content: event.content,
      createdAt: DateTime.now(),
      type: event.type,
    );

    // Optimistic update
    _messages = [..._messages, message];
    emit(MessageSending(room: _selectedRoom!, messages: _messages));

    try {
      // ส่งผ่าน WebSocket
      await chatRepository.sendMessage(message);

      emit(MessageSent(room: _selectedRoom!, messages: _messages));
    } catch (e) {
      // ถ้าส่งไม่สำเร็จ ให้ลบข้อความออก
      _messages = _messages.where((m) => m.id != message.id).toList();
      emit(ChatError('Failed to send message: $e'));

      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
          ),
        );
      }
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.markAsRead(event.roomId);

      // Update local chat room
      _chatRooms = _chatRooms.map((room) {
        if (room.id == event.roomId) {
          return room.copyWith(unreadCount: 0);
        }
        return room;
      }).toList();

      if (_selectedRoom?.id == event.roomId) {
        _selectedRoom = _selectedRoom!.copyWith(unreadCount: 0);
      }

      // 🔔 Emit state ใหม่เพื่ออัพเดท badge
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    } catch (e) {
      // Silent fail - not critical
      print('Failed to mark as read: $e');
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    chatRepository.disconnectWebSocket();
    return super.close();
  }
}
