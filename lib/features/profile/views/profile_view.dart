import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/auth/views/change_password_page.dart';
import 'package:test_wpa/features/profile/data/models/show_edit_profile.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_state.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_toggle_card.dart';
import '../widgets/profile_section_header.dart';
import 'logout_dialog.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProfileView extends StatelessWidget {
  final ProfileState state;

  const ProfileView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // ฟังเฉพาะ ProfileLoaded state เท่านั้น
        if (state is ProfileLoaded) {
          // แสดง success message
          if (state.wasUpdated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Profile updated successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }

          // แสดง error message
          if (state.updateError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(child: Text(state.updateError!)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    /// ---------------- LOADING ----------------
    if (state is ProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    /// ---------------- ERROR ----------------
    if (state is ProfileError) {
      final errorState = state as ProfileError;
      return _ErrorView(message: errorState.message);
    }

    /// ---------------- LOADED ----------------
    if (state is ProfileLoaded) {
      final loadedState = state as ProfileLoaded;
      final profile = loadedState.profile;

      return Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== Avatar Section ==========
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ProfileAvatar(avatarUrl: profile.avatarUrl),
              ),

              const SizedBox(height: 16),

              // ========== Personal Info Section ==========
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  children: [
                    ProfileInfoCard(
                      label: 'Full Name',
                      value: profile.name,
                      showBorder: true,
                      onTap: () => _showEditDialog(
                        context,
                        'Full Name',
                        profile.name,
                        'name',
                      ),
                    ),
                    ProfileInfoCard(
                      label: 'Job Title',
                      value: profile.title,
                      showBorder: true,
                      onTap: () => _showEditDialog(
                        context,
                        'Job Title',
                        profile.title,
                        'title',
                      ),
                    ),
                    ProfileInfoCard(
                      label: 'Company',
                      value: profile.companyName,
                      iconEdit: false,
                      showBorder: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Company cannot be changed'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ========== Security Section ==========
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ProfileSectionHeader(title: 'SECURITY'),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  children: [
                    ProfileInfoCard(
                      label: 'Change Password',
                      value: '',
                      showBorder: false,
                      onTap: () {
                        Modular.to.pushNamed('/change_password');
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: height.m),

              // ========== Log Out Button ==========
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: AppButton(
                    onPressed: () => showLogoutDialog(context),
                    text: 'Log Out',
                    textColor: color.AppColors.surface,
                    backgroundColor: color.AppColors.error,
                  ),
                ),
              ),

              SizedBox(height: space_bottom.l),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    String field,
  ) {
    showEditProfileDialog(
      context: context,
      title: title,
      currentValue: currentValue,
      field: field,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: color.AppColors.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.AppColors.error),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                ReadContext(context).read<ProfileBloc>().add(LoadProfile()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
