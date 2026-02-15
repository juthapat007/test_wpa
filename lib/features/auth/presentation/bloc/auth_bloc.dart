import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/auth/domain/repositories/auth_repository.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLoginRequested);
    on<AuthLogout>(_onLogout);
    on<AuthReset>(_onReset);
  }

  Future<void> _onLoginRequested(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 Login requested...');
    emit(AuthLoading());
    try {
      // 1️⃣ login
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      print('✅ Login successful!');

      // ใช้ user (ไม่ใช่ delegate)
      final avatarUrl = result.user?.avatarUrl;

      // init dio
      await DioClient().init();

      // 3️⃣ emit success พร้อม avatar
      emit(AuthAuthenticated(avatarUrl: avatarUrl));
    } catch (e) {
      print('❌ Login error: $e');
      emit(AuthError('email or Password is wrong'));
      emit(AuthInitial());
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    print('🚪 Logout requested...');
    try {
      await authRepository.logout();
      print('✅ Logout successful!');
      emit(AuthUnauthenticated());
    } catch (e) {
      print('❌ Logout error: $e');
      // ถ้า error ก็ emit unauthenticated อยู่ดี
      emit(AuthUnauthenticated());
    }
  }

  void _onReset(AuthReset event, Emitter<AuthState> emit) {
    print('🔄 Auth reset');
    emit(AuthInitial());
  }
}
