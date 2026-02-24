import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: Modular.get<NotificationBloc>()..add(LoadUnreadCount()),
        ),
        BlocProvider.value(
          value: Modular.get<ConnectionBloc>()..add(LoadConnectionRequests()),
        ),
      ],
      child: child,
    );
  }
}
