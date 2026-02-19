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
    on<CancelFriendRequest>(_onCancelFriendRequest); // ✅ เพิ่มใหม่
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RejectFriendRequest>(_onRejectFriendRequest);
    on<UnfriendRequest>(_onUnfriend);
    on<LoadScheduleOthers>(_onLoadScheduleOthers);
  }

  // ─── Load Profile ─────────────────────────────────────────────────────────
  Future<void> _onLoadProfileDetail(
    LoadProfileDetail event,
    Emitter<ProfileDetailState> emit,
  ) async {
    emit(ProfileDetailLoading());
    try {
      var profile = await profileDetailRepository.getProfileDetail(
        event.delegateId,
      );

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

  Future<ProfileDetail> _enrichWithRequestId(ProfileDetail profile) async {
    try {
      final requests = await connectionRepository.getReceivedRequests();
      final match = requests.where((r) => r.senderId == profile.id).firstOrNull;
      if (match != null) {
        return _copyProfile(
          profile,
          isConnected: false,
          connectionStatus: profile.connectionStatus,
          connectionRequestId: match.id,
        );
      }
    } catch (e) {
      print('⚠️ Could not enrich requestId: $e');
    }
    return profile;
  }

  // ─── Send Request (none → requestedByMe) ─────────────────────────────────
  Future<void> _onSendFriendRequest(
    SendFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.sendRequest(event.delegateId);

      emit(
        ProfileDetailLoaded(
          _copyProfile(
            currentState.profile,
            isConnected: false,
            connectionStatus: ConnectionStatus.requestedByMe,
            connectionRequestId: null,
          ),
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestSuccess('Friend request sent!'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestFailed('Failed to send friend request'));
    }
  }

  // ─── Cancel Request (requestedByMe → none) ───────────────────────────────
  // DELETE /api/v1/requests/:target_id/cancel
  Future<void> _onCancelFriendRequest(
    CancelFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.cancelRequest(event.targetId);

      // ✅ กลับ none → Add Friend ปรากฏอีกครั้ง
      emit(
        ProfileDetailLoaded(
          _copyProfile(
            currentState.profile,
            isConnected: false,
            connectionStatus: ConnectionStatus.none,
            connectionRequestId: null,
          ),
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestSuccess('Request cancelled'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestFailed('Failed to cancel request'));
    }
  }

  // ─── Accept (requestedToMe → connected) ──────────────────────────────────
  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.acceptRequest(event.requestId);

      emit(
        ProfileDetailLoaded(
          _copyProfile(
            currentState.profile,
            isConnected: true,
            connectionStatus: ConnectionStatus.connected,
            connectionRequestId: null,
          ),
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestSuccess('You are now connected!'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestFailed('Failed to accept request'));
    }
  }

  // ─── Reject (requestedToMe → none) ───────────────────────────────────────
  // ✅ หลัง reject ทั้งสองฝ่าย status = none → add กันได้ใหม่
  Future<void> _onRejectFriendRequest(
    RejectFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.rejectRequest(event.requestId);

      emit(
        ProfileDetailLoaded(
          _copyProfile(
            currentState.profile,
            isConnected: false,
            connectionStatus:
                ConnectionStatus.none, // ✅ none เลย ไม่ใช่ rejected
            connectionRequestId: null,
          ),
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestSuccess('Request declined'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
        ),
      );
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

      emit(
        ProfileDetailLoaded(
          _copyProfile(
            currentState.profile,
            isConnected: false,
            connectionStatus: ConnectionStatus.none,
            connectionRequestId: null,
          ),
          schedules: currentState.schedules,
        ),
      );
      emit(FriendRequestSuccess('Unfriended successfully'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
        ),
      );
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
      final List<Schedule> schedules = await scheduleOthersRepository
          .getScheduleOthers(event.delegateId);
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
