import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('AuthBloc state changed: ${state.runtimeType}');

        if (state is AuthUnauthenticated) {
          print('Navigating to login...');
          Modular.to.navigate('/login');
        }
      },
      child: const RouterOutlet(),
    );
  }
}
