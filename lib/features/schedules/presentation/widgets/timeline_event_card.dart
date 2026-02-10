import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class TimelineEventCard extends StatelessWidget {
  final Schedule? schedule;
  final EventCardType type;

  const TimelineEventCard({super.key, this.schedule, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case EventCardType.meeting:
        return _MeetingCard(schedule: schedule!);
      case EventCardType.empty:
        return const _EmptySlotCard();
      case EventCardType.breakTime:
        return const _BreakTimeCard();
    }
  }
}

class _MeetingCard extends StatelessWidget {
  final Schedule schedule;

  const _MeetingCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final helper = ScheduleCardHelper(schedule);
    final startTime = DateFormat('h:mm:a').format(schedule.startAt.toUtc());
    final endTime = DateFormat('h:mm:a').format(schedule.endAt.toUtc());

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
        style: TextStyle(
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

// Empty & Break cards ไม่ต้องแก้
class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: Colors.grey[200]!),
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

class _BreakTimeCard extends StatelessWidget {
  const _BreakTimeCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: Colors.amber[200]!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.amber[50]?.withOpacity(0.3)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Break',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 20,
                fontStyle: FontStyle.italic,
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

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

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

    for (var metric in path.computeMetrics()) {
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
