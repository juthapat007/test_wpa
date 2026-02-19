import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/data/repository/chat_repository_impl.dart';
import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _messageUpdatedSubscription;
  StreamSubscription? _typingSubscription;

  List<ChatRoom> _chatRooms = [];
  ChatRoom? _selectedRoom;
  List<ChatMessage> _messages = [];
  bool _isWebSocketConnected = false;
  String? _currentUserId;
  String? _currentUserName;

  final Set<String> _pendingReadReceipts = {};

  int _currentPage = 1;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  int get totalUnreadCount =>
      _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);

  String get currentUserId => _currentUserId ?? '0';

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    _initializeCurrentUserId();

    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<WebSocketMessageReceived>(_onWebSocketMessageReceived);
    on<WebSocketConnectionChanged>(_onWebSocketConnectionChanged);

    on<LoadChatRooms>(_onLoadChatRooms);
    on<ResetAndLoadChatRooms>(_onResetAndLoadChatRooms);
    on<SelectChatRoom>(_onSelectChatRoom);
    on<BackToRoomList>(_onBackToRoomList);
    on<CreateChatRoom>(_onCreateChatRoom);

    on<LoadChatHistory>(_onLoadChatHistory);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<MessageReadReceived>(_onMessageReadReceived);
    on<WebSocketMessageDeleted>(_onWebSocketMessageDeleted);
    on<WebSocketMessageUpdated>(_onWebSocketMessageUpdated);

    on<TypingStarted>(_onTypingStarted);
    on<TypingStopped>(_onTypingStopped);
    on<SendTypingIndicator>(_onSendTypingIndicator);

    on<DeleteMessageLocal>(_onDeleteMessageLocal);
    on<UpdateMessageLocal>(_onUpdateMessageLocal);
  }

  Future<void> _onConnectWebSocket(
    ConnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _messageSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _readReceiptSubscription?.cancel();
      await _messageDeletedSubscription?.cancel();
      await _messageUpdatedSubscription?.cancel();
      await chatRepository.connectWebSocket();

      _messageSubscription = chatRepository.messageStream.listen(
        (message) => add(WebSocketMessageReceived(message)),
      );

      _connectionSubscription = chatRepository.connectionStream.listen(
        (isConnected) => add(WebSocketConnectionChanged(isConnected)),
      );

      _readReceiptSubscription = chatRepository.readReceiptStream.listen(
        (receipt) => add(
          MessageReadReceived(
            messageId: receipt.messageId,
            readAt: receipt.readAt,
          ),
        ),
      );

      _messageDeletedSubscription = chatRepository.messageDeletedStream.listen(
        (event) => add(WebSocketMessageDeleted(messageId: event.messageId)),
      );

      _messageUpdatedSubscription = chatRepository.messageUpdatedStream.listen(
        (event) => add(
          WebSocketMessageUpdated(
            messageId: event.messageId,
            content: event.content,
            editedAt: event.editedAt,
          ),
        ),
      );

      _typingSubscription = chatRepository.typingStream.listen((event) {
        if (event.isTyping) {
          add(TypingStarted(event.userId));
        } else {
          add(TypingStopped(event.userId));
        }
      });
    } catch (e) {
      emit(ChatError('Failed to connect WebSocket: $e'));
    }
  }

  void _onTypingStarted(TypingStarted event, Emitter<ChatState> emit) {
    if (_selectedRoom == null || _selectedRoom!.participantId != event.userId) {
      return;
    }
    emit(
      ChatRoomSelected(
        room: _selectedRoom!,
        messages: _messages,
        isWebSocketConnected: _isWebSocketConnected,
        hasMoreMessages: _hasMoreMessages,
        currentPage: _currentPage,
        isTyping: true,
      ),
    );
  }

  void _onTypingStopped(TypingStopped event, Emitter<ChatState> emit) {
    if (_selectedRoom == null || _selectedRoom!.participantId != event.userId) {
      return;
    }
    emit(
      ChatRoomSelected(
        room: _selectedRoom!,
        messages: _messages,
        isWebSocketConnected: _isWebSocketConnected,
        hasMoreMessages: _hasMoreMessages,
        currentPage: _currentPage,
        isTyping: false,
      ),
    );
  }

  Future<void> _onSendTypingIndicator(
    SendTypingIndicator event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (chatRepository as ChatRepositoryImpl).sendTypingIndicator(
        event.recipientId,
        event.isTyping,
      );
    } catch (e) {
      print('❌ Failed to send typing indicator: $e');
    }
  }

  Future<void> _onDeleteMessageLocal(
    DeleteMessageLocal event,
    Emitter<ChatState> emit,
  ) async {
    if (_selectedRoom == null) return;
    try {
      await (chatRepository as ChatRepositoryImpl).deleteMessage(
        event.messageId,
      );
      _messages = _messages.where((m) => m.id != event.messageId).toList();
      emit(
        ChatRoomSelected(
          room: _selectedRoom!,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
          hasMoreMessages: _hasMoreMessages,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      emit(ChatError('Failed to delete message'));
      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
            hasMoreMessages: _hasMoreMessages,
            currentPage: _currentPage,
          ),
        );
      }
    }
  }

  Future<void> _onUpdateMessageLocal(
    UpdateMessageLocal event,
    Emitter<ChatState> emit,
  ) async {
    if (_selectedRoom == null) return;
    try {
      await (chatRepository as ChatRepositoryImpl).updateMessage(
        event.messageId,
        event.newContent,
      );
      _messages = _messages.map((m) {
        if (m.id == event.messageId) {
          return m.copyWith(
            content: event.newContent,
            editedAt: DateTime.now(),
          );
        }
        return m;
      }).toList();
      emit(
        ChatRoomSelected(
          room: _selectedRoom!,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
          hasMoreMessages: _hasMoreMessages,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      emit(ChatError('Failed to update message'));
      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
            hasMoreMessages: _hasMoreMessages,
            currentPage: _currentPage,
          ),
        );
      }
    }
  }

  void _onMessageReadReceived(
    MessageReadReceived event,
    Emitter<ChatState> emit,
  ) {
    bool hasChanges = false;
    _messages = _messages.map((m) {
      if (m.id == event.messageId && !m.isRead) {
        hasChanges = true;
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    if (hasChanges && _selectedRoom != null) {
      emit(
        ChatRoomSelected(
          room: _selectedRoom!,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
          hasMoreMessages: _hasMoreMessages,
          currentPage: _currentPage,
        ),
      );
    }
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    if (_selectedRoom != null) {
      try {
        await (chatRepository as ChatRepositoryImpl).leaveRoom(
          _selectedRoom!.participantId,
        );
      } catch (e) {
        print('🚪 ⚠️ Failed to leave room on disconnect: $e');
      }
    }
    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _readReceiptSubscription?.cancel();
    await _messageDeletedSubscription?.cancel();
    await _messageUpdatedSubscription?.cancel();
    await chatRepository.disconnectWebSocket();
    _isWebSocketConnected = false;
    emit(WebSocketDisconnected());
  }

  Future<void> _initializeCurrentUserId() async {
    try {
      const storage = FlutterSecureStorage();
      final userDataJson = await storage.read(key: 'user_data');
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        _currentUserId = userData['id'].toString();
        _currentUserName = userData['name'] ?? userData['full_name'] ?? 'Me';
      }
    } catch (e) {
      print('❌ ChatBloc: Failed to get current user ID: $e');
    }
  }

  void _onWebSocketMessageReceived(
    WebSocketMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final message = event.message;

    final existingIndex = _messages.indexWhere((m) {
      if (m.id == message.id) return true;
      if (m.senderId == message.senderId &&
          m.content == message.content &&
          m.createdAt.difference(message.createdAt).inSeconds.abs() < 5) {
        return true;
      }
      return false;
    });

    if (existingIndex != -1) {
      _messages[existingIndex] = message;
      if (_selectedRoom != null) {
        final updatedRoom = _selectedRoom!.copyWith(
          lastMessage: message,
          lastActiveAt: message.createdAt,
        );
        _selectedRoom = updatedRoom;
        emit(
          ChatRoomSelected(
            room: updatedRoom,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
            hasMoreMessages: _hasMoreMessages,
            currentPage: _currentPage,
          ),
        );
      }
      return;
    }

    if (_selectedRoom != null &&
        (message.senderId == _selectedRoom!.participantId ||
            message.receiverId == _selectedRoom!.participantId)) {
      _messages = [..._messages, message];
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
      if (message.senderId == _selectedRoom!.participantId) {
        add(MarkAsRead(_selectedRoom!.participantId));
      }
    } else {
      _updateChatRoomsWithNewMessage(message, emit);
    }
  }

  void _updateChatRoomsWithNewMessage(
    ChatMessage message,
    Emitter<ChatState> emit,
  ) {
    final roomIndex = _chatRooms.indexWhere(
      (room) => room.participantId == message.senderId,
    );
    if (roomIndex != -1) {
      final room = _chatRooms[roomIndex];
      final updatedRoom = room.copyWith(
        lastMessage: message,
        lastActiveAt: message.createdAt,
        unreadCount: room.unreadCount + 1,
      );
      _chatRooms.removeAt(roomIndex);
      _chatRooms.insert(0, updatedRoom);
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    } else {
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
      if (_selectedRoom != null) {
        try {
          (chatRepository as ChatRepositoryImpl).enterRoom(
            _selectedRoom!.participantId,
          );
        } catch (e) {
          print('Failed to re-enter room after reconnect: $e');
        }
      }
    } else {
      emit(WebSocketDisconnected());
    }
  }

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

  Future<void> _onResetAndLoadChatRooms(
    ResetAndLoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _selectedRoom = null;
      _messages = [];
      _currentPage = 1;
      _hasMoreMessages = true;
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

  void _onBackToRoomList(BackToRoomList event, Emitter<ChatState> emit) async {
    if (_selectedRoom != null) {
      try {
        await (chatRepository as ChatRepositoryImpl).leaveRoom(
          _selectedRoom!.participantId,
        );
      } catch (e) {
        print('🚪 ⚠️ Failed to leave room: $e');
      }
    }
    _selectedRoom = null;
    _messages = [];
    _currentPage = 1;
    _hasMoreMessages = true;
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
      _currentPage = 1;
      _hasMoreMessages = true;

      try {
        await (chatRepository as ChatRepositoryImpl).enterRoom(
          event.room.participantId,
        );
      } catch (e) {
        print('🚪 ⚠️ Failed to enter room: $e');
      }

      final response = await chatRepository.getChatHistory(
        event.room.id,
        page: 1,
        limit: 50,
      );

      _messages = response['messages'];
      final totalPages = response['totalPages'] ?? 1;
      _hasMoreMessages = _currentPage < totalPages;

      emit(
        ChatRoomSelected(
          room: event.room,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
          hasMoreMessages: _hasMoreMessages,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      emit(ChatError('Failed to load chat history: $e'));
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (_isLoadingMore || !_hasMoreMessages || _selectedRoom == null) return;

    _isLoadingMore = true;
    final nextPage = event.page;

    emit(
      LoadingMoreMessages(
        room: _selectedRoom!,
        messages: _messages,
        currentPage: _currentPage,
      ),
    );

    try {
      final response = await chatRepository.getChatHistory(
        event.roomId,
        page: nextPage,
        limit: event.limit,
      );

      final newMessages = response['messages'] as List<ChatMessage>;
      final totalPages = response['totalPages'] ?? nextPage;

      if (newMessages.isNotEmpty) {
        _messages = [...newMessages, ..._messages];
        _currentPage = nextPage;
        _hasMoreMessages = nextPage < totalPages;
      } else {
        _hasMoreMessages = false;
      }

      emit(
        ChatRoomSelected(
          room: _selectedRoom!,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
          hasMoreMessages: _hasMoreMessages,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      emit(ChatError('Failed to load more messages: $e'));
      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
            hasMoreMessages: _hasMoreMessages,
            currentPage: _currentPage,
          ),
        );
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  // ✅ แก้ไขแล้ว: เช็คก่อนว่ามีห้องแชทกับคนนี้อยู่แล้วหรือเปล่า
  // ถ้ามี → เปิดห้องเดิมพร้อมประวัติแชท
  // ถ้าไม่มี → สร้างห้องใหม่
  Future<void> _onCreateChatRoom(
    CreateChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // 1️⃣ ถ้ายังไม่ได้โหลด chat rooms → โหลดก่อน เพื่อเช็คว่ามีห้องอยู่แล้วหรือเปล่า
      if (_chatRooms.isEmpty) {
        try {
          _chatRooms = await chatRepository.getChatRooms();
        } catch (_) {
          // ถ้าโหลดไม่ได้ก็ข้ามไป สร้างห้องใหม่เลย
        }
      }

      // 2️⃣ เช็คว่ามีห้องที่คุยกับคนนี้อยู่แล้วหรือเปล่า
      final existingRoom = _chatRooms
          .where((r) => r.participantId == event.participantId)
          .firstOrNull;

      if (existingRoom != null) {
        // ✅ มีห้องอยู่แล้ว → เปิดห้องเดิมพร้อมประวัติแชทเดิม
        add(SelectChatRoom(existingRoom));
        return;
      }

      // 3️⃣ ยังไม่มีห้อง → สร้างใหม่
      final newRoom = await chatRepository.createChatRoom(
        event.participantId,
        title: event.participantName,
      );

      if (!_chatRooms.any((r) => r.participantId == newRoom.participantId)) {
        _chatRooms = [newRoom, ..._chatRooms];
      }

      add(SelectChatRoom(newRoom));
    } catch (e) {
      emit(ChatError('Failed to create chat room: $e'));
    }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await chatRepository.getChatHistory(
        event.roomId,
        page: 1,
        limit: event.limit ?? 50,
      );

      _messages = response['messages'];
      _currentPage = 1;
      _hasMoreMessages = _currentPage < (response['totalPages'] ?? 1);

      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
            hasMoreMessages: _hasMoreMessages,
            currentPage: _currentPage,
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

    final senderId = _currentUserId ?? '0';

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: _currentUserName ?? 'Me',
      receiverId: _selectedRoom!.participantId,
      chatRoomId: int.tryParse(_selectedRoom!.id) ?? 0,
      content: event.content,
      createdAt: DateTime.now(),
      type: event.type,
    );

    _messages = [..._messages, message];
    emit(MessageSending(room: _selectedRoom!, messages: _messages));

    try {
      await chatRepository.sendMessage(message);
      emit(MessageSent(room: _selectedRoom!, messages: _messages));
    } catch (e) {
      _messages = _messages.where((m) => m.id != message.id).toList();
      emit(ChatError('Failed to send message: $e'));
      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
            hasMoreMessages: _hasMoreMessages,
            currentPage: _currentPage,
          ),
        );
      }
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.markAsRead(event.roomId);

      _chatRooms = _chatRooms.map((room) {
        if (room.id == event.roomId) return room.copyWith(unreadCount: 0);
        return room;
      }).toList();

      if (_selectedRoom?.id == event.roomId) {
        _selectedRoom = _selectedRoom!.copyWith(unreadCount: 0);
      }

      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
            hasMoreMessages: _hasMoreMessages,
            currentPage: _currentPage,
          ),
        );
      } else {
        emit(
          ChatRoomsLoaded(
            rooms: _chatRooms,
            isWebSocketConnected: _isWebSocketConnected,
          ),
        );
      }
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  void _onWebSocketMessageDeleted(
    WebSocketMessageDeleted event,
    Emitter<ChatState> emit,
  ) {
    final existed = _messages.any((m) => m.id == event.messageId);
    if (!existed) return;

    _messages = _messages.where((m) => m.id != event.messageId).toList();

    if (_selectedRoom != null) {
      emit(
        ChatRoomSelected(
          room: _selectedRoom!,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
          hasMoreMessages: _hasMoreMessages,
          currentPage: _currentPage,
        ),
      );
    }
  }

  void _onWebSocketMessageUpdated(
    WebSocketMessageUpdated event,
    Emitter<ChatState> emit,
  ) {
    bool hasChanges = false;
    _messages = _messages.map((m) {
      if (m.id == event.messageId) {
        hasChanges = true;
        return m.copyWith(content: event.content);
      }
      return m;
    }).toList();

    if (hasChanges && _selectedRoom != null) {
      emit(
        ChatRoomSelected(
          room: _selectedRoom!,
          messages: _messages,
          isWebSocketConnected: _isWebSocketConnected,
          hasMoreMessages: _hasMoreMessages,
          currentPage: _currentPage,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    if (_selectedRoom != null) {
      try {
        await (chatRepository as ChatRepositoryImpl).leaveRoom(
          _selectedRoom!.participantId,
        );
      } catch (e) {
        print('🚪 ⚠️ Failed to leave room on close: $e');
      }
    }
    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _readReceiptSubscription?.cancel();
    await _messageDeletedSubscription?.cancel();
    await _messageUpdatedSubscription?.cancel();
    await _typingSubscription?.cancel();
    await chatRepository.disconnectWebSocket();
    return super.close();
  }
}
