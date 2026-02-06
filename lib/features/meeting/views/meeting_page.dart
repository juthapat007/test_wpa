import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_wpa/features/widgets/app_bottom_navigation_bar.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_modular/flutter_modular.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Meeting',
      currentIndex: 0,
      backgroundColor: const Color(0xFFF9FAFB),
      appBarStyle: AppBarStyle.elegant,
      actions: [
        IconButton(
          onPressed: () => Modular.to.pushNamed('/notification'),
          icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
        ),
      ],
      body: const Center(child: Text('Meeting Page')),
    );
  }
}
