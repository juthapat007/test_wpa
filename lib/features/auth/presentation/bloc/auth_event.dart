// lib/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  AuthLoginEvent({required this.email, required this.password});
}

class AuthLogout extends AuthEvent {}

class AuthReset extends AuthEvent {}

class AuthForgotPassword extends AuthEvent {
  final String email;
  AuthForgotPassword({required this.email});
}

class AuthResetPassword extends AuthEvent {
  final String token;
  final String password;
  final String passwordConfirmation;
  AuthResetPassword({
    required this.token,
    required this.password,
    required this.passwordConfirmation,
  });
}

class AuthChangePassword extends AuthEvent {
  final String oldPassword;
  final String newPassword;
  AuthChangePassword({
    required this.oldPassword,
    required this.newPassword,
  });
}