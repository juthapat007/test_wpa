import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_event_card.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class TimelineRow extends StatelessWidget {
  final Schedule? schedule;
  final EventCardType cardType;
  final bool isSelectionMode;
  final bool isSelected;

  const TimelineRow({
    super.key,
    this.schedule,
    required this.cardType,
    this.isSelectionMode = false,
    this.isSelected = false,
  });
  String _formatTime(DateTime dateTime) {
    return DateTimeHelper.formatTime12(dateTime);
  }

  //เอามาบอกว่าเช้า บ่าย เย็น อะไรแบบนี้ — เอาไว้แสดงใต้เวลาตรงข้างบนอีกที
  String _formatPeriod(DateTime dateTime) {
    return DateFormat('a').format(dateTime).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final timeToDisplay = schedule?.startAt ?? DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          width: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatTime(timeToDisplay),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: space.m),
        // Event card
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ScheduleEventCard(schedule: schedule, type: cardType),
              // Checkbox overlay
              if (isSelectionMode)
                Positioned(
                  top: 12,
                  left: -29,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.AppColors.primary
                          : color.AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? color.AppColors.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
