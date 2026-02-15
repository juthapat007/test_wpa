import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/profile/data/models/show_edit_profile.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_state.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_toggle_card.dart';
import '../widgets/profile_section_header.dart';
import '../widgets/logout_dialog.dart';

class ProfileView extends StatelessWidget {
  final ProfileState state;

  const ProfileView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // ✨ ใช้ BlocListener แยกจาก Builder เพื่อจัดการ side effects

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
                color: Colors.white,
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
                    // ProfileInfoCard(
                    //   label: 'My QR Code',
                    //   value: '',
                    //   showBorder: false,
                    //   trailing: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Container(
                    //         padding: const EdgeInsets.all(4),
                    //         decoration: BoxDecoration(
                    //           color: Colors.grey[200],
                    //           borderRadius: BorderRadius.circular(4),
                    //         ),
                    //         child: const Icon(
                    //           Icons.qr_code,
                    //           size: 24,
                    //           color: Colors.black87,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 8),
                    //       const Icon(Icons.chevron_right, color: Colors.grey),
                    //     ],
                    //   ),
                    //   onTap: () {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         content: Text('QR Code feature coming soon'),
                    //         duration: Duration(seconds: 2),
                    //       ),
                    //     );
                    //   },
                    // ),
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
                color: Colors.white,
                child: ProfileInfoCard(
                  label: 'Change Password',
                  value: '',
                  showBorder: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Change password feature coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ========== Notifications Section ==========
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ProfileSectionHeader(title: 'NOTIFICATIONS'),
              ),

              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    ProfileToggleCard(
                      label: 'Push Notifications',
                      value: profile.pushNotifications,
                      showBorder: true,
                      onChanged: (val) => context.read<ProfileBloc>().add(
                        TogglePushNotification(val),
                      ),
                    ),
                    ProfileToggleCard(
                      label: 'Email Notifications',
                      value: profile.emailNotifications,
                      showBorder: false,
                      onChanged: (val) => context.read<ProfileBloc>().add(
                        ToggleEmailNotification(val),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ========== Log Out Button ==========
              Center(
                child: TextButton(
                  onPressed: () => showLogoutDialog(context),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
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
            onPressed: () => context.read<ProfileBloc>().add(LoadProfile()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
