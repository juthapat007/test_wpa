//     แต่ภายในตอนนี้ delegate ทุก render ไปให้ ScheduleEventCard (common widget) ทั้งหมด
//     ไม่มี duplicated logic

import 'package:flutter/material.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_event_card.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

/// Thin wrapper ที่ re-export ScheduleEventCard
/// ใช้ใน timeline_row.dart และที่อื่นที่ import ชื่อเดิมไว้
class TimelineEventCard extends StatelessWidget {
  final Schedule? schedule;
  final EventCardType type;

  const TimelineEventCard({super.key, this.schedule, required this.type});

  @override
  Widget build(BuildContext context) {
    return ScheduleEventCard(schedule: schedule, type: type);
  }
}
