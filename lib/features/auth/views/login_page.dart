import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';
import 'package:test_wpa/features/widgets/app_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // print('UI email = ${_emailCtrl.text}');
      // print('UI password = ${_passwordCtrl.text}');
      FocusScope.of(context).unfocus();
      BlocProvider.of<AuthBloc>(context).add(
        AuthLoginEvent(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          print('login Done');
          Modular.to.navigate('/meeting');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: color.AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                    ),
                    const Text(
                      'Secure Delegate Login',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: space.m),
                    const Text(
                      'Global Logistics Conference',
                      style: TextStyle(fontSize: 16),
                    ),
                    AppTextFormField(
                      controller: _emailCtrl,
                      label: 'email',
                      icon: Icons.email,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: space.m),
                    AppTextFormField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      icon: Icons.lock,
                      obscureText: true,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _handleLogin,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: space.xl),
                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : AppButton(
                            text: 'Login',
                            textColor: AppColors.background,
                            backgroundColor: AppColors.primary,
                            onPressed: _handleLogin,
                          ),

                    SizedBox(height: space.m),
                    AppButton(
                      text: 'Forgot Password',
                      backgroundColor: AppColors.background,
                      onPressed: () {
                        Modular.to.navigate('/forgot_password');
                      },
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
