// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLoginRequested);
    on<AuthLogout>(_onLogout);
    on<AuthReset>(_onReset);
    on<AuthForgotPassword>(_onForgotPassword);
    on<AuthResetPassword>(_onResetPassword);
    on<AuthChangePassword>(_onChangePassword);
  }

  Future<void> _onLoginRequested(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      await DioClient().init();

      // ส่ง device token หลัง login ค่อยกลับมาเปิด
      // try {
      //   final fcmToken = await FirebaseMessaging.instance.getToken();
      //   if (fcmToken != null) {
      //     await authRepository.registerDeviceToken(fcmToken);
      //   }
      // } catch (e) {
      //   debugPrint('⚠️ FCM token failed: $e');
      // }
      emit(
        AuthAuthenticated(
          avatarUrl: result.user?.avatarUrl,
          name: result.user?.name,
          userId: result.user?.id.toString(),
        ),
      );
    } catch (e) {
      emit(AuthError('email or Password is wrong'));
      emit(AuthInitial());
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    try {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  void _onReset(AuthReset event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }

  Future<void> _onForgotPassword(
    AuthForgotPassword event,
    Emitter<AuthState> emit,
  ) async {
    print('📧 Forgot password: ${event.email}');
    emit(AuthLoading());
    try {
      await authRepository.forgotPassword(email: event.email);
      emit(ForgotPasswordSuccess());
    } catch (e) {
      emit(
        ForgotPasswordError('Failed to send reset email. Please try again.'),
      );
    }
  }

  Future<void> _onResetPassword(
    AuthResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    print('🔑 Resetting password...');
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(
        token: event.token,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
      );
      emit(ResetPasswordSuccess());
    } catch (e) {
      emit(
        ResetPasswordError('Failed to reset password. Token may be expired.'),
      );
    }
  }

  Future<void> _onChangePassword(
    AuthChangePassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      await authRepository.logout(); //ล้าง token
      emit(ChangePasswordSuccess());
    } catch (e) {
      emit(ChangePasswordError(e.toString()));
    }
  }
}
