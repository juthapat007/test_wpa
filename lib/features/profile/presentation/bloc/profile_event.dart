import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class EditName extends ProfileEvent {}

class EditTitle extends ProfileEvent {}

class EditTeam extends ProfileEvent {}

class TogglePushNotification extends ProfileEvent {
  final bool value;

  const TogglePushNotification(this.value);

  @override
  List<Object?> get props => [value];
}

class ToggleEmailNotification extends ProfileEvent {
  final bool value;

  const ToggleEmailNotification(this.value);

  @override
  List<Object?> get props => [value];
}

// ✨ New Event for updating profile fields
class UpdateProfileField extends ProfileEvent {
  final String field;
  final String value;

  const UpdateProfileField({required this.field, required this.value});

  @override
  List<Object?> get props => [field, value];
}
