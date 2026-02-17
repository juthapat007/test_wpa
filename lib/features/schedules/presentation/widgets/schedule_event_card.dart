// Common widget ที่ใช้ร่วมกันได้ทุก module (schedule, meeting, other_profile)

import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';

/// Card แสดงข้อมูล schedule ทั้ง 3 type:
///   - [EventCardType.meeting]   → white card with status badge
///   - [EventCardType.breakTime] → amber dashed card ("Break")
///   - [EventCardType.empty]     → grey dashed card ("No Meeting")
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
        return const EmptySlotCard();
    }
  }
}

// ─────────────────────────────────────────────
// Meeting Card
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: helper.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: helper.border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(helper, startTime, endTime),
          const SizedBox(height: 8),
          _buildContent(helper),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ScheduleCardHelper helper,
    String startTime,
    String endTime,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$startTime - $endTime',
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              _buildSubtitle(helper),
            ],
          ),
        ),
        _buildStatusBadge(helper),
      ],
    );
  }

  Widget _buildSubtitle(ScheduleCardHelper helper) {
    if (helper.isMeeting && schedule.tableNumber != null) {
      return Text(
        'Table ${schedule.tableNumber}',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (helper.leadingIcon != null) {
      return Row(
        children: [
          Icon(helper.leadingIcon, size: 14, color: helper.leadingIconColor),
          const SizedBox(width: 4),
          Text(
            helper.isEvent ? 'Break Time' : 'Free Time',
            style: TextStyle(
              fontSize: 11,
              color: helper.leadingIconColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusBadge(ScheduleCardHelper helper) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: helper.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        helper.statusText,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: helper.statusColor,
        ),
      ),
    );
  }

  Widget _buildContent(ScheduleCardHelper helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          helper.primaryText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: helper.statusColor,
          ),
        ),
        if (helper.secondaryText != null) ...[
          const SizedBox(height: 4),
          Text(
            helper.secondaryText!,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
        if (schedule.country.isNotEmpty && helper.isMeeting) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.flag, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                schedule.country,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Break Time Card  (amber dashed)
// ─────────────────────────────────────────────
class BreakTimeCard extends StatelessWidget {
  /// ชื่อ event จาก schedule.title (optional — fallback เป็น 'Break')
  final String? title;

  const BreakTimeCard({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedRectPainter(color: Colors.amber[200]!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.amber[50]?.withOpacity(0.3)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title ?? 'Break',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.amber[700],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.amber[100]?.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.coffee_outlined,
                color: Colors.amber[700],
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty Slot Card  (grey dashed)
// ─────────────────────────────────────────────
class EmptySlotCard extends StatelessWidget {
  const EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedRectPainter(color: Colors.grey[200]!),
      child: Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          'No Meeting',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 18,
            color: Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashed border painter (shared)
// ─────────────────────────────────────────────
class DashedRectPainter extends CustomPainter {
  final Color color;

  const DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
