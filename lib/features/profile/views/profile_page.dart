import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/theme/app_colors.dart' as colors;
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool pushNotifications = true;
  bool emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Personal Information',
      currentIndex: -1,
      showAvatar: false,
      backgroundColor: color.AppColors.background,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            final profile = state.profile;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: profile.avatarUrl.isNotEmpty
                                    ? NetworkImage(profile.avatarUrl)
                                    : const AssetImage(
                                            'assets/images/empty_state.png',
                                          )
                                          as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(
                                color: color.AppColors.background,
                                width: 2,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Personal Info Section
                    _buildSectionHeader('PERSONAL INFO'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      label: 'Full Name',
                      value: profile.name,
                      onTap: () {
                        // TODO: Open edit dialog
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      label: 'Job Title',
                      value: profile.title,
                      onTap: () {
                        // TODO: Open edit dialog
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      label: 'Team',
                      value: profile.teamName,
                      onTap: () {
                        // TODO: Open edit dialog
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildQRCodeCard(),
                    const SizedBox(height: 30),

                    // Security Section
                    _buildSectionHeader('SECURITY'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      label: 'Change Password',
                      value: '',
                      onTap: () {
                        // TODO: Navigate to change password
                      },
                      showValue: false,
                    ),
                    const SizedBox(height: 30),

                    // Notifications Section
                    _buildSectionHeader('NOTIFICATIONS'),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      label: 'Push Notifications',
                      value: pushNotifications,
                      onChanged: (val) {
                        setState(() {
                          pushNotifications = val;
                        });
                        // TODO: Save notification preference
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      label: 'Email Notifications',
                      value: emailNotifications,
                      onChanged: (val) {
                        setState(() {
                          emailNotifications = val;
                        });
                        // TODO: Save notification preference
                      },
                    ),
                    const SizedBox(height: 40),

                    // Log Out Button
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: space.m),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ReadContext(
                        context,
                      ).read<ProfileBloc>().add(LoadProfile());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool showValue = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (showValue && value.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'My QR Code',
                style: TextStyle(
                  fontSize: 12,
                  color: color.AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2,
                  size: 40,
                  color: color.AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.AppColors.surface),
        boxShadow: [
          BoxShadow(
            color: colors.AppColors.textPrimary.withAlpha(80),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: colors.AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                //  Logout using AuthBloc
                // Token จะถูกลบใน authRepository.logout()
                // และ app_view.dart จะ navigate ไปหน้า login อัตโนมัติ
                ReadContext(context).read<AuthBloc>().add(AuthLogout());
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
