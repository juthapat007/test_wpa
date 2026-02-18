import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ChatApi {
  final Dio dio;

  ChatApi(this.dio);

  /// ดึงรายการห้องแชท (Inbox)
  Future<Response> getChatRooms() async {
    try {
      final response = await dio.get('/messages/rooms');
      debugPrint('📋 Chat rooms loaded: ${response.data}');
      return response;
    } catch (e) {
      debugPrint('❌ Error loading chat rooms: $e');
      rethrow;
    }
  }

  /// ดึงประวัติข้อความกับคนใดคนหนึ่ง
  /// partnerId = ID ของคู่สนทนา
  /// page = หน้าที่ต้องการ (default = 1 คือหน้าล่าสุด)
  /// perPage = จำนวนข้อความต่อหน้า
  Future<Response> getChatHistory({
    required String partnerId,
    int? page,
    int? perPage,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (perPage != null) queryParams['per_page'] = perPage;

      final response = await dio.get(
        '/messages/conversation/$partnerId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      debugPrint('Chat history loaded for partner $partnerId');
      return response;
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      rethrow;
    }
  }

  /// ส่งข้อความ (ผ่าน REST API)
  Future<Response> sendMessage({
    required String recipientId,
    required String content,
    String? tempId,
  }) async {
    try {
      final response = await dio.post(
        '/messages',
        data: {
          'recipient_id': int.parse(recipientId),
          'content': content,
          if (tempId != null) 'tempId': tempId,
        },
      );
      debugPrint('✅ Message sent via REST');
      return response;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// ทำเครื่องหมายว่าอ่านข้อความจากคนนั้นแล้วทั้งหมด
  Future<Response> markAllAsRead(String senderId) async {
    try {
      final response = await dio.patch(
        '/messages/read_all',
        data: {'sender_id': int.parse(senderId)},
      );
      debugPrint('Messages marked as read');
      return response;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      rethrow;
    }
  }

  /// Mark a single message as read
  /// Endpoint: PATCH /api/v1/messages/{id}/mark_as_read
  Future<Response> markMessageAsRead(String messageId) async {
    try {
      final response = await dio.patch('/messages/$messageId/mark_as_read');
      debugPrint('Message $messageId marked as read');
      return response;
    } catch (e) {
      debugPrint('Error marking message $messageId as read: $e');
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
        data: {'content': content},
      );
      debugPrint('✅ Message updated');
      return response;
    } catch (e) {
      debugPrint('❌ Error updating message: $e');
      rethrow;
    }
  }

  /// ลบข้อความ (ฝั่งเดียว)
  Future<Response> deleteMessage(String messageId) async {
    try {
      final response = await dio.delete('/messages/$messageId');
      debugPrint('✅ Message deleted');
      return response;
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      rethrow;
    }
  }

  /// ลบการสนทนาทั้งหมดกับคนนั้น
  Future<Response> deleteConversation(String partnerId) async {
    try {
      final response = await dio.delete('/messages/conversation/$partnerId');
      debugPrint('✅ Conversation deleted');
      return response;
    } catch (e) {
      debugPrint('❌ Error deleting conversation: $e');
      rethrow;
    }
  }

  // /// สร้างห้องแชทใหม่
  Future<Response> createChatRoom({required String title}) async {
    try {
      final body = {
        'chat_room': {'title': title, 'room_kind': 'group'},
      };
      debugPrint('📤 createChatRoom body: $body');
      final response = await dio.post('/chat_rooms', data: body);
      debugPrint('✅ Chat room created: ${response.data}');
      return response;
    } catch (e) {
      debugPrint('❌ Error creating chat room: $e');
      rethrow;
    }
  }

  // Future<Response> createChatRoom({
  //   required String title,
  //   String? participantId,
  // }) async {
  //   try {
  //     final response = await dio.post(
  //       '/chat_rooms',
  //       data: {
  //         'chat_room': {
  //           'title': title,
  //           'room_kind': 'group',
  //           if (participantId != null)
  //             'participant_id': int.parse(participantId),
  //         },
  //       },
  //     );
  //     debugPrint('✅ Chat room created: ${response.data}');
  //     return response;
  //   } catch (e) {
  //     debugPrint('❌ Error creating chat room: $e');
  //     rethrow;
  //   }
  // }
}
