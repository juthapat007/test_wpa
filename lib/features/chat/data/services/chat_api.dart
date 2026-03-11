import 'package:dio/dio.dart';
import 'package:test_wpa/core/constants/print_logger.dart';

class ChatApi {
  final Dio dio;

  ChatApi(this.dio);

  /// ดึงรายการห้องแชท (Inbox)
  Future<Response> getChatRooms() async {
    try {
      final response = await dio.get('/messages/rooms');
      log.d('Chat rooms loaded: ${response.data}');
      return response;
    } catch (e) {
      log.e('Error loading chat rooms', error: e);
      rethrow;
    }
  }

  /// ดึงประวัติข้อความกับคนใดคนหนึ่ง
  Future<Response> getChatHistory({
    required String partnerId,
    int? page,
    int? perPage,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      };

      final response = await dio.get(
        '/messages/conversation/$partnerId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      log.d('Chat history loaded for partner $partnerId');
      return response;
    } catch (e) {
      log.e('Error loading chat history for partner $partnerId', error: e);
      rethrow;
    }
  }

  /// ส่งข้อความ (text หรือ image)
  /// [imageBase64] — data URI เช่น "data:image/png;base64,..." (nullable)
  Future<Response> sendMessage({
    required int chatRoomId,
    required String content,
    required String recipientId,
    String? imageBase64,
  }) async {
    final recipientIdInt = int.tryParse(recipientId);
    if (recipientIdInt == null) {
      throw Exception('Invalid recipientId: $recipientId');
    }

    try {
      final messageBody = <String, dynamic>{
        'chat_room_id': chatRoomId,
        'recipient_id': recipientIdInt,
      };

      if (imageBase64 != null && imageBase64.isNotEmpty) {
        // ส่งรูป — content อาจว่างได้
        messageBody['image'] = imageBase64;
      } else {
        messageBody['content'] = content;
      }

      final response = await dio.post(
        '/messages',
        data: {'message': messageBody},
      );
      log.i('Message sent: ${response.data}');
      return response;
    } catch (e) {
      log.e('Error sending message', error: e);
      rethrow;
    }
  }

  /// ทำเครื่องหมายว่าอ่านข้อความจากคนนั้นแล้วทั้งหมด
  Future<Response> markAllAsRead(String senderId) async {
    final senderIdInt = int.tryParse(senderId);
    if (senderIdInt == null) throw Exception('Invalid senderId: $senderId');

    try {
      final response = await dio.patch(
        '/messages/read_all',
        data: {'sender_id': senderIdInt},
      );
      log.d('All messages from $senderId marked as read');
      return response;
    } catch (e) {
      log.e('Error marking all as read', error: e);
      rethrow;
    }
  }

  /// Mark a single message as read
  Future<Response> markMessageAsRead(String messageId) async {
    try {
      final response = await dio.patch('/messages/$messageId/mark_as_read');
      log.d('Message $messageId marked as read');
      return response;
    } catch (e) {
      log.e('Error marking message $messageId as read', error: e);
      rethrow;
    }
  }

  /// แก้ไขข้อความ
  Future<Response> updateMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await dio.put(
        '/messages/$messageId',
        data: {
          'message': {'content': content},
        },
      );
      log.i('Message $messageId updated');
      return response;
    } catch (e) {
      log.e('Error updating message $messageId', error: e);
      rethrow;
    }
  }

  /// ลบข้อความ (ฝั่งเดียว)
  Future<Response> deleteMessage(String messageId) async {
    try {
      final response = await dio.delete('/messages/$messageId');
      log.i('Message $messageId deleted');
      return response;
    } catch (e) {
      log.e('Error deleting message $messageId', error: e);
      rethrow;
    }
  }

  /// ลบประวัติสนทนาทั้งหมดกับคนนั้น (soft delete — server ยังเก็บไว้)
  /// DELETE /api/v1/messages/conversation/:delegate_id
  Future<Response> deleteConversation(String partnerId) async {
    try {
      final response = await dio.delete('/messages/conversation/$partnerId');
      log.i(
        'Conversation with $partnerId deleted (deleted_count: ${response.data?['deleted_count']})',
      );
      return response;
    } catch (e) {
      log.e('Error deleting conversation with $partnerId', error: e);
      rethrow;
    }
  }

  /// สร้างห้องแชทใหม่
  Future<Response> createChatRoom({required String title}) async {
    try {
      final body = {
        'chat_room': {'title': title, 'room_kind': 'group'},
      };
      log.d('createChatRoom body: $body');
      final response = await dio.post('/chat_rooms', data: body);
      log.i('Chat room created: ${response.data}');
      return response;
    } catch (e) {
      log.e('Error creating chat room', error: e);
      rethrow;
    }
  }
}
