// forgot_password.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }
    FocusScope.of(context).unfocus();
    ReadContext(context).read<AuthBloc>().add(AuthForgotPassword(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reset link sent! Please check your email.'),
              backgroundColor: AppColors.success,
            ),
          );
          Modular.to.navigate('/');
        } else if (state is ForgotPasswordError) {
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
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: space.l),
                    AppBar(
                      title: const Text('Forgot password?'),
                      backgroundColor: AppColors.background,
                      elevation: 0,
                    ),

                    const Text(
                      'Please enter your email to send the password reset link',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: space.l),
                    AppTextFormField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: space.l),
                    isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.primary,
                          )
                        : AppButton(
                            text: 'Send',
                            textColor: AppColors.textOnPrimary,
                            backgroundColor: AppColors.primary,
                            onPressed: _handleSend,
                          ),
                    const Spacer(),
                    AppButton(
                      text: 'Back to login',
                      backgroundColor: AppColors.background,
                      onPressed: () => Modular.to.navigate('/'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
