// lib/features/other_profile/presentation/bloc/profile_detail_event.dart

import 'package:flutter/foundation.dart';

@immutable
sealed class ProfileDetailEvent {}

class LoadProfileDetail extends ProfileDetailEvent {
  final int delegateId;
  LoadProfileDetail(this.delegateId);
}

/// ส่งคำขอเพื่อน → POST /api/v1/requests
class SendFriendRequest extends ProfileDetailEvent {
  final int delegateId;
  SendFriendRequest(this.delegateId);
}

/// ยกเลิกคำขอที่เราส่งออกไป → DELETE /api/v1/requests/:target_id/cancel
class CancelFriendRequest extends ProfileDetailEvent {
  final int targetId;
  CancelFriendRequest(this.targetId);
}

/// ยอมรับคำขอ → PATCH /api/v1/requests/:id/accept
class AcceptFriendRequest extends ProfileDetailEvent {
  final int requestId;
  AcceptFriendRequest(this.requestId);
}

/// ปฏิเสธคำขอ → PATCH /api/v1/requests/:id/reject
class RejectFriendRequest extends ProfileDetailEvent {
  final int requestId;
  RejectFriendRequest(this.requestId);
}

/// ยกเลิกการเป็นเพื่อน → DELETE /api/v1/connections/:delegateId
class UnfriendRequest extends ProfileDetailEvent {
  final int delegateId;
  UnfriendRequest(this.delegateId);
}

/// ✅ date เป็น optional — ถ้าไม่ส่ง backend คืน default (วันแรก)
///    ส่ง date เมื่อ user กดเปลี่ยน tab ใน DateTabBar
class LoadScheduleOthers extends ProfileDetailEvent {
  final int delegateId;
  final String? date; // "2025-10-13"

  LoadScheduleOthers(this.delegateId, {this.date});
}