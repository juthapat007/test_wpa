// Common widget ที่ใช้ร่วมกันได้ทุก module (schedule, meeting, other_profile)

import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';

/// Card แสดงข้อมูล schedule ทั้ง 3 type:
///   - [EventCardType.meeting]   → white card with status badge
///   - [EventCardType.breakTime] → amber card with status badge
///   - [EventCardType.empty]     → blue card ("No Meeting")
class ScheduleEventCard extends StatelessWidget {
  final Schedule? schedule;
  final EventCardType type;

  const ScheduleEventCard({super.key, this.schedule, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case EventCardType.meeting:
        assert(schedule != null, 'schedule must not be null for meeting card');
        return MeetingCard(schedule: schedule!);
      case EventCardType.breakTime:
        assert(schedule != null);
        return MeetingCard(schedule: schedule!);
      case EventCardType.empty:
        return EmptySlotCard(schedule: schedule);
    }
  }
}

// ─────────────────────────────────────────────
// Meeting Card  (meeting / event / leave)
// ─────────────────────────────────────────────
class MeetingCard extends StatelessWidget {
  final Schedule schedule;

  const MeetingCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final helper = ScheduleCardHelper(schedule);
    final startTime = DateTimeHelper.formatTime12(schedule.startAt);
    final endTime = DateTimeHelper.formatTime12(schedule.endAt);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: helper.backgroundColor,
        border: Border.all(color: Colors.grey[200]!, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // เวลา — ซ้าย
              Text(
                '$startTime - $endTime',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 100),

              ///มันทำให้โหลดข้อมูลช้าไม่ต้องเอามาก็ได้
              if (schedule.tableNumber != null) ...[
                const Spacer(), // ✅ ดัน table ให้อยู่กลาง
                Text(
                  '${schedule.tableNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: helper.statusColor,
                  ),
                ),
              ],
              const Spacer(), // ✅ ดัน badge ไปขวาสุด
              _buildBadge(helper),
            ],
          ),
          SizedBox(height: 10),
          //บอกรายละเอียดแผน
          // Row 2: company • country
          Text(
            _buildSubtitleText(helper),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: helper.statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitleText(ScheduleCardHelper helper) {
    if (helper.isEvent) return schedule.title ?? 'Break';
    if (helper.isNoMeeting) return 'Free Time';
    final delegates = schedule.teamDelegates;
    if (delegates == null || delegates.isEmpty) return 'Unknown';
    final company = delegates.first.company;
    final country = schedule.country.isNotEmpty ? ' • ${schedule.country}' : '';
    return '$company$country';
  }

  Widget _buildBadge(ScheduleCardHelper helper) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: helper.statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        helper.statusText.toLowerCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: helper.statusColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty Slot Card  (nomeeting)
// ─────────────────────────────────────────────
class EmptySlotCard extends StatelessWidget {
  final Schedule? schedule;

  const EmptySlotCard({super.key, this.schedule});

  @override
  Widget build(BuildContext context) {
    final startTime = schedule != null
        ? DateTimeHelper.formatTime12(schedule!.startAt)
        : null;
    final endTime = schedule != null
        ? DateTimeHelper.formatTime12(schedule!.endAt)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.2),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: เวลา | badge
          Row(
            children: [
              Text(
                startTime != null ? '$startTime - $endTime' : 'No Meeting',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'free',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 4),
          // Row 2: label
          Text(
            'No Meeting',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
