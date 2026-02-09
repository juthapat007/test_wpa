part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  AuthLoginEvent({required this.email, required this.password});
}

class LogoutEvent extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class AuthReset extends AuthEvent {}

class AuthLogout extends AuthEvent {}
