import 'package:flutter/material.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_state.dart';
import 'package:test_wpa/features/profile/views/profile_view.dart';
import 'package:test_wpa/features/widgets/app_bar_back.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarBack(title: 'Personal Information'),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ProfileView(state: state);
        },
      ),
    );
  }
}
