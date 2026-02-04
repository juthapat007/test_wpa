import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';
import 'package:test_wpa/features/widgets/menu_button.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: space.l),

              // Title
              const Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: space.xs),

              // Description
              const Text(
                'Please enter your email to send the password reset link',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              SizedBox(height: space.xl),

              // Email field
              AppTextFormField(
                controller: emailController,
                label: 'email',
                icon: Icons.email,

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),

              SizedBox(height: space.l),

              // Reset password button
              AppButton(
                text: 'Send',
                textColor: AppColors.textOnPrimary,
                backgroundColor: AppColors.primary,
                onPressed: () {
                  final email = emailController.text.trim();

                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plase enter your email')),
                    );
                    return;
                  }

                  // TODO: เรียก API reset password ตรงนี้
                  debugPrint('Reset password for $email');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sent email successfully')),
                  );
                },
              ),

              const Spacer(),

              AppButton(
                text: 'Back to login',
                onPressed: () {
                  Modular.to.navigate('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
