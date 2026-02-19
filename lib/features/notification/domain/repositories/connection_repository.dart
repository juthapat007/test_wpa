// lib/features/notification/domain/repositories/connection_repository.dart

import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';

/// Friend entity สำหรับ friend list tab
class Friend {
  final int id;
  final String name;
  final String? title;
  final String? avatarUrl;
  final String? companyName;

  Friend({
    required this.id,
    required this.name,
    this.title,
    this.avatarUrl,
    this.companyName,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    // รองรับทั้ง flat และ nested delegate format
    final delegate = json['delegate'] as Map<String, dynamic>?;
    if (delegate != null) {
      return Friend(
        id: delegate['id'],
        name: delegate['name'] ?? '',
        title: delegate['title'],
        avatarUrl: delegate['avatar_url'],
        companyName: delegate['company_name'],
      );
    }
    return Friend(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'],
      avatarUrl: json['avatar_url'],
      companyName: json['company_name'],
    );
  }
}

abstract class ConnectionRepository {
  /// GET /api/v1/requests/my_received — คำขอที่คนอื่นส่งมาหาเรา
  Future<List<ConnectionRequest>> getReceivedRequests();

  /// GET /api/v1/connections — รายชื่อเพื่อนทั้งหมด (ถ้า backend ยังไม่มี ให้แจ้งให้เพิ่ม)
  Future<List<Friend>> getFriends();

  /// POST /api/v1/requests — ส่งคำขอเป็นเพื่อน
  Future<void> sendRequest(int delegateId);

  /// PATCH /api/v1/requests/:id/accept — ยอมรับคำขอ
  Future<void> acceptRequest(int requestId);

  /// PATCH /api/v1/requests/:id/reject — ปฏิเสธคำขอ (หลังจากนี้ status = none ทั้งสองฝ่าย)
  Future<void> rejectRequest(int requestId);

  /// DELETE /api/v1/requests/:target_id/cancel — ยกเลิกคำขอที่เราส่งออกไป
  /// ⚠️ ใช้ target_id (delegate id) ไม่ใช่ request id
  Future<void> cancelRequest(int targetId);

  /// DELETE /api/v1/connections/:delegate_id — ยกเลิกการเป็นเพื่อน
  /// ⚠️ ถ้า backend ยังไม่มี endpoint นี้ ต้องแจ้งทีม backend ให้เพิ่ม
  Future<void> unfriend(int delegateId);
}
