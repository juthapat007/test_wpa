// lib/app/app_module.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
import 'package:test_wpa/features/chat/presentation/pages/connected_chat.dart';
import 'package:test_wpa/features/meeting/presentation/page/meeting_page.dart';
import 'package:test_wpa/features/notification/data/repository/connection_repository_impl.dart';
import 'package:test_wpa/features/notification/data/services/connection_api.dart';
import 'package:test_wpa/features/notification/domain/repositories/connection_repository.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/auth/views/change_password_page.dart';

// Profile
import 'package:test_wpa/features/profile/data/repository/profile_repository_impl.dart';
import 'package:test_wpa/features/profile/data/service/profile_api.dart';
import 'package:test_wpa/features/profile/domain/repositories/profile_repository.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';
import 'package:test_wpa/features/profile/presentation/page/profile_page.dart';
import 'package:test_wpa/features/scan/data/repositories/qr_repository_impl.dart';
import 'package:test_wpa/features/scan/data/services/qr_api.dart';
import 'package:test_wpa/features/scan/domain/repositories/qr_repository.dart';

// Schedule
import 'package:test_wpa/features/schedules/data/repository/schedule_repository_impl.dart';
import 'package:test_wpa/features/schedules/data/services/schedule_api.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/page/schedule_widget.dart';

// ✅ Schedule Others (เพิ่มใหม่)
import 'package:test_wpa/features/schedules/data/services/schedule_others_api.dart';
import 'package:test_wpa/features/schedules/data/repository/schedule_others_repository_impl.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_others_repository.dart';

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

// Chat
import 'package:test_wpa/features/chat/data/repository/chat_repository_impl.dart';
import 'package:test_wpa/features/chat/data/services/chat_api.dart';
import 'package:test_wpa/features/chat/data/services/chat_websocket_service.dart';
import 'package:test_wpa/features/chat/domain/repositories/chat_repository.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_room_list_widget.dart';
import 'package:test_wpa/features/chat/presentation/pages/chat_conversation_page.dart';

// Notification
import 'package:test_wpa/features/notification/data/repository/notification_repository_impl.dart';
import 'package:test_wpa/features/notification/data/services/notification_api.dart';
import 'package:test_wpa/features/notification/domain/repositories/notification_repository.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/presentation/page/notification.dart';

// other Profile
import 'package:test_wpa/features/other_profile/data/repository/profile_detail_repository_impl.dart';
import 'package:test_wpa/features/other_profile/data/services/profile_detail_api.dart';
import 'package:test_wpa/features/other_profile/domain/repositories/profile_detail_repository.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_bloc.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/pages/other_profile_page.dart';

// Other features
import 'package:flutter_bloc/flutter_bloc.dart';
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
    i.add<AuthBloc>(
      () => AuthBloc(authRepository: Modular.get<AuthRepository>()),
    );

    /// ================= Profile =================
    i.addLazySingleton<ProfileApi>(() => ProfileApi(Modular.get<Dio>()));
    i.addLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(api: Modular.get<ProfileApi>()),
    );
    i.addLazySingleton<ProfileBloc>(
      () => ProfileBloc(
        profileRepository: Modular.get<ProfileRepository>(),
        profileApi: Modular.get<ProfileApi>(),
      ),
    );

    /// ================= Schedule =================
    i.addLazySingleton<ScheduleApi>(() => ScheduleApi(Modular.get<Dio>()));
    i.addLazySingleton<ScheduleRepository>(
      () => ScheduleRepositoryImpl(api: Modular.get<ScheduleApi>()),
    );
    i.addLazySingleton<ScheduleBloc>(
      () => ScheduleBloc(scheduleRepository: Modular.get<ScheduleRepository>()),
    );

    /// ================= Schedule Others =================
    i.addLazySingleton<ScheduleOthersApi>(
      () => ScheduleOthersApi(dio: Modular.get<Dio>()),
    );
    i.addLazySingleton<ScheduleOthersRepository>(
      () => ScheduleOthersRepositoryImpl(api: Modular.get<ScheduleOthersApi>()),
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

    /// ================= Chat =================
    i.addLazySingleton<ChatApi>(() => ChatApi(Modular.get<Dio>()));
    i.addLazySingleton<ChatWebSocketService>(() => ChatWebSocketService());
    i.addLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        api: Modular.get<ChatApi>(),
        webSocketService: Modular.get<ChatWebSocketService>(),
        storage: Modular.get<FlutterSecureStorage>(),
      ),
    );
    i.addLazySingleton<ChatBloc>(
      () => ChatBloc(chatRepository: Modular.get<ChatRepository>()),
    );

    /// ================= Notification =================
    i.addLazySingleton<NotificationApi>(
      () => NotificationApi(Modular.get<Dio>()),
    );
    i.addLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(api: Modular.get<NotificationApi>()),
    );
    i.addLazySingleton<NotificationBloc>(
      () => NotificationBloc(
        notificationRepository: Modular.get<NotificationRepository>(),
      ),
    );

    /// ================= Connection =================
    i.addLazySingleton<ConnectionApi>(() => ConnectionApi(Modular.get<Dio>()));
    i.addLazySingleton<ConnectionRepository>(
      () => ConnectionRepositoryImpl(api: Modular.get<ConnectionApi>()),
    );
    i.addLazySingleton<ConnectionBloc>(
      () => ConnectionBloc(
        connectionRepository: Modular.get<ConnectionRepository>(),
      ),
    );

    /// ================= Scan / QR Code =================
    i.addLazySingleton<QrApi>(() => QrApi(Modular.get<Dio>()));
    i.addLazySingleton<QrRepository>(
      () => QrRepositoryImpl(api: Modular.get<QrApi>()),
    );
    i.addLazySingleton<ScanBloc>(
      () => ScanBloc(qrRepository: Modular.get<QrRepository>()),
    );

    /// ================= other Profile =================
    i.addLazySingleton<ProfileDetailApi>(
      () => ProfileDetailApi(Modular.get<Dio>()),
    );
    i.addLazySingleton<ProfileDetailRepository>(
      () => ProfileDetailRepositoryImpl(api: Modular.get<ProfileDetailApi>()),
    );
    i.add<ProfileDetailBloc>(
      () => ProfileDetailBloc(
        profileDetailRepository: Modular.get<ProfileDetailRepository>(),
        connectionRepository: Modular.get<ConnectionRepository>(),
        scheduleOthersRepository: Modular.get<ScheduleOthersRepository>(),
      ),
    );
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

    //  Meeting
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

    r.child('/chat', child: (_) => const ConnectedChat());

    r.child('/chat/room', child: (_) => const ChatConversationPage());

    r.child(
      '/scan',
      child: (_) => BlocProvider.value(
        value: Modular.get<ScanBloc>(),
        child: const Scan(),
      ),
    );

    r.child(
      '/profile',
      child: (_) => BlocProvider.value(
        value: Modular.get<ProfileBloc>()..add(LoadProfile()),
        child: const ProfilePage(),
      ),
    );

    r.child(
      '/notification',
      child: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: Modular.get<NotificationBloc>()),
          BlocProvider.value(value: Modular.get<ConnectionBloc>()),
        ],
        child: const NotificationWidget(),
      ),
    );

    r.child(
      '/schedule',
      child: (_) => BlocProvider.value(
        value: Modular.get<ScheduleBloc>()..add(LoadSchedules()),
        child: const ScheduleWidget(),
      ),
    );

    // เพิ่มใน routes() ต่อจาก /other_profile เดิม
    r.child(
      '/other-profile/:id',
      child: (_) {
        final delegateId = int.tryParse(r.args.params['id'] ?? '');

        if (delegateId == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Invalid delegate ID')),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  Modular.get<ProfileDetailBloc>()
                    ..add(LoadProfileDetail(delegateId)),
            ),
            BlocProvider.value(value: Modular.get<ChatBloc>()),
          ],
          child: OtherProfilePage(delegateId: delegateId),
        );
      },
    );
    r.child(
      '/change_password',
      child: (_) => BlocProvider.value(
        value: Modular.get<AuthBloc>(),
        child: ChangePasswordPage(),
      ),
    );
  }
}
