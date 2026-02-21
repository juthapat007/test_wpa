import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/core/constants/print_logger.dart';
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

  // ─── WebSocket ───────────────────────────────────────────────────────────

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
        add(
          event.isTyping
              ? TypingStarted(event.userId)
              : TypingStopped(event.userId),
        );
      });
    } catch (e) {
      log.e('Failed to connect WebSocket', error: e);
      emit(ChatError('Failed to connect WebSocket: $e'));
    }
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    await _leaveCurrentRoom();
    await _cancelAllSubscriptions();
    await chatRepository.disconnectWebSocket();
    _isWebSocketConnected = false;
    // ✅ ไม่ emit WebSocketDisconnected แยก — อัปเดต flag แล้ว re-emit state ปัจจุบัน
    _emitCurrentState(emit);
  }

  /// ✅ FIX: ไม่ emit WebSocketConnected/Disconnected แยกอีกต่อไป
  /// เพราะมันทำให้ BlocBuilder ไม่รู้จัก state แล้ว UI พัง
  /// แทนด้วยการอัปเดต flag แล้ว re-emit state ปัจจุบัน
  void _onWebSocketConnectionChanged(
    WebSocketConnectionChanged event,
    Emitter<ChatState> emit,
  ) {
    _isWebSocketConnected = event.isConnected;
    log.i('WebSocket connection changed: ${event.isConnected}');

    if (event.isConnected && _selectedRoom != null) {
      try {
        (chatRepository as ChatRepositoryImpl).enterRoom(
          _selectedRoom!.participantId,
        );
      } catch (e) {
        log.w('Failed to re-enter room after reconnect', error: e);
      }
    }

    _emitCurrentState(emit);
  }

  // ─── Typing ───────────────────────────────────────────────────────────────

  void _onTypingStarted(TypingStarted event, Emitter<ChatState> emit) {
    if (_selectedRoom == null || _selectedRoom!.participantId != event.userId)
      return;
    emit(_buildRoomState(isTyping: true));
  }

  void _onTypingStopped(TypingStopped event, Emitter<ChatState> emit) {
    if (_selectedRoom == null || _selectedRoom!.participantId != event.userId)
      return;
    emit(_buildRoomState(isTyping: false));
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
      log.w('Failed to send typing indicator', error: e);
    }
  }

  // ─── Chat Rooms ───────────────────────────────────────────────────────────

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
      log.e('Failed to load chat rooms', error: e);
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
    _selectedRoom = null;
    _messages = [];
    _currentPage = 1;
    _hasMoreMessages = true;
    try {
      _chatRooms = await chatRepository.getChatRooms();
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    } catch (e) {
      log.e('Failed to reset and load chat rooms', error: e);
      emit(ChatError('Failed to load chat rooms: $e'));
      emit(
        ChatRoomsLoaded(rooms: [], isWebSocketConnected: _isWebSocketConnected),
      );
    }
  }

  Future<void> _onBackToRoomList(
    BackToRoomList event,
    Emitter<ChatState> emit,
  ) async {
    await _leaveCurrentRoom();
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
        log.w('Failed to enter room', error: e);
      }

      final response = await chatRepository.getChatHistory(
        event.room.id,
        page: 1,
        limit: 50,
      );

      _messages = response['messages'];
      final totalPages = response['totalPages'] ?? 1;
      _hasMoreMessages = _currentPage < totalPages;

      emit(_buildRoomState());
    } catch (e) {
      log.e('Failed to load chat history', error: e);
      emit(ChatError('Failed to load chat history: $e'));
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
    try {
      if (_chatRooms.isEmpty) {
        try {
          _chatRooms = await chatRepository.getChatRooms();
        } catch (_) {}
      }

      final existingRoom = _chatRooms
          .where((r) => r.participantId == event.participantId)
          .firstOrNull;

      if (existingRoom != null) {
        add(SelectChatRoom(existingRoom));
        return;
      }

      final newRoom = await chatRepository.createChatRoom(
        event.participantId,
        title: event.participantName,
      );

      if (!_chatRooms.any((r) => r.participantId == newRoom.participantId)) {
        _chatRooms = [newRoom, ..._chatRooms];
      }

      add(SelectChatRoom(newRoom));
    } catch (e) {
      log.e('Failed to create chat room', error: e);
      emit(ChatError('Failed to create chat room: $e'));
    }
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

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

      if (_selectedRoom != null) emit(_buildRoomState());
    } catch (e) {
      log.e('Failed to load messages', error: e);
      emit(ChatError('Failed to load messages: $e'));
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

      emit(_buildRoomState());
    } catch (e) {
      log.e('Failed to load more messages', error: e);
      emit(ChatError('Failed to load more messages: $e'));
      if (_selectedRoom != null) emit(_buildRoomState());
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_selectedRoom == null) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId ?? '0',
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
      log.e('Failed to send message', error: e);
      _messages = _messages.where((m) => m.id != message.id).toList();
      emit(ChatError('Failed to send message: $e'));
      if (_selectedRoom != null) emit(_buildRoomState());
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.markAsRead(event.roomId);
      _chatRooms = _chatRooms.map((room) {
        return room.id == event.roomId ? room.copyWith(unreadCount: 0) : room;
      }).toList();
      if (_selectedRoom?.id == event.roomId) {
        _selectedRoom = _selectedRoom!.copyWith(unreadCount: 0);
      }
      _emitCurrentState(emit);
    } catch (e) {
      log.w('Failed to mark as read', error: e);
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

    if (hasChanges && _selectedRoom != null) emit(_buildRoomState());
  }

  void _onWebSocketMessageDeleted(
    WebSocketMessageDeleted event,
    Emitter<ChatState> emit,
  ) {
    if (!_messages.any((m) => m.id == event.messageId)) return;
    _messages = _messages.where((m) => m.id != event.messageId).toList();
    if (_selectedRoom != null) emit(_buildRoomState());
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
    if (hasChanges && _selectedRoom != null) emit(_buildRoomState());
  }

  void _onWebSocketMessageReceived(
    WebSocketMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final message = event.message;

    // ตรวจสอบข้อความซ้ำ
    final existingIndex = _messages.indexWhere((m) {
      if (m.id == message.id) return true;
      return m.senderId == message.senderId &&
          m.content == message.content &&
          m.createdAt.difference(message.createdAt).inSeconds.abs() < 5;
    });

    if (existingIndex != -1) {
      _messages[existingIndex] = message;
      if (_selectedRoom != null) {
        _selectedRoom = _selectedRoom!.copyWith(
          lastMessage: message,
          lastActiveAt: message.createdAt,
        );
        emit(_buildRoomState());
      }
      return;
    }

    if (_selectedRoom != null &&
        (message.senderId == _selectedRoom!.participantId ||
            message.receiverId == _selectedRoom!.participantId)) {
      _messages = [..._messages, message];
      _selectedRoom = _selectedRoom!.copyWith(
        lastMessage: message,
        lastActiveAt: message.createdAt,
      );
      emit(
        NewMessageReceived(
          message: message,
          room: _selectedRoom!,
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
      final updatedRoom = _chatRooms[roomIndex].copyWith(
        lastMessage: message,
        lastActiveAt: message.createdAt,
        unreadCount: _chatRooms[roomIndex].unreadCount + 1,
      );
      _chatRooms = [
        updatedRoom,
        ..._chatRooms.where((r) => r.participantId != message.senderId),
      ];
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

  // ─── Message Actions ──────────────────────────────────────────────────────

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
      emit(_buildRoomState());
    } catch (e) {
      log.e('Failed to delete message', error: e);
      emit(ChatError('Failed to delete message'));
      emit(_buildRoomState());
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
        return m.id == event.messageId
            ? m.copyWith(content: event.newContent, editedAt: DateTime.now())
            : m;
      }).toList();
      emit(_buildRoomState());
    } catch (e) {
      log.e('Failed to update message', error: e);
      emit(ChatError('Failed to update message'));
      emit(_buildRoomState());
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// ✅ Single source of truth สำหรับ emit state ของห้องแชท
  ChatRoomSelected _buildRoomState({bool isTyping = false}) {
    return ChatRoomSelected(
      room: _selectedRoom!,
      messages: _messages,
      isWebSocketConnected: _isWebSocketConnected,
      hasMoreMessages: _hasMoreMessages,
      currentPage: _currentPage,
      isTyping: isTyping,
    );
  }

  /// ✅ Re-emit state ปัจจุบันโดยไม่เปลี่ยน context (ใช้เมื่อ flag เปลี่ยนแต่ UI ไม่ควรกระโดด)
  void _emitCurrentState(Emitter<ChatState> emit) {
    if (_selectedRoom != null) {
      emit(_buildRoomState());
    } else {
      emit(
        ChatRoomsLoaded(
          rooms: _chatRooms,
          isWebSocketConnected: _isWebSocketConnected,
        ),
      );
    }
  }

  Future<void> _leaveCurrentRoom() async {
    if (_selectedRoom == null) return;
    try {
      await (chatRepository as ChatRepositoryImpl).leaveRoom(
        _selectedRoom!.participantId,
      );
    } catch (e) {
      log.w('Failed to leave room', error: e);
    }
  }

  Future<void> _cancelAllSubscriptions() async {
    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _readReceiptSubscription?.cancel();
    await _messageDeletedSubscription?.cancel();
    await _messageUpdatedSubscription?.cancel();
    await _typingSubscription?.cancel();
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
      log.e('Failed to get current user ID', error: e);
    }
  }

  @override
  Future<void> close() async {
    await _leaveCurrentRoom();
    await _cancelAllSubscriptions();
    await chatRepository.disconnectWebSocket();
    return super.close();
  }
}
