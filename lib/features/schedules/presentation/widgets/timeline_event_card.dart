import 'package:flutter/material.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_event_card.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class TimelineEventCard extends StatelessWidget {
  final Schedule? schedule;
  final EventCardType type;

  const TimelineEventCard({super.key, this.schedule, required this.type});

  @override
  Widget build(BuildContext context) {
    return ScheduleEventCard(schedule: schedule, type: type);
  }
}
