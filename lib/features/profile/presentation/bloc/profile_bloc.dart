import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/profile/domain/entities/profile.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository}) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await profileRepository.getProfile();
      emit(ProfileLoaded(profile));
    } catch (e) {
      print(' ProfileBloc error: $e');
      emit(ProfileError('Cannot load profile: $e'));
    }
  }
}
