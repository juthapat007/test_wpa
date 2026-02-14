import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';
import 'package:test_wpa/features/profile/mapper/profile_mapper.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';

import 'profile_event.dart';
import 'profile_state.dart';


class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository}) : super(ProfileLoading()) {
    on<LoadProfile>(_onLoadProfile);
    on<TogglePushNotification>(_onTogglePush);
    on<ToggleEmailNotification>(_onToggleEmail);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final profile = await profileRepository.getProfile();

      emit(
        ProfileLoaded(
          profile.toViewModel(), // ✅ map ตรงนี้
        ),
      );
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  void _onTogglePush(TogglePushNotification event, Emitter<ProfileState> emit) {
    if (state is ProfileLoaded) {
      final current = (state as ProfileLoaded).profile;

      emit(ProfileLoaded(current.copyWith(pushNotifications: event.value)));
    }
  }


  void _onToggleEmail(
    ToggleEmailNotification event,
    Emitter<ProfileState> emit,
  ) {
    if (state is ProfileLoaded) {
      final current = (state as ProfileLoaded).profile;

      emit(ProfileLoaded(current.copyWith(emailNotifications: event.value)));
    }
  }
}
