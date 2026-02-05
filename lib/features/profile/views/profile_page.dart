import 'package:flutter/material.dart';
import 'package:test_wpa/features/profile/widgets/profile_info_card.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Personal Information',
      currentIndex: -1, // ไม่มีใน bottom nav
      showAvatar: false,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            final p = state.profile;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: p.avatarUrl.isNotEmpty
                        ? NetworkImage(p.avatarUrl)
                        : const AssetImage('assets/images/empty_state.png')
                              as ImageProvider,
                  ),
                  SizedBox(height: space.m),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: space.l),
                  Text(
                    'PERSONAL INFORMATION',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  ProfileInfoCard(
                    label: 'Full Name',
                    child: Row(
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          onPressed: () {
                            // open edit dialog
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: space.xs),
                  ProfileInfoCard(
                    label: 'Company',
                    child: Row(
                      children: [
                        Text(
                          p.companyName,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          onPressed: () {
                            // open edit dialog
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: space.xs),
                  ProfileInfoCard(
                    label: 'Team',
                    child: Row(
                      children: [
                        Text(p.teamName, style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          onPressed: () {
                            // open edit dialog
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: space.l),
                  Text(
                    'SECURITY',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: space.xs),
                  ProfileInfoCard(
                    label: 'Company',
                    child: Row(
                      children: [
                        Text(
                          p.companyName,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          onPressed: () {
                            // open edit dialog
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: space.l),
                  Text(
                    'NOTIFICATIONS',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  ProfileInfoCard(
                    label: 'Company',
                    child: Row(
                      children: [
                        Text(
                          p.companyName,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          onPressed: () {
                            // open edit dialog
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: space.l),
                  AppButton(text: 'Logout', onPressed: () {}),
                ],
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
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
