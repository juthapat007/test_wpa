import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_state.dart';
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

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileAvatar(avatarUrl: profile.avatarUrl),

            const SizedBox(height: 30),

            const ProfileSectionHeader(title: 'PERSONAL INFO'),
            const SizedBox(height: 12),

            ProfileInfoCard(
              label: 'Full Name',
              value: profile.name,
              onTap: () => context.read<ProfileBloc>().add(EditName()),
            ),

            const SizedBox(height: 12),

            ProfileInfoCard(
              label: 'Job Title',
              value: profile.title,
              onTap: () => context.read<ProfileBloc>().add(EditTitle()),
            ),

            const SizedBox(height: 12),
            ProfileInfoCard(
              label: 'Team',
              value: profile.teamName,
              onTap: () {},
            ),

            const SizedBox(height: 12),
            ProfileInfoCard(
              label: 'company',
              value: profile.companyName,
              onTap: () => context.read<ProfileBloc>().add(EditTeam()),
            ),

            const SizedBox(height: 30),

            const ProfileSectionHeader(title: 'NOTIFICATIONS'),
            const SizedBox(height: 12),

            ProfileToggleCard(
              label: 'Push Notifications',
              value: profile.pushNotifications,
              onChanged: (val) =>
                  context.read<ProfileBloc>().add(TogglePushNotification(val)),
            ),

            const SizedBox(height: 12),

            ProfileToggleCard(
              label: 'Email Notifications',
              value: profile.emailNotifications,
              onChanged: (val) =>
                  context.read<ProfileBloc>().add(ToggleEmailNotification(val)),
            ),
            const SizedBox(height: 40),

            Center(
              child: TextButton(
                onPressed: () => showLogoutDialog(context),
                child: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
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
