import 'dart:async';
import 'dart:convert'; // เพิ่ม import นี้
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // เพิ่ม import นี้
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

  /// Getter สำหรับ total unread count (ใช้ใน bottom nav badge)
  int get totalUnreadCount =>
      _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);

  /// ✅ Getter สำหรับ current user ID (ใช้ใน UI)
  String get currentUserId => _currentUserId ?? '0';

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    // ✅ Initialize current user ID
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
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
  }

  /// ✅ Initialize current user ID from secure storage
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

    // ✅ Debug log
    print('📩 WebSocket message received:');
    print('   - Message ID: ${message.id}');
    print('   - From: ${message.senderId}');
    print('   - To: ${message.receiverId}');
    print('   - Content: ${message.content}');
    print('   - Current user ID: $_currentUserId');

    // ตรวจสอบ duplicate: ถ้า message id ซ้ำกับที่มีอยู่แล้ว ให้ skip
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

      print('💬 Selected room: ${event.room.participantName}');
      print('💬 Loaded ${_messages.length} messages');

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

  // ✏️ แก้ไขใน lib/features/chat/presentation/bloc/chat_bloc.dart
  // หาส่วน _onSelectChatRoom และแทนที่ด้วยโค้ดนี้

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

  // Future<void> _onSelectChatRoom(
  //   SelectChatRoom event,
  //   Emitter<ChatState> emit,
  // ) async {
  //   emit(ChatLoading());
  //   try {
  //     _selectedRoom = event.room;

  //     print(
  //       '🔍 About to load history for room: ${event.room.participantName} (id: ${event.room.id})',
  //     );
  //     print(
  //       '   Last message from room object: ${event.room.lastMessage?.content}',
  //     );

  //     // โหลด messages จาก API
  //     _messages = await chatRepository.getChatHistory(event.room.id);

  //     print('🔍 Loaded ${_messages.length} messages');
  //     if (_messages.isNotEmpty) {
  //       print('   Last message from API: ${_messages.last.content}');
  //       print('   Last message time: ${_messages.last.createdAt}');
  //     }

  //     // 🔧 FIX 1: Merge ข้อความล่าสุดจาก room object (ถ้ามี)
  //     if (event.room.lastMessage != null) {
  //       final roomLastMessage = event.room.lastMessage!;

  //       // ตรวจสอบว่าข้อความนี้มีใน list แล้วหรือยัง (ดูจาก ID หรือ content + timestamp)
  //       final alreadyExists = _messages.any(
  //         (m) =>
  //             m.id == roomLastMessage.id ||
  //             (m.content == roomLastMessage.content &&
  //                 m.createdAt
  //                         .difference(roomLastMessage.createdAt)
  //                         .inSeconds
  //                         .abs() <
  //                     2),
  //       );

  //       if (!alreadyExists) {
  //         print('⚠️ Last message from room not in API response!');
  //         print(
  //           '   Adding: "${roomLastMessage.content}" (${roomLastMessage.createdAt})',
  //         );

  //         // เพิ่มข้อความเข้าไป
  //         _messages = [..._messages, roomLastMessage];

  //         // เรียงใหม่ตาม createdAt
  //         _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

  //         print('✅ After merge: ${_messages.length} messages');
  //         print('   New last message: ${_messages.last.content}');
  //       } else {
  //         print('✅ Last message already in list');
  //       }
  //     }

  //     // Mark as read
  //     if (event.room.unreadCount > 0) {
  //       add(MarkAsRead(event.room.id));
  //     }

  //     emit(
  //       ChatRoomSelected(
  //         room: event.room,
  //         messages: _messages,
  //         isWebSocketConnected: _isWebSocketConnected,
  //       ),
  //     );
  //   } catch (e) {
  //     emit(ChatError('Failed to load chat history: $e'));
  //     emit(
  //       ChatRoomsLoaded(
  //         rooms: _chatRooms,
  //         isWebSocketConnected: _isWebSocketConnected,
  //       ),
  //     );
  //   }
  // }

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

    // ✅ ใช้ current user ID จริง
    final senderId = _currentUserId ?? '0';

    print('📤 Sending message:');
    print('   - From (current user): $senderId');
    print('   - To: ${_selectedRoom!.participantId}');
    print('   - Content: ${event.content}');

    // สร้าง message object
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId, // ✅ ใช้ user ID จริง
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

      print('✅ Message sent successfully');
      emit(MessageSent(room: _selectedRoom!, messages: _messages));
    } catch (e) {
      print('❌ Failed to send message: $e');

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

      // ถ้าอยู่ในห้องแชท ให้ emit ChatRoomSelected เพื่อไม่ให้ UI หาย
      if (_selectedRoom != null) {
        emit(
          ChatRoomSelected(
            room: _selectedRoom!,
            messages: _messages,
            isWebSocketConnected: _isWebSocketConnected,
          ),
        );
      } else {
        // ถ้าอยู่หน้า list ให้ emit ChatRoomsLoaded เพื่ออัพเดท badge
        emit(
          ChatRoomsLoaded(
            rooms: _chatRooms,
            isWebSocketConnected: _isWebSocketConnected,
          ),
        );
      }
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
