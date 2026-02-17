// lib/features/Other_profile/presentation/bloc/profile_detail_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/notification/domain/repositories/connection_repository.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/other_profile/domain/repositories/profile_detail_repository.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
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
      final profile = await profileDetailRepository.getProfileDetail(
        event.delegateId,
      );

      emit(ProfileDetailLoaded(profile));

      // โหลด schedule ของคนนั้นด้วยอัตโนมัติ
      add(LoadScheduleOthers(event.delegateId));
    } catch (e) {
      print('❌ ProfileDetailBloc error: $e');
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
      // ✅ อัปเดต isConnected เป็น true (หรือ pending)
      final updatedProfile = ProfileDetail(
        id: currentState.profile.id,
        name: currentState.profile.name,
        title: currentState.profile.title,
        email: currentState.profile.email,
        companyName: currentState.profile.companyName,
        avatarUrl: currentState.profile.avatarUrl,
        countryCode: currentState.profile.countryCode,
        isConnected: true, // ถือว่าส่ง request แล้ว
      );

      emit(
        ProfileDetailLoaded(updatedProfile, schedules: currentState.schedules),
      );
      emit(FriendRequestSuccess('Friend request sent successfully!'));
    } catch (e) {
      print('❌ Send friend request error: $e');
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
        ),
      ); // คืนสถานะเดิม
      emit(FriendRequestFailed('Failed to send friend request'));
    }
  }

  Future<void> _onLoadScheduleOthers(
    LoadScheduleOthers event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;

    try {
      final schedules = await scheduleOthersRepository.getScheduleOthers(
        event.delegateId,
      );

      if (currentState is ProfileDetailLoaded) {
        emit(ProfileDetailLoaded(currentState.profile, schedules: schedules));
      }
    } catch (e) {
      print('❌ Load schedule error: $e');
      // ไม่ให้ error ของ schedule ทำให้หน้าพังทั้งหมด
      if (currentState is ProfileDetailLoaded) {
        emit(ProfileDetailLoaded(currentState.profile, schedules: []));
      }
    }
  }
}
