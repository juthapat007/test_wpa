import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  String? _currentUserId;
  
  // ✨ NEW: Pagination state
  int _currentPage = 1;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  /// Getter สำหรับ total unread count (ใช้ใน bottom nav badge)
  int get totalUnreadCount =>
      _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);

  /// Getter สำหรับ current user ID (ใช้ใน UI)
  String get currentUserId => _currentUserId ?? '0';

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    // Initialize current user ID
    _initializeCurrentUserId();

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
    on<LoadMoreMessages>(_onLoadMoreMessages); // ✨ NEW
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
  }

  /// Initialize current user ID from secure storage
  Future<void> _initializeCurrentUserId() async {
    try {
      const storage = FlutterSecureStorage();
      final userDataJson = await storage.read(key: 'user_data');

      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        _currentUserId = userData['id'].toString();
        print('✅ ChatBloc: Current user ID set to $_currentUserId');
      } else {
        print('⚠️ ChatBloc: No user_data found in storage');
      }
    } catch (e) {
      print('❌ ChatBloc: Failed to get current user ID: $e');
    }
  }

  // ==================== WebSocket Handlers ====================

  Future<void> _onConnectWebSocket(
    ConnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.connectWebSocket();

      _messageSubscription = chatRepository.messageStream.listen(
        (message) => add(WebSocketMessageReceived(message)),
      );

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

    print('📩 WebSocket message received:');
    print('   - Message ID: ${message.id}');
    print('   - From: ${message.senderId}');
    print('   - To: ${message.receiverId}');
    print('   - Content: ${message.content}');

    // ตรวจสอบ duplicate
    final isDuplicate = _messages.any((m) => m.id == message.id);
    if (isDuplicate) {
      print('⚠️ Duplicate message detected, skipping');
      return;
    }

    // ถ้ากำลังอยู่ในห้องแชทนั้น
    if (_selectedRoom != null &&
        (message.senderId == _selectedRoom!.participantId ||
            message.receiverId == _selectedRoom!.participantId)) {
      print('✅ Adding message to current room');

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

      // Mark as read ถ้าข้อความมาจากคนอื่น
      if (message.senderId == _selectedRoom!.participantId) {
        add(MarkAsRead(_selectedRoom!.participantId));
      }
    }
    // ถ้าไม่ได้อยู่ในห้องนั้น = เพิ่ม unread count
    else {
      print('📬 Message for other room, updating room list');
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

  // ✨ UPDATED: ลบส่วนกรอง/merge ออก เพราะ backend กรองให้แล้ว
  Future<void> _onSelectChatRoom(
    SelectChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _selectedRoom = event.room;
      _currentPage = 1;
      _hasMoreMessages = true;
      
      // โหลดข้อความหน้าแรก (page 1)
      final response = await chatRepository.getChatHistory(
        event.room.id,
        page: 1,
        limit: 50,
      );

      _messages = response['messages'];
      final totalPages = response['totalPages'] ?? 1;
      _hasMoreMessages = _currentPage < totalPages;

      print('💬 Selected room: ${event.room.participantName}');
      print('💬 Loaded ${_messages.length} messages (page 1/$totalPages)');

      // Mark as read
      if (event.room.unreadCount > 0) {
        add(MarkAsRead(event.room.id));
      }

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

  // ✨ NEW: Handler สำหรับ infinite scroll
  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    // ป้องกันการโหลดซ้ำ
    if (_isLoadingMore || !_hasMoreMessages || _selectedRoom == null) {
      print('⚠️ Skip loading more: isLoading=$_isLoadingMore, hasMore=$_hasMoreMessages');
      return;
    }

    _isLoadingMore = true;
    final nextPage = event.page;

    print('📥 Loading more messages: page $nextPage');

    // Emit loading state
    emit(LoadingMoreMessages(
      room: _selectedRoom!,
      messages: _messages,
      currentPage: _currentPage,
    ));

    try {
      final response = await chatRepository.getChatHistory(
        event.roomId,
        page: nextPage,
        limit: event.limit,
      );

      final newMessages = response['messages'] as List<ChatMessage>;
      final totalPages = response['totalPages'] ?? nextPage;

      if (newMessages.isNotEmpty) {
        // เพิ่มข้อความเก่าเข้าไปด้านหน้า list (เพราะ reverse: true)
        _messages = [...newMessages, ..._messages];
        _currentPage = nextPage;
        _hasMoreMessages = nextPage < totalPages;

        print('✅ Loaded ${newMessages.length} more messages (page $nextPage/$totalPages)');
      } else {
        _hasMoreMessages = false;
        print('⚠️ No more messages to load');
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
      print('❌ Error loading more messages: $e');
      emit(ChatError('Failed to load more messages: $e'));
      
      // กลับไปยัง state เดิม
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

  Future<void> _onCreateChatRoom(
    CreateChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final newRoom = await chatRepository.createChatRoom(event.participantId);
      _chatRooms = [newRoom, ..._chatRooms];

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

    print('📤 Sending message:');
    print('   - From (current user): $senderId');
    print('   - To: ${_selectedRoom!.participantId}');
    print('   - Content: ${event.content}');

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
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
      await chatRepository.sendMessage(message);

      print('✅ Message sent successfully');
      emit(MessageSent(room: _selectedRoom!, messages: _messages));
    } catch (e) {
      print('❌ Failed to send message: $e');

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
        if (room.id == event.roomId) {
          return room.copyWith(unreadCount: 0);
        }
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

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    chatRepository.disconnectWebSocket();
    return super.close();
  }
}