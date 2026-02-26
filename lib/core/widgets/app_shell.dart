// lib/core/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    // ใช้ BlocProvider.value เพื่อไม่ให้ dispose bloc เมื่อ route เปลี่ยน
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: Modular.get<AuthBloc>()),
        BlocProvider.value(value: Modular.get<ChatBloc>()),
        BlocProvider.value(value: Modular.get<NotificationBloc>()),
        BlocProvider.value(value: Modular.get<ConnectionBloc>()),
      ],
      child: widget.child,
    );
  }
}
