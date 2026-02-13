import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
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

  // Local state
  List<ChatRoom> _chatRooms = [];
  ChatRoom? _selectedRoom;
  List<ChatMessage> _messages = [];
  bool _isWebSocketConnected = false;
  String? _currentUserId;

  // Pending read receipts: stores message IDs that were marked as read
  // before the new_message event arrived (race condition fix)
  final Set<String> _pendingReadReceipts = {};

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
    on<ResetAndLoadChatRooms>(_onResetAndLoadChatRooms);
    on<SelectChatRoom>(_onSelectChatRoom);
    on<BackToRoomList>(_onBackToRoomList);
    on<CreateChatRoom>(_onCreateChatRoom);

    // Message Events
    on<LoadChatHistory>(_onLoadChatHistory);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<MessageReadReceived>(_onMessageReadReceived);
    on<WebSocketMessageDeleted>(_onWebSocketMessageDeleted);
    on<WebSocketMessageUpdated>(_onWebSocketMessageUpdated);
  }

  Future<void> _onConnectWebSocket(
    ConnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Cancel existing subscriptions
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
        (event) => add(WebSocketMessageUpdated(
          messageId: event.messageId,
          content: event.content,
          editedAt: event.editedAt,
        )),
      );
    } catch (e) {
      emit(ChatError('Failed to connect WebSocket: $e'));
    }
  }

  // Handler for read receipt events (both single and bulk)
  void _onMessageReadReceived(
    MessageReadReceived event,
    Emitter<ChatState> emit,
  ) {
    print(
      'Read receipt received: Message ${event.messageId} read at ${event.readAt}',
    );

    final messageExists = _messages.any((m) => m.id == event.messageId);

    if (!messageExists) {
      // Race condition: bulk_read arrived before new_message.
      // Store in pending set so we can apply it when the message arrives.
      _pendingReadReceipts.add(event.messageId);
      print(
        'Message ${event.messageId} not in local state yet -- queued as pending read receipt.',
      );
      return;
    }

    // Update local message state
    bool hasChanges = false;
    _messages = _messages.map((m) {
      if (m.id == event.messageId && !m.isRead) {
        hasChanges = true;
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    // Emit updated state if in conversation AND we actually changed something
    if (hasChanges && _selectedRoom != null) {
      print('Updating UI with read receipt for message ${event.messageId}');
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

  // ✅ อย่าลืม cancel ตอน disconnect
  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    // 🔥 Leave room ก่อน disconnect
    if (_selectedRoom != null) {
      try {
        await (chatRepository as ChatRepositoryImpl).leaveRoom(
          _selectedRoom!.participantId,
        );
        print('🚪 ✅ Left room on disconnect');
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
    final isDuplicate = _messages.any((m) {
      if (m.id == message.id) return true;
      if (m.senderId == message.senderId &&
          m.content == message.content &&
          m.createdAt.difference(message.createdAt).inSeconds.abs() < 5) {
        return true;
      }
      return false;
    });

    if (isDuplicate) {
      print('⚠️ Duplicate message detected, skipping');
      return;
    }

    // Apply any pending read receipt from the race condition
    // (bulk_read arrived before new_message)
    ChatMessage finalMessage = message;
    if (_pendingReadReceipts.contains(message.id)) {
      finalMessage = message.copyWith(isRead: true);
      _pendingReadReceipts.remove(message.id);
      print('Applied pending read receipt to message ${message.id}');
    }

    // Check if the message belongs to the currently open chat room
    if (_selectedRoom != null &&
        (finalMessage.senderId == _selectedRoom!.participantId ||
            finalMessage.receiverId == _selectedRoom!.participantId)) {
      print('Adding message to current room');

      _messages = [..._messages, finalMessage];

      final updatedRoom = _selectedRoom!.copyWith(
        lastMessage: finalMessage,
        lastActiveAt: finalMessage.createdAt,
      );
      _selectedRoom = updatedRoom;

      emit(
        NewMessageReceived(
          message: finalMessage,
          room: updatedRoom,
          messages: _messages,
        ),
      );

      // Auto mark-as-read when receiving a message in the currently open room
      if (finalMessage.senderId == _selectedRoom!.participantId) {
        print('Auto-marking messages as read (we are in the room)');
        add(MarkAsRead(_selectedRoom!.participantId));
      }
    }
    // Message is for a room we are NOT currently viewing
    else {
      print('Message for other room, updating room list');
      _updateChatRoomsWithNewMessage(finalMessage, emit);
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

      // Re-enter the room after a reconnect so the backend knows
      // we are still viewing this conversation (fixes read receipts
      // and real-time events stopping after a brief disconnect).
      if (_selectedRoom != null) {
        try {
          (chatRepository as ChatRepositoryImpl).enterRoom(
            _selectedRoom!.participantId,
          );
          print('Re-entered room with ${_selectedRoom!.participantName} after reconnect');
        } catch (e) {
          print('Failed to re-enter room after reconnect: $e');
        }
      }
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

  /// Resets local chat room state and reloads fresh data from the server.
  Future<void> _onResetAndLoadChatRooms(
    ResetAndLoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      // Clear stale local state
      _selectedRoom = null;
      _messages = [];
      _currentPage = 1;
      _hasMoreMessages = true;

      // Reload fresh from API
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
    // 🔥 FIX: Leave room เมื่อออกจากห้องแชท
    if (_selectedRoom != null) {
      try {
        await (chatRepository as ChatRepositoryImpl).leaveRoom(
          _selectedRoom!.participantId,
        );
        print('🚪 ✅ Left room with ${_selectedRoom!.participantName}');
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

  // 🔥 FIX: เพิ่ม enterRoom และใช้ bulk mark-as-read
  Future<void> _onSelectChatRoom(
    SelectChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _selectedRoom = event.room;
      _currentPage = 1;
      _hasMoreMessages = true;

      // 🔥 FIX 1: เข้าห้องแชท - บอก backend ว่าเรากำลังอยู่ในห้องนี้
      // Backend จะรู้และจะ auto-mark messages as read + ส่ง read receipt
      try {
        await (chatRepository as ChatRepositoryImpl).enterRoom(
          event.room.participantId,
        );
        print('🚪 ✅ Entered room with ${event.room.participantName}');
      } catch (e) {
        print('🚪 ⚠️ Failed to enter room: $e');
      }

      // โหลดข้อความหน้าแรก
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

      // 🔥 FIX 2: ใช้ bulk mark-as-read แทน per-message
      // เพราะ per-message API (/messages/:id/mark_as_read) ส่ง 404
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

  // ✨ Handler สำหรับ infinite scroll
  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (_isLoadingMore || !_hasMoreMessages || _selectedRoom == null) {
      print(
        '⚠️ Skip loading more: isLoading=$_isLoadingMore, hasMore=$_hasMoreMessages',
      );
      return;
    }

    _isLoadingMore = true;
    final nextPage = event.page;

    print('📥 Loading more messages: page $nextPage');

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

        print(
          '✅ Loaded ${newMessages.length} more messages (page $nextPage/$totalPages)',
        );
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

  // ==================== Real-time Delete / Edit Handlers ====================

  void _onWebSocketMessageDeleted(
    WebSocketMessageDeleted event,
    Emitter<ChatState> emit,
  ) {
    print('WebSocket message_deleted: ${event.messageId}');

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
    print('WebSocket message_updated: ${event.messageId}');

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
    // 🔥 FIX: Leave room ก่อนปิด bloc
    if (_selectedRoom != null) {
      try {
        await (chatRepository as ChatRepositoryImpl).leaveRoom(
          _selectedRoom!.participantId,
        );
        print('🚪 ✅ Left room on bloc close');
      } catch (e) {
        print('🚪 ⚠️ Failed to leave room on close: $e');
      }
    }

    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _readReceiptSubscription?.cancel();
    await _messageDeletedSubscription?.cancel();
    await _messageUpdatedSubscription?.cancel();
    await chatRepository.disconnectWebSocket();

    return super.close();
  }
}
