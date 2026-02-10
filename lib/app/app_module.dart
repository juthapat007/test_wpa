// lib/app/app_module.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/network/dio_client.dart';

// Auth
import 'package:test_wpa/features/auth/data/repository/auth_repository_impl.dart';
import 'package:test_wpa/features/auth/data/services/auth_api.dart';
import 'package:test_wpa/features/auth/domain/repositories/auth_repository.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/auth/views/forgot_password.dart';
import 'package:test_wpa/features/auth/views/login_page.dart';

// Profile
import 'package:test_wpa/features/profile/data/repository/profile_repository_impl.dart';
import 'package:test_wpa/features/profile/data/repository/service/profile_api.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/page/profile_widget.dart';

// Schedule
import 'package:test_wpa/features/schedules/data/repository/schedule_repository_impl.dart';
import 'package:test_wpa/features/schedules/data/services/schedule_api.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/page/schedule_widget.dart';

// Search
import 'package:test_wpa/features/search/data/repository/delegate_repository_impl.dart';
import 'package:test_wpa/features/search/data/services/delegate_api.dart';
import 'package:test_wpa/features/search/domain/repositories/delegate_repository.dart';
import 'package:test_wpa/features/search/presentation/bloc/search_bloc.dart';
import 'package:test_wpa/features/search/views/search_page.dart';

// Meeting & Table
import 'package:test_wpa/features/meeting/data/repository/table_repository_impl.dart';
import 'package:test_wpa/features/meeting/data/services/table_api.dart';
import 'package:test_wpa/features/meeting/domain/repositories/table_repository.dart';
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart';
import 'package:test_wpa/features/meeting/views/meeting_page.dart';

// Other features
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat.dart';
import 'package:test_wpa/features/event/presentation/bloc/event_bloc.dart';
import 'package:test_wpa/features/event/views/event.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/presentation/page/notification.dart';
import 'package:test_wpa/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:test_wpa/features/scan/views/scan.dart';

class AppModule extends Module {
  @override
  void binds(i) {
    /// ================= Core =================
    i.addInstance<Dio>(DioClient.createDio());
    i.addInstance<FlutterSecureStorage>(const FlutterSecureStorage());

    /// ================= Auth =================
    i.addLazySingleton<AuthApi>(() => AuthApi(Modular.get<Dio>()));
    i.addLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(Modular.get<AuthApi>()),
    );
    i.addLazySingleton<AuthBloc>(
      () => AuthBloc(authRepository: Modular.get<AuthRepository>()),
    );

    /// ================= Profile =================
    i.addLazySingleton<ProfileApi>(() => ProfileApi(Modular.get<Dio>()));
    i.addLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(api: Modular.get<ProfileApi>()),
    );
    i.addLazySingleton<ProfileBloc>(
      () => ProfileBloc(profileRepository: Modular.get<ProfileRepository>()),
    );

    /// ================= Schedule =================
    i.addLazySingleton<ScheduleApi>(() => ScheduleApi(Modular.get<Dio>()));
    i.addLazySingleton<ScheduleRepository>(
      () => ScheduleRepositoryImpl(api: Modular.get<ScheduleApi>()),
    );
    i.addLazySingleton<ScheduleBloc>(
      () => ScheduleBloc(scheduleRepository: Modular.get<ScheduleRepository>()),
    );

    /// ================= Search/Delegate =================
    i.addLazySingleton<DelegateApi>(() => DelegateApi(Modular.get<Dio>()));
    i.addLazySingleton<DelegateRepository>(
      () => DelegateRepositoryImpl(api: Modular.get<DelegateApi>()),
    );
    i.addLazySingleton<SearchBloc>(
      () => SearchBloc(delegateRepository: Modular.get<DelegateRepository>()),
    );

    /// ================= Meeting & Table =================
    i.addLazySingleton<TableApi>(() => TableApi(Modular.get<Dio>()));
    i.addLazySingleton<TableRepository>(
      () => TableRepositoryImpl(api: Modular.get<TableApi>()),
    );
    i.addLazySingleton<TableBloc>(
      () => TableBloc(tableRepository: Modular.get<TableRepository>()),
    );

    /// ================= Other Feature Blocs =================
    // i.addLazySingleton<MeetingBloc>(() => MeetingBloc());
    i.addLazySingleton<ChatBloc>(() => ChatBloc());
    i.addLazySingleton<EventBloc>(() => EventBloc());
    i.addLazySingleton<ScanBloc>(() => ScanBloc());
    i.addLazySingleton<NotificationBloc>(() => NotificationBloc());
  }

  @override
  void routes(r) {
    /// ===== Public =====
    r.child(
      '/',
      child: (_) => BlocProvider<AuthBloc>(
        create: (_) => Modular.get<AuthBloc>(),
        child: const LoginPage(),
      ),
    );

    r.child('/forgot_password', child: (_) => const ForgotPasswordPage());

    /// ===== Protected =====

    //  Meeting - ต้อง provide ทั้ง ScheduleBloc และ TableBloc
    r.child(
      '/meeting',
      child: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: Modular.get<ScheduleBloc>()),
          BlocProvider.value(value: Modular.get<TableBloc>()),
        ],
        child: const MeetingPage(),
      ),
    );

    r.child(
      '/search',
      child: (_) => BlocProvider.value(
        value: Modular.get<SearchBloc>()..add(SearchDelegates()),
        child: const SearchPage(),
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
      child: (_) => BlocProvider.value(
        value: Modular.get<ProfileBloc>()..add(LoadProfile()),
        child: const ProfileWidget(),
      ),
    );

    r.child(
      '/notification',
      child: (_) => BlocProvider(
        create: (_) => Modular.get<NotificationBloc>(),
        child: const Notification(),
      ),
    );

    r.child(
      '/schedule',
      child: (_) => BlocProvider.value(
        value: Modular.get<ScheduleBloc>()..add(LoadSchedules()),
        child: const ScheduleWidget(),
      ),
    );
  }
}
