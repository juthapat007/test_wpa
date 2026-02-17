// lib/features/Other_profile/presentation/bloc/profile_detail_state.dart

import 'package:flutter/foundation.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';

@immutable
sealed class ProfileDetailState {}

final class ProfileDetailInitial extends ProfileDetailState {}

final class ProfileDetailLoading extends ProfileDetailState {}

final class ProfileDetailLoaded extends ProfileDetailState {
  final ProfileDetail profile;
  final List<ScheduleItem>? schedules;

  ProfileDetailLoaded(this.profile, {this.schedules});
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

// ✅ สถานะการโหลด Schedule
final class ScheduleOthersLoading extends ProfileDetailState {}

final class ScheduleOthersLoaded extends ProfileDetailState {
  final List<ScheduleItem> schedules;

  ScheduleOthersLoaded(this.schedules);
}

final class ScheduleOthersError extends ProfileDetailState {
  final String message;

  ScheduleOthersError(this.message);
}
