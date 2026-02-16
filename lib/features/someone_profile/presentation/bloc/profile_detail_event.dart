// lib/features/someone_profile/presentation/bloc/profile_detail_event.dart

import 'package:flutter/foundation.dart';

@immutable
sealed class ProfileDetailEvent {}

class LoadProfileDetail extends ProfileDetailEvent {
  final int delegateId;

  LoadProfileDetail(this.delegateId);
}

class SendFriendRequest extends ProfileDetailEvent {
  final int delegateId;

  SendFriendRequest(this.delegateId);
}
