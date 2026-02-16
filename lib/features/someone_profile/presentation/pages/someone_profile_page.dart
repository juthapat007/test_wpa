// lib/features/someone_profile/presentation/pages/someone_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/search/domain/entities/delegate.dart';
import 'package:test_wpa/features/someone_profile/presentation/bloc/profile_detail_bloc.dart';
import 'package:test_wpa/features/someone_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/someone_profile/presentation/bloc/profile_detail_state.dart';
import 'package:test_wpa/features/someone_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/widgets/app_button.dart';

class SomeoneProfilePage extends StatefulWidget {
  final Delegate delegate; // ✅ รับ Delegate object แทน

  const SomeoneProfilePage({super.key, required this.delegate});

  @override
  State<SomeoneProfilePage> createState() => _SomeoneProfilePageState();
}

class _SomeoneProfilePageState extends State<SomeoneProfilePage> {
  @override
  void initState() {
    super.initState();
    // ✅ แปลง Delegate เป็น ProfileDetail แล้วโหลดเข้า BLoC
    final profile = ProfileDetail(
      id: widget.delegate.id,
      name: widget.delegate.name,
      title: widget.delegate.title,
      email: widget.delegate.email,
      companyName: widget.delegate.companyName,
      avatarUrl: widget.delegate.avatarUrl,
      countryCode: widget.delegate.countryCode,
      isConnected: widget.delegate.isConnected,
    );

    // โหลด profile เข้า state
    context.read<ProfileDetailBloc>().emit(ProfileDetailLoaded(profile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: color.AppColors.surface,
      ),
      body: BlocListener<ProfileDetailBloc, ProfileDetailState>(
        listener: (context, state) {
          if (state is FriendRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: color.AppColors.success,
              ),
            );
          } else if (state is FriendRequestFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: color.AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<ProfileDetailBloc, ProfileDetailState>(
          builder: (context, state) {
            if (state is ProfileDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: color.AppColors.primary,
                ),
              );
            }

            if (state is ProfileDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: color.AppColors.error,
                    ),
                    SizedBox(height: space.m),
                    Text(
                      state.message,
                      style: const TextStyle(color: color.AppColors.error),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileDetailLoaded || state is FriendRequestSending) {
              final profile = state is ProfileDetailLoaded
                  ? state.profile
                  : null;

              if (profile == null) {
                return const Center(child: Text('No profile data'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: profile.avatarUrl.isNotEmpty
                          ? NetworkImage(profile.avatarUrl)
                          : null,
                      child: profile.avatarUrl.isEmpty
                          ? Text(
                              profile.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 40),
                            )
                          : null,
                    ),

                    SizedBox(height: space.l),

                    // Name
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color.AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: space.xs),

                    // Title
                    if (profile.title != null && profile.title!.isNotEmpty)
                      Text(
                        profile.title!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: color.AppColors.textSecondary,
                        ),
                      ),

                    SizedBox(height: space.m),

                    // Company
                    _buildInfoRow(
                      icon: Icons.business,
                      label: 'Company',
                      value: profile.companyName,
                    ),

                    // Email
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: profile.email,
                    ),

                    // Country
                    _buildInfoRow(
                      icon: Icons.flag,
                      label: 'Country',
                      value: profile.countryCode,
                    ),

                    SizedBox(height: space.xl),

                    // Connection Status & Add Friend Button
                    _buildConnectionSection(profile, context),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.AppColors.textSecondary),
          SizedBox(width: space.s),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: color.AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection(ProfileDetail profile, BuildContext context) {
    return Column(
      children: [
        // Connection Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: profile.isConnected
                ? color.AppColors.success.withOpacity(0.1)
                : color.AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: profile.isConnected
                  ? color.AppColors.success
                  : color.AppColors.warning,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                profile.isConnected ? Icons.people : Icons.person_add_disabled,
                size: 18,
                color: profile.isConnected
                    ? color.AppColors.success
                    : color.AppColors.warning,
              ),
              SizedBox(width: space.xs),
              Text(
                profile.isConnected ? '✓ Connected' : 'Not Connected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: profile.isConnected
                      ? color.AppColors.success
                      : color.AppColors.warning,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: space.l),

        // Add Friend Button (only show if not connected)
        if (!profile.isConnected)
          AppButton(
            text: 'Add Friend',
            backgroundColor: color.AppColors.primary,
            textColor: color.AppColors.textOnPrimary,
            onPressed: () {
              context.read<ProfileDetailBloc>().add(
                SendFriendRequest(profile.id),
              );
            },
          ),

        // Message Button (if connected)
        if (profile.isConnected) ...[
          AppButton(
            text: 'Send Message',
            backgroundColor: color.AppColors.primary,
            textColor: color.AppColors.textOnPrimary,
            onPressed: () {
              // TODO: Navigate to chat with this user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming soon!')),
              );
            },
          ),
          SizedBox(height: space.s),
          AppButton(
            text: 'View Schedule',
            backgroundColor: color.AppColors.background,
            textColor: color.AppColors.primary,
            onPressed: () {
              // TODO: Navigate to their schedule
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule view coming soon!')),
              );
            },
          ),
        ],
      ],
    );
  }
}
