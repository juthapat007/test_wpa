import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_theme.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc
        BlocProvider<AuthBloc>(create: (_) => Modular.get<AuthBloc>()),
        // ChatBloc
        BlocProvider<ChatBloc>(
          create: (_) => Modular.get<ChatBloc>()
            ..add(ConnectWebSocket())
            ..add(LoadChatRooms()),
        ),
        // NotificationBloc - for unread badge across the app
        BlocProvider<NotificationBloc>(
          create: (_) =>
              Modular.get<NotificationBloc>()..add(LoadUnreadCount()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: Modular.routerConfig,
      ),
    );
  }
}

//เป็นหน้าหลักของแอป
