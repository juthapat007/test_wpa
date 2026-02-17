// lib/features/auth/presentation/bloc/auth_state.dart
part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String? avatarUrl;
  AuthAuthenticated({this.avatarUrl});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class ForgotPasswordSuccess extends AuthState {}

class ForgotPasswordError extends AuthState {
  final String message;
  ForgotPasswordError(this.message);
}

class ResetPasswordSuccess extends AuthState {}

class ResetPasswordError extends AuthState {
  final String message;
  ResetPasswordError(this.message);
}

class ChangePasswordSuccess extends AuthState {}

class ChangePasswordError extends AuthState {
  final String message;
  ChangePasswordError(this.message);
}