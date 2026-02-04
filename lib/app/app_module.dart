import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/core/constants/setup_Logger.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/interceptors/auth_interceptor.dart';
import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/auth/data/repository/auth_repository_impl.dart';
import 'package:test_wpa/features/auth/data/services/auth_api.dart';
import 'package:test_wpa/features/auth/domain/repository/auth_repository.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/auth/views/forgot_password.dart';
import 'package:test_wpa/features/auth/views/login_page.dart';
import 'package:test_wpa/features/auth_local_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat.dart';
import 'package:test_wpa/features/event/presentation/bloc/event_bloc.dart';
import 'package:test_wpa/features/event/views/event.dart';
import 'package:test_wpa/features/meeting/presentation/bloc/meeting_bloc.dart';
import 'package:test_wpa/features/meeting/views/meeting_page.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/presentation/page/notification.dart';
import 'package:test_wpa/features/profile/data/repository/service/profile_api.dart';
import 'package:test_wpa/features/profile/data/repository/profile_repository_impl.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/page/profile.dart';
import 'package:test_wpa/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:test_wpa/features/scan/views/scan.dart';
import 'package:test_wpa/features/search/presentation/bloc/search_bloc.dart';
import 'package:test_wpa/features/search/views/search_page.dart';

class AppModule extends Module {
  @override
  @override
  void binds(i) {
    /// ===== Core =====
    i.addSingleton<Dio>(() => DioClient().dio);
    i.addInstance<FlutterSecureStorage>(const FlutterSecureStorage());

    /// ===== Auth =====
    i.addLazySingleton<AuthApi>(() => AuthApi(i()));
    i.addLazySingleton<AuthRepository>(() => AuthRepositoryImpl(i()));
    i.addLazySingleton<AuthBloc>(() => AuthBloc(authRepository: i()));

    /// ===== Profile =====
    i.addLazySingleton<ProfileApi>(() => ProfileApi(i()));

    i.addLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(i()));

    // i.addLazySingleton<ProfileBloc>(() => ProfileBloc(profileRepository: i()));
    i.add<ProfileBloc>(() => ProfileBloc(profileRepository: i()));
  }

  @override
  void routes(r) {
    /// ===== Public =====
    // r.child(
    //   '/',
    //   child: (_) => BlocProvider<AuthBloc>(
    //     create: (_) => Modular.get<AuthBloc>(),
    //     child: const LoginPage(),
    //   ),
    // );
    r.child(
      '/',
      child: (_) => BlocProvider.value(
        value: Modular.get<AuthBloc>(),
        child: const LoginPage(),
      ),
    );

    r.child('/forgot_password', child: (_) => const ForgotPasswordPage());

    /// ===== Protected =====
    r.child(
      '/search',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<SearchBloc>(),
        child: const SearchPage(),
      ),
    );

    r.child(
      '/meeting',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<MeetingBloc>(),
        child: const MeetingPage(),
      ),
    );

    r.child(
      '/chat',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<ChatBloc>(),
        child: const ChatPage(),
      ),
    );

    r.child(
      '/event',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<EventBloc>(),
        child: const EventPage(),
      ),
    );

    r.child(
      '/scan',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<ScanBloc>(),
        child: const Scan(),
      ),
    );

    r.child(
      '/profile',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<ProfileBloc>()..add(LoadProfile()),
        child: const Profile(),
      ),
    );

    r.child(
      '/notification',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<NotificationBloc>(),
        child: const Notification(),
      ),
    );
  }
}
