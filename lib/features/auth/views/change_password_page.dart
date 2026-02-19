// lib/features/auth/views/change_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  void _handleChange() {
    if (_formKey.currentState!.validate()) {
      // ✅ แจ้งเตือนก่อนว่าจะถูก logout
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.info_outline,
            color: AppColors.warning,
            size: 40,
          ),
          title: const Text(
            'Confirm Password Change',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'After changing your password,\nyou will be logged out automatically\nand need to login again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: space.s),
                Expanded(
                  child: AppButton(
                    text: 'Confirm',
                    onPressed: () {
                      Navigator.pop(context);
                      FocusScope.of(context).unfocus();
                      BlocProvider.of<AuthBloc>(context).add(
                        AuthChangePassword(
                          oldPassword: _oldPasswordCtrl.text,
                          newPassword: _newPasswordCtrl.text,
                        ),
                      );
                    },
                  ),
                ),
                // Expanded(

                // child: TextButton(
                //   onPressed: () {
                //     Navigator.pop(context);
                //     FocusScope.of(context).unfocus();
                //     BlocProvider.of<AuthBloc>(context).add(
                //       AuthChangePassword(
                //         oldPassword: _oldPasswordCtrl.text,
                //         newPassword: _newPasswordCtrl.text,
                //       ),
                //     );
                //   },
                //   style: TextButton.styleFrom(
                //     backgroundColor: AppColors.primary,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //   ),
                //   child: const Text(
                //     'Confirm',
                //     style: TextStyle(color: Colors.white),
                //   ),
                // ),
                // ),
              ],
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ChangePasswordSuccess) {
          // ✅ แสดง dialog สำเร็จ แล้ว navigate ไป login
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 48,
              ),
              title: const Text(
                'Password Changed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Your password has been changed.\nPlease login with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Login Again',
                    onPressed: () {
                      Navigator.pop(context); // ปิด dialog
                      Modular.to.navigate('/'); // ไปหน้า login
                    },
                  ),
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Change Password'),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
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

                      // Icon + Title
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

                      const SizedBox(height: space.xs),

                      const Center(
                        child: Text(
                          'You will be logged out after changing',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: space.xl),

                      // Old Password
                      AppTextFormField(
                        controller: _oldPasswordCtrl,
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
                        textInputAction: TextInputAction.done,
                        onSubmitted: () => _handleChange(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (value == _oldPasswordCtrl.text) {
                            return 'New password must be different';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: space.xl),

                      // ⚠️ Warning banner
                      Container(
                        padding: const EdgeInsets.all(space.m),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: space.s),
                            Expanded(
                              child: Text(
                                'You will be automatically logged out after changing your password.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.warning,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: space.l),

                      // Submit Button
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
