// lib/features/other_profile/presentation/bloc/profile_detail_bloc.dart

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

  /// เก็บ delegateId ไว้ใช้ reload schedule เมื่อเปลี่ยน date
  int? _delegateId;

  ProfileDetailBloc({
    required this.profileDetailRepository,
    required this.connectionRepository,
    required this.scheduleOthersRepository,
  }) : super(ProfileDetailInitial()) {
    on<LoadProfileDetail>(_onLoadProfileDetail);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<CancelFriendRequest>(_onCancelFriendRequest);
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
    _delegateId = event.delegateId;
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
      // โหลด schedule ทันที (ไม่ส่ง date → backend คืน default)
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

  // ─── Load Schedules ───────────────────────────────────────────────────────
  Future<void> _onLoadScheduleOthers(
    LoadScheduleOthers event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;

    // ✅ แสดง isScheduleLoading แทนการ emit loading ทั้งหน้า
    if (currentState is ProfileDetailLoaded) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: event.date ?? currentState.selectedDate,
          isScheduleLoading: true,
        ),
      );
    }

    try {
      final response = await scheduleOthersRepository.getScheduleOthers(
        event.delegateId,
        date: event.date,
      );

      final baseProfile = currentState is ProfileDetailLoaded
          ? currentState.profile
          : await profileDetailRepository.getProfileDetail(event.delegateId);

      emit(
        ProfileDetailLoaded(
          baseProfile,
          schedules: response.schedules,
          availableDates: response.availableDates,
          selectedDate: response.selectedDate,
          isScheduleLoading: false,
        ),
      );
    } catch (e) {
      print('❌ Load schedule others error: $e');
      if (currentState is ProfileDetailLoaded) {
        emit(
          ProfileDetailLoaded(
            currentState.profile,
            schedules: currentState.schedules ?? [],
            availableDates: currentState.availableDates,
            selectedDate: currentState.selectedDate,
            isScheduleLoading: false,
          ),
        );
      }
    }
  }

  // ─── Send Request ─────────────────────────────────────────────────────────
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
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestSuccess('Friend request sent!'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestFailed('Failed to send friend request'));
    }
  }

  // ─── Cancel Request ───────────────────────────────────────────────────────
  Future<void> _onCancelFriendRequest(
    CancelFriendRequest event,
    Emitter<ProfileDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileDetailLoaded) return;

    emit(FriendRequestSending());
    try {
      await connectionRepository.cancelRequest(event.targetId);
      emit(
        ProfileDetailLoaded(
          _copyProfile(
            currentState.profile,
            isConnected: false,
            connectionStatus: ConnectionStatus.none,
            connectionRequestId: null,
          ),
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestSuccess('Request cancelled'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestFailed('Failed to cancel request'));
    }
  }

  // ─── Accept ───────────────────────────────────────────────────────────────
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
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestSuccess('You are now connected!'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestFailed('Failed to accept request'));
    }
  }

  // ─── Reject ───────────────────────────────────────────────────────────────
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
            connectionStatus: ConnectionStatus.none,
            connectionRequestId: null,
          ),
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestSuccess('Request declined'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestFailed('Failed to decline request'));
    }
  }

  // ─── Unfriend ─────────────────────────────────────────────────────────────
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
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestSuccess('Unfriended successfully'));
    } catch (e) {
      emit(
        ProfileDetailLoaded(
          currentState.profile,
          schedules: currentState.schedules,
          availableDates: currentState.availableDates,
          selectedDate: currentState.selectedDate,
        ),
      );
      emit(FriendRequestFailed('Failed to unfriend'));
    }
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
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
