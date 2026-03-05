import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/time_slot_chip.dart';
import 'package:test_wpa/features/widgets/app_button.dart';

class TableSlotHeader extends StatelessWidget {
  final TableViewResponse response;
  final Map<String, TimeSlotType> slotTypeMap;
  final ValueChanged<String>? onTimeSlotChanged;
  final List<Schedule> schedules;

  const TableSlotHeader({
    super.key,
    required this.response,
    required this.slotTypeMap,
    this.onTimeSlotChanged,
    this.schedules = const [],
  });

  @override
  Widget build(BuildContext context) {
    final currentTime = response.time;
    final timesToday = response.timesToday;
    final date = response.date;
    final currentIndex = timesToday.indexOf(currentTime);
    final nextTime = (currentIndex >= 0 && currentIndex + 1 < timesToday.length)
        ? timesToday[currentIndex + 1]
        : null;

    final timeDisplay = nextTime != null
        ? DateTimeHelper.formatTimeRange12(
            DateTimeHelper.parseFlexibleDateTime(currentTime, date),
            DateTimeHelper.parseFlexibleDateTime(nextTime, date),
          )
        : DateTimeHelper.formatTime12(
            DateTimeHelper.parseFlexibleDateTime(currentTime, date),
          );

    final dateText = DateTimeHelper.formatFullDate(
      DateTimeHelper.parseSafeDate(date),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          const SizedBox(width: space.xs),
          Expanded(
            child: Text(
              '$dateText  |  $timeDisplay',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Show "Slots time" button only when there are slots available
          if (_mergedTimes().isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    _showTimeSlotPopup(context, _mergedTimes(), currentTime),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 16, color: AppColors.border),
                      SizedBox(width: space.xs),
                      Text(
                        'Slots time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.border,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTimeSlotPopup(
    BuildContext context,
    List<String> times,
    String currentTime,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Colors.white,
            child: DraggableScrollableSheet(
              initialChildSize: 0.5,
              maxChildSize: 0.9,
              minChildSize: 0.3,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select Time Slot',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose a time to view table assignments',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildSlotChips(ctx, times, currentTime),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TimeSlotType _resolveSlotType(String time) {
    final variants = [
      time,
      time.replaceAll(' ', ''),
      time.replaceAll(' ', '').toLowerCase(),
      time.length < 8 ? '0$time' : time,
    ];
    for (final v in variants) {
      final found = slotTypeMap[v];
      if (found != null) return found;
    }
    return TimeSlotType.unknown;
  }

  List<Widget> _buildSlotChips(
    BuildContext ctx,
    List<String> times,
    String currentTime,
  ) {
    final date = response.date;
    // Normalize currentTime to HH:mm for comparison
    final currentHHmm = _toHHmm(currentTime);

    return List.generate(times.length, (index) {
      final time = times[index];
      // Next time for range display — use next item in the list
      final nextTime = index + 1 < times.length ? times[index + 1] : null;

      final parsedStart = DateTimeHelper.parseFlexibleDateTime(time, date);
      final label = nextTime != null
          ? DateTimeHelper.formatTimeRange12(
              parsedStart,
              DateTimeHelper.parseFlexibleDateTime(nextTime, date),
            )
          : DateTimeHelper.formatTime12(parsedStart);

      // Lookup slot type via normalized key
      final lookupKey = DateTimeHelper.formatApiTime12(
        parsedStart,
      ).replaceAll(' ', '').toLowerCase();
      final slotType = slotTypeMap[lookupKey] ?? TimeSlotType.unknown;

      // ✅ Normalize both sides to HH:mm before comparing
      final timeHHmm = _toHHmm(time);
      final isSelected = timeHHmm == currentHHmm;

      return TimeSlotChip(
        time: label,
        isSelected: isSelected,
        type: slotType,
        onTap: () {
          Navigator.of(ctx).pop();
          // ✅ Always send HH:mm to backend
          final formatted =
              '${parsedStart.toLocal().hour.toString().padLeft(2, '0')}:'
              '${parsedStart.toLocal().minute.toString().padLeft(2, '0')}';
          onTimeSlotChanged?.call(formatted);
        },
      );
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Normalize any time string (ISO / HH:mm / "9:20 AM") → "HH:mm" for comparison.
  String _toHHmm(String timeStr) {
    try {
      final parsed = DateTimeHelper.parseFlexibleDateTime(
        timeStr,
        response.date,
      );
      final local = parsed.toLocal();
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  /// Build slot list from my_schedule data (ALL types: meeting + event).
  /// ✅ If user hasn't tapped any slot, backend already returns current time
  ///    in response.time — no extra logic needed here.
  /// Falls back to timesToday from table API if no schedules provided.
  List<String> _mergedTimes() {
    if (schedules.isNotEmpty) {
      final seen = <String>{};
      return schedules
          .map((s) => s.startAt.toIso8601String())
          .where((t) => seen.add(t))
          .toList()
        ..sort();
    }
    return response.timesToday;
  }
}
