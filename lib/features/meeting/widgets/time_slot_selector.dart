// lib/features/meeting/widgets/time_slot_selector.dart

import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_event_card.dart';

class TimeSlotSelector extends StatelessWidget {
  final List<Schedule> schedules;
  final String? selectedTime;
  final Function(Schedule) onSlotTap;
  final Schedule? currentSchedule;
  final Schedule? nextSchedule;

  const TimeSlotSelector({
    super.key,
    required this.schedules,
    this.selectedTime,
    required this.onSlotTap,
    this.currentSchedule,
    this.nextSchedule,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME SLOTS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color.AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              _buildLegend(),
            ],
          ),
        ),

        // Time Slots Grid
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.6,
            ),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _buildTimeSlot(schedule);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlot(Schedule schedule) {
    final now = DateTime.now();
    final isCurrent = currentSchedule?.id == schedule.id;
    final isNext = nextSchedule?.id == schedule.id;
    final isPast = schedule.endAt.isBefore(now);
    final isUpcoming = schedule.startAt.isAfter(now) && !isNext;

    final isOnLeave = schedule.leave != null;
    final isEvent = schedule.type == 'event';
    final isNoMeeting = schedule.type == 'nomeeting';
    final isMeeting = schedule.type == 'meeting';

    // Determine colors and status
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String statusLabel;
    IconData? icon;

    if (isOnLeave) {
      backgroundColor = Colors.red[50]!;
      borderColor = color.AppColors.error;
      textColor = color.AppColors.error;
      statusLabel = 'LEAVE';
      icon = Icons.event_busy;
    } else if (isEvent) {
      backgroundColor = Colors.amber[50]!;
      borderColor = color.AppColors.warning;
      textColor = color.AppColors.warning;
      statusLabel = 'BREAK';
      icon = Icons.coffee;
    } else if (isNoMeeting) {
      backgroundColor = Colors.grey[50]!;
      borderColor = color.AppColors.info;
      textColor = color.AppColors.info;
      statusLabel = 'FREE';
      icon = Icons.free_breakfast;
    } else if (isPast) {
      backgroundColor = Colors.green[50]!;
      borderColor = color.AppColors.success.withOpacity(0.3);
      textColor = color.AppColors.success;
      statusLabel = 'DONE';
      icon = Icons.check_circle_outline;
    } else if (isCurrent) {
      backgroundColor = Colors.blue[50]!;
      borderColor = color.AppColors.primary;
      textColor = color.AppColors.primary;
      statusLabel = 'NOW';
      icon = Icons.play_circle_outline;
    } else if (isNext) {
      backgroundColor = Colors.orange[50]!;
      borderColor = color.AppColors.warning;
      textColor = color.AppColors.warning;
      statusLabel = 'NEXT';
      icon = Icons.schedule;
    } else {
      backgroundColor = Colors.white;
      borderColor = color.AppColors.border;
      textColor = color.AppColors.textPrimary;
      statusLabel = 'UPCOMING';
      icon = Icons.event;
    }

    final startTime = DateTimeHelper.formatTime12(schedule.startAt);
    final endTime = DateTimeHelper.formatTime12(schedule.endAt);

    // Can tap if it's a meeting with table
    final canTap =
        isMeeting &&
        schedule.tableNumber != null &&
        schedule.tableNumber!.isNotEmpty;

    return GestureDetector(
      onTap: canTap ? () => onSlotTap(schedule) : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isCurrent || isNext ? 2.5 : 1.5,
          ),
          boxShadow: isCurrent || isNext
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 10, color: textColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$startTime - $endTime',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  // Text(
                  //   startTime,
                  //   style: TextStyle(
                  //     fontSize: 13,
                  //     fontWeight: FontWeight.bold,
                  //     color: textColor,
                  //   ),
                  // ),
                  // Text(
                  //   endTime,
                  //   style: TextStyle(
                  //     fontSize: 11,
                  //     color: textColor.withOpacity(0.7),
                  //   ),
                  // ),
                ],
              ),

              // Meeting info
              if (isMeeting) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (schedule.tableNumber != null)
                      Text(
                        'Table ${schedule.tableNumber}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    if (schedule.teamDelegates?.isNotEmpty ?? false)
                      Text(
                        schedule.teamDelegates!.first.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ] else if (isEvent) ...[
                Text(
                  schedule.title ?? 'Break',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(color.AppColors.primary, 'Now'),
        const SizedBox(width: 12),
        _buildLegendItem(color.AppColors.warning, 'Next'),
        const SizedBox(width: 12),
        _buildLegendItem(color.AppColors.success, 'Done'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
            SizedBox(height: space.s),
            Text(
              'No meetings scheduled',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
