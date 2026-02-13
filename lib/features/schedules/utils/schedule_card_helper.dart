import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';

class ScheduleCardHelper {
  final Schedule schedule;

  ScheduleCardHelper(this.schedule);

  // ========== Type Checks ==========
  bool get isOnLeave => schedule.leave != null;
  bool get isEvent => schedule.type == 'event';
  bool get isNoMeeting => schedule.type == 'nomeeting';
  bool get isMeeting => schedule.type == 'meeting';

  // ========== Status ==========
  ScheduleCardStatus get status {
    if (isOnLeave) return ScheduleCardStatus.leave;
    if (isEvent) return ScheduleCardStatus.event;
    if (isNoMeeting) return ScheduleCardStatus.free;

    final now = DateTime.now();
    if (schedule.endAt.isBefore(now)) return ScheduleCardStatus.passed;
    if (schedule.startAt.isBefore(now)) return ScheduleCardStatus.ongoing;
    return ScheduleCardStatus.upcoming;
  }

  // ========== Colors ==========
  Color get statusColor {
    switch (status) {
      case ScheduleCardStatus.leave:
        return color.AppColors.error;
      case ScheduleCardStatus.event:
        return color.AppColors.warning;
      case ScheduleCardStatus.free:
        return color.AppColors.info;
      case ScheduleCardStatus.passed:
        return color.AppColors.success;
      case ScheduleCardStatus.ongoing:
        return color.AppColors.primary;
      case ScheduleCardStatus.upcoming:
        return color.AppColors.warning;
    }
  }

  Color get backgroundColor {
    if (isOnLeave) return Colors.red[50]!;
    if (isEvent) return Colors.amber[50]!;
    if (isNoMeeting) return Colors.grey[50]!;
    return Colors.white;
  }

  Border? get border {
    if (isOnLeave) {
      return Border.all(color: color.AppColors.error.withAlpha(100), width: 2);
    }
    if (isEvent) {
      return Border.all(
        color: color.AppColors.warning.withAlpha(100),
        width: 2,
      );
    }
    if (isNoMeeting) {
      return Border.all(
        color: color.AppColors.textSecondary.withAlpha(100),
        width: 2,
      );
    }
    return null;
  }

  // ========== Text Content ==========
  String get statusText {
    switch (status) {
      case ScheduleCardStatus.leave:
        return 'LEAVE';
      case ScheduleCardStatus.event:
        return 'BREAK';
      case ScheduleCardStatus.free:
        return 'FREE';
      case ScheduleCardStatus.passed:
        return 'PASSED';
      case ScheduleCardStatus.ongoing:
        return 'ONGOING';
      case ScheduleCardStatus.upcoming:
        return 'UPCOMING';
    }
  }

  String get primaryText {
    if (isEvent) return schedule.title ?? 'Event';
    if (isNoMeeting) {
      final delegates = schedule.teamDelegates;
      if (delegates == null || delegates.isEmpty) return 'Free time';
      return delegates.map((d) => d.name).join(', ');
    }
    if (isMeeting) {
      final delegates = schedule.teamDelegates;
      if (delegates == null || delegates.isEmpty) return 'Unknown';
      return delegates.first.company;
    }
    return 'N/A';
  }

  String? get secondaryText {
    if (!isMeeting) return null;
    final delegates = schedule.teamDelegates;
    if (delegates == null || delegates.isEmpty) return null;
    return delegates.map((d) => d.name).join(', ');
  }

  // ========== Icons ==========
  IconData? get leadingIcon {
    if (isEvent) return Icons.coffee_outlined;
    if (isNoMeeting) return Icons.free_breakfast;
    return null;
  }

  Color? get leadingIconColor {
    if (isEvent) return color.AppColors.warning;
    if (isNoMeeting) return color.AppColors.info;
    return null;
  }
}
