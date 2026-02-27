import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

// ─── My Table Banner ─────────────────────────────────────────────────────────

class MyTableBanner extends StatelessWidget {
  final TableViewResponse response;

  const MyTableBanner({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final currentTime = response.time;
    final timesToday = response.timesToday;
    final currentIndex = timesToday.indexOf(currentTime);
    final nextTime = (currentIndex >= 0 && currentIndex + 1 < timesToday.length)
        ? timesToday[currentIndex + 1]
        : null;
    final timeRange = nextTime != null
        ? DateTimeHelper.formatTimeRange12(
            DateTimeHelper.parseFlexibleDateTime(currentTime, response.date),
            DateTimeHelper.parseFlexibleDateTime(nextTime, response.date),
          )
        : DateTimeHelper.formatTime12(
            DateTimeHelper.parseFlexibleDateTime(currentTime, response.date),
          );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─── Icon box ────────────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_seat,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // ─── Text ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY SEAT',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Table ${response.myTable}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // ─── Time pill ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Text(
              timeRange,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No Assignment Banner ─────────────────────────────────────────────────────

class NoAssignmentBanner extends StatelessWidget {
  const NoAssignmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline, size: 15, color: AppColors.warning),
          ),
          const SizedBox(width: 10),
          Text(
            'No table assigned for this time slot',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.warning.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No Table Card ────────────────────────────────────────────────────────────

class NoTableCard extends StatelessWidget {
  final TableViewResponse response;
  final ValueChanged<String>? onTimeSlotChanged;

  const NoTableCard({
    super.key,
    required this.response,
    this.onTimeSlotChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timesToday = response.timesToday;
    final currentTime = response.time;
    final date = response.date;
    final currentIndex = timesToday.indexOf(currentTime);
    final nextSlot = (currentIndex >= 0 && currentIndex + 1 < timesToday.length)
        ? timesToday[currentIndex + 1]
        : null;
    final nextNextSlot =
        (currentIndex >= 0 && currentIndex + 2 < timesToday.length)
        ? timesToday[currentIndex + 2]
        : null;
    final nextTimeRange = (nextSlot != null && nextNextSlot != null)
        ? DateTimeHelper.formatTimeRange12(
            DateTimeHelper.parseFlexibleDateTime(nextSlot, date),
            DateTimeHelper.parseFlexibleDateTime(nextNextSlot, date),
          )
        : nextSlot != null
        ? DateTimeHelper.formatTime12(
            DateTimeHelper.parseFlexibleDateTime(nextSlot, date),
          )
        : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              size: 32,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Table Assigned',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "You don't have a table assignment\nfor this time slot.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (nextTimeRange != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => onTimeSlotChanged?.call(nextSlot!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next slot: $nextTimeRange',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Try selecting another time slot',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
