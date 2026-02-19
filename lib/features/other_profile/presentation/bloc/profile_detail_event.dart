// lib/features/other_profile/presentation/bloc/profile_detail_event.dart

import 'package:flutter/foundation.dart';

@immutable
sealed class ProfileDetailEvent {}

/// โหลด profile
class LoadProfileDetail extends ProfileDetailEvent {
  final int delegateId;
  LoadProfileDetail(this.delegateId);
}

/// ส่ง friend request ใหม่ → POST /requests  (status = none)
class SendFriendRequest extends ProfileDetailEvent {
  final int delegateId;
  SendFriendRequest(this.delegateId);
}

/// Accept → PATCH /requests/:id/accept  (status = requestedToMe)
class AcceptFriendRequest extends ProfileDetailEvent {
  final int requestId;
  AcceptFriendRequest(this.requestId);
}

/// Reject → PATCH /requests/:id/reject  (status = requestedToMe → none)
class RejectFriendRequest extends ProfileDetailEvent {
  final int requestId;
  RejectFriendRequest(this.requestId);
}

/// Unfriend → DELETE /connections/:delegateId  (status = connected → none)
class UnfriendRequest extends ProfileDetailEvent {
  final int delegateId;
  UnfriendRequest(this.delegateId);
}

/// โหลด schedule ของ delegate คนอื่น
class LoadScheduleOthers extends ProfileDetailEvent {
  final int delegateId;
  LoadScheduleOthers(this.delegateId);
}