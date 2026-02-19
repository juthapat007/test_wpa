// lib/features/other_profile/presentation/bloc/profile_detail_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/notification/domain/repositories/connection_repository.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/other_profile/domain/repositories/profile_detail_repository.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
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
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RejectFriendRequest>(_onRejectFriendRequest);
    on<UnfriendRequest>(_onUnfriend);
    on<LoadScheduleOthers>(_onLoadScheduleOthers);
  }

  // ─── Load Profile ────────────────────────────────────────────────────────
  Future<void> _onLoadProfileDetail(
    LoadProfileDetail event,
    Emitter<ProfileDetailState> emit,
  ) async {
    emit(ProfileDetailLoading());
    try {
      var profile =
          await profileDetailRepository.getProfileDetail(event.delegateId);

      // backend ยังไม่ส่ง connection_request_id มา
      // ถ้า status = requestedToMe ให้ดึง request id จาก my_received
      if (profile.connectionStatus == ConnectionStatus.requestedToMe &&
          profile.connectionRequestId == null) {
        profile = await _enrichWithRequestId(profile);
      }

      emit(ProfileDetailLoaded(profile));
      add(LoadScheduleOthers(event.delegateId));
    } catch (e) {
      emit(ProfileDetailError('Cannot load profile: $e'));
    }
  }

  /// ดึง request id จาก my_received แล้ว attach กลับเข้า profile
  Future<ProfileDetail> _enrichWithRequestId(ProfileDetail profile) async {
    try {
      final requests = await connectionRepository.getReceivedRequests();
      // requester.id (map เป็น senderId) == delegate ที่เรากำลังดู
      final match =
          requests.where((r) => r.senderId == profile.id).firstOrNull;
      if (match != null) {
        return ProfileDetail(
          id: profile.id,
          name: profile.name,
          title: profile.title,
          email: profile.email,
          companyName: profile.companyName,
          avatarUrl: profile.avatarUrl,
          countryCode: profile.countryCode,
          isConnected: profile.isConnected,
          connectionStatus: profile.connectionStatus,
          teamId: profile.teamId,
          connectionRequestId: match.id, // ✅ ได้ request id แล้ว
        );
      }
    } catch (e) {
      print('⚠️ Could not enrich requestId: $e');
    }
    return profile;
  }

  // ─── Send Friend Request (none → requestedByMe) ──────────────────────────
  Future<void> _onSendFriendRequest(
    SendFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.sendRequest(event.delegateId);

      final updatedProfile = _copyProfile(
        currentState.profile,
        isConnected: false,
        connectionStatus: ConnectionStatus.requestedByMe,
        connectionRequestId: null,
      );

      emit(ProfileDetailLoaded(updatedProfile,
          schedules: currentState.schedules));
      emit(FriendRequestSuccess('Friend request sent!'));
    } catch (e) {
      emit(ProfileDetailLoaded(currentState.profile,
          schedules: currentState.schedules));
      emit(FriendRequestFailed('Failed to send friend request'));
    }
  }

  // ─── Accept (requestedToMe → connected) ─────────────────────────────────
  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.acceptRequest(event.requestId);

      final updatedProfile = _copyProfile(
        currentState.profile,
        isConnected: true,
        connectionStatus: ConnectionStatus.connected,
        connectionRequestId: null,
      );

      emit(ProfileDetailLoaded(updatedProfile,
          schedules: currentState.schedules));
      emit(FriendRequestSuccess('You are now connected!'));
    } catch (e) {
      emit(ProfileDetailLoaded(currentState.profile,
          schedules: currentState.schedules));
      emit(FriendRequestFailed('Failed to accept request'));
    }
  }

  // ─── Reject (requestedToMe → none) ───────────────────────────────────────
  Future<void> _onRejectFriendRequest(
    RejectFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.rejectRequest(event.requestId);

      // ✅ status กลับ none → คนนั้น add มาใหม่ได้
      final updatedProfile = _copyProfile(
        currentState.profile,
        isConnected: false,
        connectionStatus: ConnectionStatus.none,
        connectionRequestId: null,
      );

      emit(ProfileDetailLoaded(updatedProfile,
          schedules: currentState.schedules));
      emit(FriendRequestSuccess('Request declined'));
    } catch (e) {
      emit(ProfileDetailLoaded(currentState.profile,
          schedules: currentState.schedules));
      emit(FriendRequestFailed('Failed to decline request'));
    }
  }

  // ─── Unfriend (connected → none) ─────────────────────────────────────────
  Future<void> _onUnfriend(
    UnfriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.unfriend(event.delegateId);

      // ✅ status กลับ none → add กันใหม่ได้
      final updatedProfile = _copyProfile(
        currentState.profile,
        isConnected: false,
        connectionStatus: ConnectionStatus.none,
        connectionRequestId: null,
      );

      emit(ProfileDetailLoaded(updatedProfile,
          schedules: currentState.schedules));
      emit(FriendRequestSuccess('Unfriended successfully'));
    } catch (e) {
      emit(ProfileDetailLoaded(currentState.profile,
          schedules: currentState.schedules));
      emit(FriendRequestFailed('Failed to unfriend'));
    }
  }

  // ─── Load Schedules ───────────────────────────────────────────────────────
  Future<void> _onLoadScheduleOthers(
    LoadScheduleOthers event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    try {
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

  // ─── Helper: copy profile with updated fields ────────────────────────────
  ProfileDetail _copyProfile(
    ProfileDetail p, {
    required bool isConnected,
    required ConnectionStatus connectionStatus,
    required int? connectionRequestId,
  }) {
    return ProfileDetail(
      id: p.id,
      name: p.name,
      title: p.title,
      email: p.email,
      companyName: p.companyName,
      avatarUrl: p.avatarUrl,
      countryCode: p.countryCode,
      isConnected: isConnected,
      connectionStatus: connectionStatus,
      teamId: p.teamId,
      connectionRequestId: connectionRequestId,
    );
  }
}