import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/auth/domain/repositories/auth_repository.dart';
import 'package:test_wpa/features/chat/data/services/chat_websocket_service.dart';
import 'package:flutter_modular/flutter_modular.dart';
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
      final storage = Modular.get<FlutterSecureStorage>();
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        Modular.get<ChatWebSocketService>().connect(token);

        // NotificationWebSocketService.instance.connect(token);
      }
      //คอยเก็บ token

      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('🔥 FCM Token: $fcmToken');
      if (fcmToken != null) {
        await authRepository.registerDeviceToken(fcmToken);
      }

      /// fcm
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
      // NotificationWebSocketService.instance.disconnect();
      await Modular.get<ChatWebSocketService>().disconnect();
      // ✅ เพิ่มตรงนี้ — ส่ง empty string ก่อน logout
      await authRepository.registerDeviceToken("");
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
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        newPasswordConfirmation: event.newPasswordConfirmation,
      );
      emit(ChangePasswordSuccess());
    } catch (e) {
      emit(ChangePasswordError(e.toString()));
    }
  }
}
