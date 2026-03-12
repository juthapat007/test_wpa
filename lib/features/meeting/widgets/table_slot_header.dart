import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/time_slot_chip.dart';

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
          if (_mergedTimes().isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showTimeSlotPopup(context),
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

  void _showTimeSlotPopup(BuildContext context) {
    final times = _mergedTimes();
    final scrollTargetHHmm = _nearestSlotHHmmToNow(times);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimeSlotSheet(
        times: times,
        selectedHHmm: _toHHmm(response.time),
        scrollTargetHHmm: scrollTargetHHmm,
        response: response,
        slotTypeMap: slotTypeMap,
        onTimeSlotChanged: onTimeSlotChanged,
        toHHmm: _toHHmm,
      ),
    );
  }

  String _toHHmm(String timeStr) {
    try {
      final parsed = DateTimeHelper.parseFlexibleDateTime(
        timeStr,
        response.date,
      );
      final local = parsed.toLocal();
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  String _nearestSlotHHmmToNow(List<String> times) {
    if (times.isEmpty) return _toHHmm(response.time);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    String? bestTime;
    int bestDiff = 99999;
    for (final t in times) {
      try {
        final parsed = DateTimeHelper.parseFlexibleDateTime(
          t,
          response.date,
        ).toLocal();
        final slotMinutes = parsed.hour * 60 + parsed.minute;
        final diff = (slotMinutes - nowMinutes).abs();
        if (slotMinutes <= nowMinutes && diff < bestDiff) {
          bestDiff = diff;
          bestTime = t;
        }
      } catch (_) {}
    }
    return _toHHmm(bestTime ?? times.first);
  }

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

// ─── Sheet Widget ─────────────────────────────────────────────────────────────

class _TimeSlotSheet extends StatefulWidget {
  final List<String> times;
  final String selectedHHmm;
  final String scrollTargetHHmm;
  final TableViewResponse response;
  final Map<String, TimeSlotType> slotTypeMap;
  final ValueChanged<String>? onTimeSlotChanged;
  final String Function(String) toHHmm;

  const _TimeSlotSheet({
    required this.times,
    required this.selectedHHmm,
    required this.scrollTargetHHmm,
    required this.response,
    required this.slotTypeMap,
    required this.onTimeSlotChanged,
    required this.toHHmm,
  });

  @override
  State<_TimeSlotSheet> createState() => _TimeSlotSheetState();
}

class _TimeSlotSheetState extends State<_TimeSlotSheet> {
  late final ScrollController _scrollController;
  static const double _itemHeight = 78.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTarget() {
    if (!_scrollController.hasClients) return;
    final targetIndex = widget.times.indexWhere(
      (t) => widget.toHHmm(t) == widget.scrollTargetHHmm,
    );
    if (targetIndex < 0) return;
    final targetOffset =
        (targetIndex * _itemHeight) -
        (_scrollController.position.viewportDimension / 2) +
        (_itemHeight / 2);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.response.date;

    // เวลาปัจจุบันของ device สำหรับแสดงใน header
    final now = DateTime.now();
    final h = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
        ? 12
        : now.hour;
    final nowLabel =
        '$h:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
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
            builder: (_, __) => Column(
              children: [
                // ─── Header ──────────────────────────────────────────────
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

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Time Slot',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  nowLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

                // ─── Slot list ────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: widget.times.length,
                    itemExtent: _itemHeight,
                    itemBuilder: (ctx, index) {
                      final time = widget.times[index];
                      final nextTime = index + 1 < widget.times.length
                          ? widget.times[index + 1]
                          : null;

                      final parsedStart = DateTimeHelper.parseFlexibleDateTime(
                        time,
                        date,
                      );
                      final label = nextTime != null
                          ? DateTimeHelper.formatTimeRange12(
                              parsedStart,
                              DateTimeHelper.parseFlexibleDateTime(
                                nextTime,
                                date,
                              ),
                            )
                          : DateTimeHelper.formatTime12(parsedStart);

                      final lookupKey = DateTimeHelper.formatApiTime12(
                        parsedStart,
                      ).replaceAll(' ', '').toLowerCase();
                      final slotType =
                          widget.slotTypeMap[lookupKey] ?? TimeSlotType.unknown;

                      final isSelected =
                          widget.toHHmm(time) == widget.selectedHHmm;
                      final isNow =
                          widget.toHHmm(time) == widget.scrollTargetHHmm;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          // highlight chip ที่ตรงกับเวลาปัจจุบัน
                          decoration: isNow
                              ? BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border(
                                    left: BorderSide(
                                      color: AppColors.primary,
                                      width: 3,
                                    ),
                                  ),
                                )
                              : null,
                          child: Row(
                            children: [
                              if (isNow) const SizedBox(width: 8),
                              Expanded(
                                child: TimeSlotChip(
                                  time: label,
                                  isSelected: isSelected,
                                  type: slotType,
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    final formatted =
                                        '${parsedStart.toLocal().hour.toString().padLeft(2, '0')}:'
                                        '${parsedStart.toLocal().minute.toString().padLeft(2, '0')}';
                                    widget.onTimeSlotChanged?.call(formatted);
                                  },
                                ),
                              ),
                              if (isNow)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 4,
                                  ),
                                  child: Text(
                                    'NOW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
