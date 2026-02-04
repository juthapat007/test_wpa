import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_avatar.dart';
import 'package:test_wpa/features/widget/app_bottom_navigation_bar.dart';
import 'package:test_wpa/features/widget/app_scaffold.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Event',
      currentIndex: 4,
      actions: [
        IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null),
      ],
    );
  }
}
