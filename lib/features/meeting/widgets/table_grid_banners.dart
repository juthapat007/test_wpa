import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.7))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_seat, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY SEAT',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: width.s,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Table ${response.myTable}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: width.xxl,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoAssignmentBanner extends StatelessWidget {
  const NoAssignmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(
            'No table assigned for this time slot',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.warning.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Table Assigned',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "You don't have a table assignment for this time slot.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (nextTimeRange != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Try next slot',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onTimeSlotChanged?.call(nextSlot!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nextTimeRange,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  'Try selecting another time slot',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
