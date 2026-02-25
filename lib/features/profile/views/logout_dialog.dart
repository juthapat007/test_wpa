import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/widgets/app_dialog.dart';

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AppDialog(
      title: 'Log Out',
      description: 'Are you sure you want to log out?',
      actions: [
        AppDialogAction(
          backgroundColor: AppColors.background,
          onPressed: () => Navigator.pop(context),
          label: 'Cancel',
        ),
        AppDialogAction(
          label: 'Log Out',
          isPrimary: true,
          backgroundColor: AppColors.error,
          onPressed: () async {
            Navigator.pop(context);

            try {
              final authBloc = Modular.get<AuthBloc>();
              authBloc.add(AuthLogout());
              await Future.delayed(const Duration(milliseconds: 300));
              Modular.to.navigate('/');
            } catch (e) {
              print('Logout error: $e');
              // ถ้า error ให้ navigate อยู่ดี
              Modular.to.navigate('/');
            }
          },
        ),
      ],
    ),
  );
}
