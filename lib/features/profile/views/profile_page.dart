import 'package:flutter/material.dart';
import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/features/profile/domain/repository/profile_repository.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/widget/app_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class ProfilePage extends StatelessWidget {
  final String token;

  const ProfilePage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(
        ProfileRepository(
          DioClient(token).dio,
        ),
      )..add(LoadProfile()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileLoaded) {
              final p = state.profile;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(p.avatarUrl),
                    ),
                    const SizedBox(height: 16),
                    Text(p.name, style: const TextStyle(fontSize: 20)),
                    Text(p.title),
                    Text(p.email),
                    const SizedBox(height: 12),
                    Text('Company: ${p.company.name}'),
                    Text('Team: ${p.team.name}'),
                  ],
                ),
              );
            }

            if (state is ProfileError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
