// lib/features/auth/views/change_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/widgets/app_bar_back.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_dialog.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _handleChange() {
    if (!_formKey.currentState!.validate()) return;

    // ✅ capture bloc ก่อนเปิด dialog เพราะ dialog context ไม่มี AuthBloc
    final bloc = BlocProvider.of<AuthBloc>(context);

    // showDialog เอาไว้แสดง pop_up
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        icon: Icons.lock_outline,
        iconColor: AppColors.primary,
        title: 'Confirm',
        description: 'Are you sure you want to change your password?',
        actions: [
          AppDialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(dialogContext),
            backgroundColor: AppColors.surface,
            // ไม่ต้องใส่อะไรเพิ่ม → ใช้ default style
          ),
          AppDialogAction(
            label: 'Confirm',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(
                AuthChangePassword(
                  currentPassword: _currentPasswordCtrl.text,
                  newPassword: _newPasswordCtrl.text,
                  newPasswordConfirmation: _confirmPasswordCtrl.text,
                ),
              );
            },
            backgroundColor: null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ChangePasswordSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AppDialog(
              icon: Icons.check_circle_outline,
              iconColor: AppColors.success,
              title: 'Password Changed!',
              description: 'Your password has been changed successfully.',
              actions: [
                AppDialogAction(
                  label: 'OK',
                  isPrimary: true,
                  onPressed: () {
                    Navigator.pop(dialogContext); // ปิด dialog
                    Navigator.of(
                      dialogContext,
                    ).pop(); // ออกจาก change_password_page
                  },
                  textColor: AppColors.surface,
                  backgroundColor: null,
                ),
              ],
            ),
          );
        } else if (state is ChangePasswordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: const AppBarBack(title: 'Change Password'),

        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(space.m),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: space.l),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(space.l),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: space.l),

                      const Center(
                        child: Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: space.xl),

                      // Current Password
                      AppTextFormField(
                        controller: _currentPasswordCtrl,
                        label: 'Current Password',
                        icon: Icons.lock_outlined,
                        obscureText: true,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: space.m),

                      // New Password
                      AppTextFormField(
                        controller: _newPasswordCtrl,
                        label: 'New Password',
                        icon: Icons.lock_outlined,
                        obscureText: true,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (value == _currentPasswordCtrl.text) {
                            return 'New password must be different from current';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: space.m),

                      // Confirm New Password
                      AppTextFormField(
                        controller: _confirmPasswordCtrl,
                        label: 'Confirm New Password',
                        icon: Icons.lock_outlined,
                        obscureText: true,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: space.l),

                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : AppButton(
                              text: 'Change Password',
                              textColor: AppColors.textOnPrimary,
                              backgroundColor: AppColors.primary,
                              onPressed: _handleChange,
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
