import 'package:equatable/equatable.dart';
import 'package:test_wpa/features/profile/data/models/profile_view_Model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileViewModel profile;
  final bool wasUpdated; 
  final String? updateError; 

  const ProfileLoaded(
    this.profile, {
    this.wasUpdated = false,
    this.updateError,
  });

  @override
  List<Object?> get props => [profile, wasUpdated, updateError];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileViewModel profile;
  const ProfileUpdateSuccess(this.profile);
}

class ProfileUpdateError extends ProfileState {
  final String message;
  const ProfileUpdateError(this.message);
}
