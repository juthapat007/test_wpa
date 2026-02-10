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
  Future<Response> getChatHistory({required String partnerId}) async {
    try {
      final response = await dio.get('/messages/conversation/$partnerId');
      debugPrint('💬 Chat history loaded for partner $partnerId');
      return response;
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
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
      debugPrint('✅ Messages marked as read');
      return response;
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
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
}