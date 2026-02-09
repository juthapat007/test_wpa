import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_avatar.dart';
import 'package:test_wpa/features/widgets/app_bottom_navigation_bar.dart';
import 'package:test_wpa/features/widgets/app_calendar_bottom_sheet.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Event',
      currentIndex: 4,
      actions: const [
        IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null),
      ],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate.toLocal().toString().split(' ')[0],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () {
                      showCalendarBottomSheet(
                        context: context,
                        selectedDate: selectedDate,
                        onDateSelected: (date) {
                          setState(() {
                            selectedDate = date;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
