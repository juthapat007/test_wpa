import 'package:flutter/foundation.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';

@immutable
sealed class ProfileDetailState {}

final class ProfileDetailInitial extends ProfileDetailState {}

final class ProfileDetailLoading extends ProfileDetailState {}

final class ProfileDetailLoaded extends ProfileDetailState {
  final ProfileDetail profile;
  final List<Schedule>? schedules;
  final List<String> availableDates;
  final String selectedDate; // วันที่ที่แสดงอยู่ตอนนี้
  final bool isScheduleLoading;

  ProfileDetailLoaded(
    this.profile, {
    this.schedules,
    this.availableDates = const [],
    this.selectedDate = '',
    this.isScheduleLoading = false,
  });
}

final class ProfileDetailError extends ProfileDetailState {
  final String message;
  ProfileDetailError(this.message);
}

final class FriendRequestSending extends ProfileDetailState {}

final class FriendRequestSuccess extends ProfileDetailState {
  final String message;
  FriendRequestSuccess(this.message);
}

final class FriendRequestFailed extends ProfileDetailState {
  final String message;
  FriendRequestFailed(this.message);
}
