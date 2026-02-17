// lib/features/other_profile/presentation/bloc/profile_detail_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/notification/domain/repositories/connection_repository.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/other_profile/domain/repositories/profile_detail_repository.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart'; // ✅ Schedule
import 'package:test_wpa/features/schedules/domain/repositories/schedule_others_repository.dart';

class ProfileDetailBloc extends Bloc<ProfileDetailEvent, ProfileDetailState> {
  final ProfileDetailRepository profileDetailRepository;
  final ConnectionRepository connectionRepository;
  final ScheduleOthersRepository scheduleOthersRepository;

  ProfileDetailBloc({
    required this.profileDetailRepository,
    required this.connectionRepository,
    required this.scheduleOthersRepository,
  }) : super(ProfileDetailInitial()) {
    on<LoadProfileDetail>(_onLoadProfileDetail);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<LoadScheduleOthers>(_onLoadScheduleOthers);
  }

  Future<void> _onLoadProfileDetail(
    LoadProfileDetail event,
    Emitter<ProfileDetailState> emit,
  ) async {
    emit(ProfileDetailLoading());
    try {
      final profile = await profileDetailRepository.getProfileDetail(event.delegateId);
      emit(ProfileDetailLoaded(profile));
      // โหลด schedule อัตโนมัติ
      add(LoadScheduleOthers(event.delegateId));
    } catch (e) {
      emit(ProfileDetailError('Cannot load profile: $e'));
    }
  }

  Future<void> _onSendFriendRequest(
    SendFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.sendRequest(event.delegateId);

      final updatedProfile = ProfileDetail(
        id: currentState.profile.id,
        name: currentState.profile.name,
        title: currentState.profile.title,
        email: currentState.profile.email,
        companyName: currentState.profile.companyName,
        avatarUrl: currentState.profile.avatarUrl,
        countryCode: currentState.profile.countryCode,
        isConnected: true,
        connectionStatus: ConnectionStatus.requestedByMe,
      );

      emit(ProfileDetailLoaded(updatedProfile, schedules: currentState.schedules));
      emit(FriendRequestSuccess('Friend request sent!'));
    } catch (e) {
      emit(ProfileDetailLoaded(currentState.profile, schedules: currentState.schedules));
      emit(FriendRequestFailed('Failed to send friend request'));
    }
  }

  Future<void> _onLoadScheduleOthers(
    LoadScheduleOthers event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    try {
      // ✅ repository return List<Schedule> โดยตรง
      final List<Schedule> schedules =
          await scheduleOthersRepository.getScheduleOthers(event.delegateId);

      if (currentState is ProfileDetailLoaded) {
        emit(ProfileDetailLoaded(currentState.profile, schedules: schedules));
      }
    } catch (e) {
      print('❌ Load schedule others error: $e');
      if (currentState is ProfileDetailLoaded) {
        emit(ProfileDetailLoaded(currentState.profile, schedules: []));
      }
    }
  }
}