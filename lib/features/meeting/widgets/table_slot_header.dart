import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/time_slot_chip.dart';

class TableSlotHeader extends StatelessWidget {
  final TableViewResponse response;
  final Map<String, TimeSlotType> slotTypeMap;
  final ValueChanged<String>? onTimeSlotChanged;

  const TableSlotHeader({
    super.key,
    required this.response,
    required this.slotTypeMap,
    this.onTimeSlotChanged,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dateText  |  $timeDisplay',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (timesToday.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    _showTimeSlotPopup(context, timesToday, currentTime),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Slots',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
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
    List<String> timesToday,
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
                        children: _buildSlotChips(ctx, timesToday, currentTime),
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

  List<Widget> _buildSlotChips(
    BuildContext ctx,
    List<String> timesToday,
    String currentTime,
  ) {
    final date = response.date;
    final filteredTimes = timesToday.where((t) {
      final type = slotTypeMap[t] ?? TimeSlotType.unknown;
      // กรอง free (nomeeting) ออก — ถ้า enum มี nomeeting ให้เพิ่ม: && type != TimeSlotType.nomeeting
      return type != TimeSlotType.free;
    }).toList();

    return List.generate(filteredTimes.length, (index) {
      final time = filteredTimes[index];
      final originalIndex = timesToday.indexOf(time);
      final nextTime = originalIndex + 1 < timesToday.length
          ? timesToday[originalIndex + 1]
          : null;
      final label = nextTime != null
          ? DateTimeHelper.formatTimeRange12(
              DateTimeHelper.parseFlexibleDateTime(time, date),
              DateTimeHelper.parseFlexibleDateTime(nextTime, date),
            )
          : DateTimeHelper.formatTime12(
              DateTimeHelper.parseFlexibleDateTime(time, date),
            );
      return TimeSlotChip(
        time: label,
        isSelected: time == currentTime,
        type: slotTypeMap[time] ?? TimeSlotType.unknown,
        onTap: () {
          Navigator.of(ctx).pop();
          onTimeSlotChanged?.call(time);
        },
      );
    });
  }
}
