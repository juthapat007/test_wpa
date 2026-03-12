import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/data/services/chat_api.dart';
import 'package:test_wpa/features/chat/data/services/chat_websocket_service.dart'
    show
        ChatWebSocketService,
        ReadReceiptEvent,
        MessageDeletedEvent,
        MessageUpdatedEvent;

import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart';
import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart'
    show TypingEvent;

class ChatRepositoryImpl implements ChatRepository {
  final ChatApi api;
  final ChatWebSocketService webSocketService;
  final FlutterSecureStorage storage;

  ChatRepositoryImpl({
    required this.api,
    required this.webSocketService,
    required this.storage,
  });

  @override
  Future<void> connectWebSocket() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No auth token found');
    await webSocketService.connect(token);
  }

  @override
  Future<void> disconnectWebSocket() async {
    await webSocketService.disconnect();
  }

  @override
  Stream<String> get roomDeletedStream => webSocketService.roomDeletedStream;
  @override
  Stream<ChatMessage> get messageStream => webSocketService.messageStream;

  @override
  Stream<bool> get connectionStream => webSocketService.connectionStream;

  @override
  Stream<ReadReceiptEvent> get readReceiptStream =>
      webSocketService.readReceiptStream;

  @override
  Stream<MessageDeletedEvent> get messageDeletedStream =>
      webSocketService.messageDeletedStream;

  @override
  Stream<MessageUpdatedEvent> get messageUpdatedStream =>
      webSocketService.messageUpdatedStream;

  @override
  Stream<TypingEvent> get typingStream => webSocketService.typingStream;

  @override
  Future<void> sendMessage(ChatMessage message, {String? imageBase64}) async {
    try {
      await api.sendMessage(
        chatRoomId: message.chatRoomId,
        content: message.content,
        recipientId: message.receiverId,
        imageBase64: imageBase64,
      );
    } catch (e) {
      debugPrint('REST send failed, falling back to WebSocket: $e');
      await webSocketService.sendMessage(message);
    }
  }

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await api.getChatRooms();
      final List<dynamic> data = response.data;

      final rooms = data.map((json) {
        final delegate = json['delegate'];
        final lastMessageText = json['last_message'] as String?;
        final lastMessageType = json['last_message_type'] as String?;
        final isLastImage = lastMessageType == 'image';
        final lastMessageAt = json['last_message_at'] as String?;
        return ChatRoom(
          id: json['id'].toString(),
          participantId: delegate['id'].toString(),
          participantName: delegate['name'] ?? 'Unknown',
          participantAvatar: _resolveAvatarUrl(delegate['avatar_url']),
          lastMessage: lastMessageText != null && lastMessageAt != null
              ? ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  senderId: delegate['id'].toString(),
                  senderName: delegate['name'] ?? '',
                  receiverId: '',
                  chatRoomId: json['id'] as int? ?? 0,
                  content: lastMessageText,
                  createdAt: DateTime.parse(lastMessageAt).toLocal(),
                  editedAt: json['edited_at'] != null
                      ? DateTime.parse(json['edited_at']).toLocal()
                      : null,
                )
              : null,
          unreadCount: json['unread_count'] ?? 0,
          lastActiveAt: lastMessageAt != null
              ? DateTime.parse(lastMessageAt).toLocal()
              : null,
          isGroup: json['is_group'] ?? false,
          groupName: json['group_name'],
          participantIds: json['participant_ids'] != null
              ? (json['participant_ids'] as List)
                    .map<String>((e) => e.toString())
                    .toList()
              : [delegate['id'].toString()],
        );
      }).toList();

      rooms.sort((a, b) {
        if (a.lastActiveAt == null && b.lastActiveAt == null) return 0;
        if (a.lastActiveAt == null) return 1;
        if (b.lastActiveAt == null) return -1;
        return b.lastActiveAt!.compareTo(a.lastActiveAt!);
      });
      for (final r in rooms) {
        debugPrint(
          'Room: id=${r.id} participantId=${r.participantId} name=${r.participantName}',
        );
      }
      return rooms;
    } catch (e) {
      throw Exception('Failed to load chat rooms: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getChatHistory(
    String partnerId, {
    int? page,
    int? limit,
  }) async {
    try {
      final response = await api.getChatHistory(
        partnerId: partnerId,
        page: page,
        perPage: limit,
      );

      final List<dynamic> data = response.data['data'] ?? response.data;
      final meta = response.data['meta'];
      final messages = data
          .map((json) {
            try {
              final isImage = json['message_type'] == 'image';
              final content = isImage
                  ? (json['image_url'] ?? '')
                  : (json['content'] ?? '');

              return ChatMessage(
                id: json['id'].toString(),
                senderId: json['sender']['id'].toString(),
                senderName: json['sender']['name'] ?? '',
                senderAvatar: json['sender']['avatar_url'],
                receiverId: json['recipient']['id'].toString(),
                chatRoomId: json['chat_room_id'] as int? ?? 0,
                content: content,
                type: isImage ? MessageType.image : MessageType.text,
                createdAt: json['created_at'] != null
                    ? DateTime.parse(json['created_at']).toLocal()
                    : DateTime.now(),
                editedAt: json['edited_at'] != null
                    ? DateTime.parse(json['edited_at']).toLocal()
                    : null,
                isDeleted: json['is_deleted'] ?? false,
                isRead: json['read_at'] != null,
              );
            } catch (e) {
              debugPrint('Skip message parse error: $e | json: $json');
              return null;
            }
          })
          .whereType<ChatMessage>()
          .toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return {
        'messages': messages,
        'currentPage': meta?['page'] ?? page ?? 1,
        'totalPages': meta?['total_pages'] ?? 1,
        'totalCount': meta?['total_count'] ?? messages.length,
      };
    } catch (e) {
      throw Exception('Failed to load chat history: $e');
    }
  }

  @override
  Future<ChatRoom> createChatRoom(
    String participantId, {
    String title = '',
  }) async {
    try {
      final response = await api.createChatRoom(title: title);
      final data = response.data;
      final id = (data['id'] as int?) ?? 0;
      return ChatRoom(
        id: id.toString(),
        participantId: participantId,
        participantName: data['title'] ?? '',
        unreadCount: 0,
        isGroup: false,
        participantIds: [participantId],
      );
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  @override
  Future<void> markAsRead(String partnerId) async {
    try {
      await api.markAllAsRead(partnerId);
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await api.markMessageAsRead(messageId);
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> updateMessage(String messageId, String content) async {
    try {
      await api.updateMessage(messageId: messageId, content: content);
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await api.deleteMessage(messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// ลบประวัติสนทนาทั้งหมดกับ delegate — คืนค่า deleted_count
  @override
  Future<int> deleteConversation(String partnerId) async {
    try {
      final response = await api.deleteConversation(partnerId);
      return (response.data['deleted_count'] as int?) ?? 0;
    } on Exception catch (e) {
      // โยน error message จาก server ให้ caller จัดการ
      throw Exception('Failed to delete conversation: $e');
    }
  }

  Future<void> sendTypingIndicator(String recipientId, bool isTyping) async {
    await webSocketService.sendTypingIndicator(recipientId, isTyping);
  }

  Future<void> enterRoom(String roomId) async {
    await webSocketService.enterRoom(roomId);
  }

  Future<void> leaveRoom(String userId) async {
    await webSocketService.leaveRoom(userId);
  }

  static String? _resolveAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return 'https://wpadocker-production.up.railway.app$url';
  }
}
