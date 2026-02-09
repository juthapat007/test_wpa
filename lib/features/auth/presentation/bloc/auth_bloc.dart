import 'package:bloc/bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/auth/domain/repositories/auth_repository.dart';
import 'package:test_wpa/features/auth_local_storage.dart';
import 'package:flutter_modular/flutter_modular.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLoginRequested);
    on<AuthLogout>(_onLogout);
    on<AuthReset>(_onReset);
  }

  // Future<void> _onLoginRequested(
  //   AuthLoginEvent event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   emit(AuthLoading());
  //   try {
  //     // 1️⃣ login (ภายในนี้คุณ save token แล้ว)
  //     await authRepository.login(email: event.email, password: event.password);

  //     // ⭐ 2️⃣ re-init Dio เพื่อแนบ token กับทุก request
  //     await DioClient().init();

  //     // 3️⃣ login success
  //     emit(AuthAuthenticated());
  //   } catch (e) {
  //     emit(AuthError('email or Password is wrong'));
  //     emit(AuthInitial());
  //   }
  // }

  Future<void> _onLoginRequested(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // 1️login
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      //  ใช้ user (ไม่ใช่ delegate)
      final avatarUrl = result.user?.avatarUrl;

      //init dio
      await DioClient().init();

      // 3️⃣ emit success พร้อม avatar
      emit(AuthAuthenticated(avatarUrl: avatarUrl));
    } catch (e) {
      emit(AuthError('email or Password is wrong'));
      emit(AuthInitial());
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }

  void _onReset(AuthReset event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
