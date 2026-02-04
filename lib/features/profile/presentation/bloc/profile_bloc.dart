import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/profile/data/models/profile_model.dart';
import 'package:test_wpa/features/profile/data/repository/profile_repository_impl.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';
import 'package:test_wpa/features/profile/presentation/page/profile.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository}) : super(ProfileInitial()) {
    on<LoadProfile>((event, emit) async {
      emit(ProfileLoading());
      try {
        final profile = await profileRepository.getProfile();
        emit(ProfileLoaded(profile));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });
  }
}
