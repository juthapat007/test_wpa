import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;

enum TimeSlotType { meeting, breakTime, free, leave, unknown }

class TimeSlotHelper {
  /// แยก type จาก label เช่น "10:00 AM - Break", "10:00 AM - Meeting"
  /// หรือถ้า backend ส่ง type มาด้วยก็ใช้ตรงๆ
  static TimeSlotType resolveType(
    String timeLabel, {
    String? scheduleType,
    bool isOnLeave = false, // ← เพิ่ม
  }) {
    if (isOnLeave) return TimeSlotType.leave;
    if (scheduleType != null) {
      switch (scheduleType) {
        case 'event':
          return TimeSlotType.breakTime;
        case 'nomeeting':
          return TimeSlotType.free;
        case 'meeting':
          return TimeSlotType.meeting;
      }
    }
    // fallback: ดูจาก label
    final lower = timeLabel.toLowerCase();
    if (lower.contains('break')) return TimeSlotType.breakTime;
    if (lower.contains('free') || lower.contains('no'))
      return TimeSlotType.free;
    return TimeSlotType.meeting;
  }

  static Color chipColor(TimeSlotType type, bool isSelected) {
    if (isSelected) {
      switch (type) {
        case TimeSlotType.leave:
          return Colors.red[700]!;
        case TimeSlotType.breakTime:
          return Colors.amber[700]!;
        case TimeSlotType.free:
          return color.AppColors.info;
        case TimeSlotType.meeting:
        case TimeSlotType.unknown:
          return color.AppColors.primary;
      }
    }
    switch (type) {
      case TimeSlotType.leave:
        return Colors.red[50]!;
      case TimeSlotType.breakTime:
        return Colors.amber[50]!;
      case TimeSlotType.free:
        return Colors.blue[50]!;
      case TimeSlotType.meeting:
      case TimeSlotType.unknown:
        return Colors.grey[100]!;
    }
  }

  static Color chipBorderColor(TimeSlotType type, bool isSelected) {
    switch (type) {
      case TimeSlotType.leave:
        return isSelected ? Colors.red[700]! : Colors.red[300]!;

      case TimeSlotType.breakTime:
        return isSelected ? Colors.amber[700]! : Colors.amber[300]!;
      case TimeSlotType.free:
        return isSelected ? color.AppColors.info : Colors.blue[200]!;
      case TimeSlotType.meeting:
      case TimeSlotType.unknown:
        return isSelected ? color.AppColors.primary : color.AppColors.border;
    }
  }

  static Color chipTextColor(TimeSlotType type, bool isSelected) {
    if (isSelected) return Colors.white;
    switch (type) {
      case TimeSlotType.leave:
        return Colors.red[800]!;
      case TimeSlotType.breakTime:
        return Colors.amber[800]!;
      case TimeSlotType.free:
        return color.AppColors.info;
      case TimeSlotType.meeting:
      case TimeSlotType.unknown:
        return color.AppColors.textPrimary;
    }
  }

  static IconData? chipIcon(TimeSlotType type) {
    switch (type) {
      case TimeSlotType.leave:
        return Icons.event_busy;
      case TimeSlotType.breakTime:
        return Icons.coffee_outlined;
      case TimeSlotType.free:
        return Icons.free_breakfast_outlined;
      case TimeSlotType.meeting:
      case TimeSlotType.unknown:
        return Icons.people_outline;
    }
  }

  static String chipLabel(TimeSlotType type) {
    switch (type) {
      case TimeSlotType.leave:
        return 'Leave';
      case TimeSlotType.breakTime:
        return 'Break';
      case TimeSlotType.free:
        return 'Free';
      case TimeSlotType.meeting:
      case TimeSlotType.unknown:
        return 'Meeting';
    }
  }
}

class TimeSlotChip extends StatelessWidget {
  final String time;
  final bool isSelected;
  final TimeSlotType type;
  final VoidCallback onTap;

  const TimeSlotChip({
    super.key,
    required this.time,
    required this.isSelected,
    required this.type,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final bgColor = TimeSlotHelper.chipColor(type, isSelected);
    final borderColor = TimeSlotHelper.chipBorderColor(type, isSelected);
    final textColor = TimeSlotHelper.chipTextColor(type, isSelected);
    final icon = TimeSlotHelper.chipIcon(type);
    final label = TimeSlotHelper.chipLabel(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 12,
                      color: isSelected ? Colors.white70 : textColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  // label เล็กๆ บอก type
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white70
                          : textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
