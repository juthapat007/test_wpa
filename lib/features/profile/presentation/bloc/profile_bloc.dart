import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';
import 'package:test_wpa/features/profile/mapper/profile_mapper.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';
import 'package:test_wpa/features/profile/data/service/profile_api.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;
  final ProfileApi profileApi;

  ProfileBloc({required this.profileRepository, required this.profileApi})
    : super(ProfileLoading()) {
    on<LoadProfile>(_onLoadProfile);
    on<TogglePushNotification>(_onTogglePush);
    on<ToggleEmailNotification>(_onToggleEmail);
    on<UpdateProfileField>(_onUpdateProfileField);
    on<UpdateAvatar>(_onUpdateAvatar);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final profile = await profileRepository.getProfile();
      emit(ProfileLoaded(profile.toViewModel()));
    } catch (e) {
      print(' LoadProfile Error: $e');
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

  //แก้ไขให้ emit ProfileLoaded เท่านั้น พร้อม flag isUpdated
  Future<void> _onUpdateProfileField(
    UpdateProfileField event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentProfile = (state as ProfileLoaded).profile;

    try {
      // เตรียมข้อมูลสำหรับ API
      final Map<String, dynamic> updateData = {event.field: event.value};

      // เรียก API เพื่ออัพเดทข้อมูล
      final response = await profileApi.updateProfile(updateData);

      print('Profile updated successfully');

      // โหลดข้อมูลใหม่จาก API
      final updatedProfile = await profileRepository.getProfile();

      final storage = Modular.get<FlutterSecureStorage>();
      final userDataStr = await storage.read(key: 'user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
        userData['name'] = updatedProfile.toViewModel().name;
        userData['title'] = updatedProfile.toViewModel().title;
        await storage.write(key: 'user_data', value: jsonEncode(userData));
      }

      emit(ProfileLoaded(updatedProfile.toViewModel(), wasUpdated: true));
    } catch (e) {
      print(' Update profile error: $e');

      // กรณี error ให้แสดง error แล้วกลับไปที่ state เดิม
      emit(
        ProfileLoaded(
          currentProfile,
          updateError: 'Failed to update profile. Please try again.',
        ),
      );
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;
    final currentProfile = (state as ProfileLoaded).profile;
    final fileSize = await event.imageFile.length();
    if (fileSize > 4 * 1024 * 1024) {
      emit(
        ProfileLoaded(
          currentProfile,
          updateError: 'Image must be smaller than 4MB',
        ),
      );
      return;
    }

    try {
      await profileApi.uploadAvatar(event.imageFile);
      final updatedProfile = await profileRepository.getProfile();

      Modular.get<AuthBloc>().add(AuthUpdateAvatar(updatedProfile.avatarUrl));

      emit(ProfileLoaded(updatedProfile.toViewModel(), wasUpdated: true));
    } catch (e) {
      print('Upload avatar error: $e');
      emit(
        ProfileLoaded(currentProfile, updateError: 'Failed to upload avatar.'),
      );
    }
  }
}
