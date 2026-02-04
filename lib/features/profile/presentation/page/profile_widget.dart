import 'package:flutter/material.dart';
import 'package:test_wpa/features/profile/views/profile_page.dart';

// ✅ RENAMED: from Profile to ProfileWidget
class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePage();
  }
}
