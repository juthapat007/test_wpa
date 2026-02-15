// lib/features/someone_profile/presentation/bloc/profile_detail_state.dart

import 'package:flutter/foundation.dart';
import 'package:test_wpa/features/someone_profile/domain/entities/profile_detail.dart';

@immutable
sealed class ProfileDetailState {}

final class ProfileDetailInitial extends ProfileDetailState {}

final class ProfileDetailLoading extends ProfileDetailState {}

final class ProfileDetailLoaded extends ProfileDetailState {
  final ProfileDetail profile;

  ProfileDetailLoaded(this.profile);
}

final class ProfileDetailError extends ProfileDetailState {
  final String message;

  ProfileDetailError(this.message);
}

// ✅ สถานะการส่ง friend request
final class FriendRequestSending extends ProfileDetailState {}

final class FriendRequestSuccess extends ProfileDetailState {
  final String message;

  FriendRequestSuccess(this.message);
}

final class FriendRequestFailed extends ProfileDetailState {
  final String message;

  FriendRequestFailed(this.message);
}
