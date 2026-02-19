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

/// ✅ ยกเลิกคำขอที่เราส่งออกไป → DELETE /api/v1/requests/:target_id/cancel
/// status: requestedByMe → none
class CancelFriendRequest extends ProfileDetailEvent {
  final int targetId; // คือ delegate id ที่เราส่ง request ไป
  CancelFriendRequest(this.targetId);
}

/// ยอมรับคำขอ → PATCH /api/v1/requests/:id/accept
/// status: requestedToMe → connected
class AcceptFriendRequest extends ProfileDetailEvent {
  final int requestId;
  AcceptFriendRequest(this.requestId);
}

/// ปฏิเสธคำขอ → PATCH /api/v1/requests/:id/reject
/// status: requestedToMe → none (ทั้งสองฝ่าย add กันได้ใหม่)
class RejectFriendRequest extends ProfileDetailEvent {
  final int requestId;
  RejectFriendRequest(this.requestId);
}

/// ยกเลิกการเป็นเพื่อน → DELETE /api/v1/connections/:delegateId
/// status: connected → none
class UnfriendRequest extends ProfileDetailEvent {
  final int delegateId;
  UnfriendRequest(this.delegateId);
}

class LoadScheduleOthers extends ProfileDetailEvent {
  final int delegateId;
  LoadScheduleOthers(this.delegateId);
}
