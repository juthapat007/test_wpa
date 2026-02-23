import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart';
import 'package:test_wpa/features/meeting/widgets/table_grid_widget.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/date_header.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/time_slot_chip.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';
import 'package:test_wpa/features/widgets/app_dialog.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/features/widgets/date_tab_bar.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_event_card.dart';

class MeetingWidget extends StatefulWidget {
  const MeetingWidget({super.key});

  @override
  State<MeetingWidget> createState() => _MeetingWidgetState();
}

class _MeetingWidgetState extends State<MeetingWidget> {
  // ─── State ───────────────────────────────────────────────────────────────
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  String _selectedDateStr = '';
  bool _showFullList = false;
  bool _shownNoTodayDialog = false;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    //นับ เวลาที่เริ่มและ +1
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _currentTime = DateTime.now()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _onDateSelected(String date) {
    setState(() {
      _selectedDateStr = date;
      _showFullList = true;
    });
    ReadContext(context).read<ScheduleBloc>().add(LoadSchedules(date: date));
    Modular.get<TableBloc>().add(LoadTableView(date: date));
  }

  void _onScheduleTap(Schedule schedule) {
    if (!_isSelectableSchedule(schedule)) return;
    Modular.get<TableBloc>().add(
      LoadTableView(
        date: DateTimeHelper.formatApiDate(schedule.startAt),
        time: DateTimeHelper.formatApiTime12(schedule.startAt),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool _isSelectableSchedule(Schedule s) =>
      s.type != 'event' &&
      s.type != 'nomeeting' &&
      s.leave == null &&
      s.tableNumber != null &&
      s.tableNumber!.isNotEmpty;

  String _normalizeTime(String t) => t.replaceAll(' ', '').toLowerCase();

  Map<String, TimeSlotType> _buildSlotTypeMap(List<Schedule> schedules) => {
    for (final s in schedules)
      _normalizeTime(DateTimeHelper.formatApiTime12(s.startAt)):
          _resolveSlotType(s),
  };

  TimeSlotType _resolveSlotType(Schedule s) {
    if (s.leave != null) return TimeSlotType.leave;
    switch (s.type) {
      case 'event':
        return TimeSlotType.breakTime;
      case 'nomeeting':
        return TimeSlotType.free;
      default:
        return TimeSlotType.meeting;
    }
  }

  List<ScheduleWithStatus> _getSchedulesWithStatus(List<Schedule> schedules) {
    final result = <ScheduleWithStatus>[];
    bool nextAssigned = false;

    for (final s in schedules) {
      late ScheduleStatus status;
      if (_currentTime.isBefore(s.startAt)) {
        status = !nextAssigned ? ScheduleStatus.next : ScheduleStatus.upcoming;
        if (!nextAssigned) nextAssigned = true;
      } else if (_currentTime.isAfter(s.endAt)) {
        status = ScheduleStatus.past;
      } else {
        status = ScheduleStatus.now;
      }
      result.add(ScheduleWithStatus(schedule: s, status: status));
    }
    return result;
  }

  ScheduleWithStatus? _findByStatus(
    List<ScheduleWithStatus> list,
    ScheduleStatus target,
  ) {
    try {
      return list.firstWhere((s) => s.status == target);
    } catch (_) {
      return null;
    }
  }

  // ─── Initial date / dialog ────────────────────────────────────────────────
  // วันเริ่มต้นซิงค์

  void _syncInitialDate(String responseDate) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedDateStr = responseDate);
      Modular.get<TableBloc>().add(LoadTableView(date: responseDate));
      _maybeShowNoTodayDialog(responseDate);
    });
  }

  void _maybeShowNoTodayDialog(String responseDate) {
    if (_shownNoTodayDialog) return;
    final today = DateTimeHelper.formatApiDate(DateTime.now());
    if (responseDate == today) return;

    _shownNoTodayDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AppDialog(
          icon: Icons.event_note_outlined,
          iconColor: color.AppColors.warning,
          title: 'No meetings today',
          description:
              'You have no meetings scheduled for today.\nShowing the nearest available date instead.',
          actions: [
            AppDialogAction(
              label: 'Got it',
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: null,
            ),
          ],
        ),
      );
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Meetings',
      currentIndex: 0,
      appBarStyle: AppBarStyle.elegant,
      backgroundColor: color.AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DateHeader(),
            _buildDateTabBar(),
            _buildTableGridSection(),
            _buildScheduleSection(), // ✅ หายไป ต้องเพิ่มกลับ
          ],
        ),
      ),
    );
  }

  // ─── Date Tab Bar ─────────────────────────────────────────────────────────

  Widget _buildDateTabBar() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      buildWhen: (_, curr) => curr is ScheduleLoaded || curr is ScheduleLoading,
      builder: (context, state) {
        if (state is ScheduleLoaded) {
          final response = state.scheduleResponse;
          if (_selectedDateStr.isEmpty && response.availableDates.isNotEmpty) {
            _syncInitialDate(response.date);
          }
          return DateTabBar(
            availableDates: response.availableDates,
            selectedDate: _selectedDateStr.isNotEmpty
                ? _selectedDateStr
                : response.date,
            onDateSelected: _onDateSelected,
          );
        }
        if (state is ScheduleLoading) {
          return DateTabBar(
            availableDates: const [],
            selectedDate: _selectedDateStr,
            onDateSelected: _onDateSelected,
          );
        }
        return const SizedBox(height: 16);
      },
    );
  }

  // ─── Table Grid ───────────────────────────────────────────────────────────

  Widget _buildTableGridSection() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, scheduleState) {
        if (scheduleState is ScheduleLoaded) {
          final statuses = _getSchedulesWithStatus(
            scheduleState.scheduleResponse.schedules,
          );
          final current =
              _findByStatus(statuses, ScheduleStatus.now)?.schedule ??
              _findByStatus(statuses, ScheduleStatus.next)?.schedule;

          if (current?.leave != null) return _buildLeaveBanner(current!);
          if (current != null &&
              (current.type == 'event' ||
                  current.tableNumber == null ||
                  current.tableNumber!.isEmpty)) {
            return const SizedBox.shrink();
          }
        }

        return BlocBuilder<TableBloc, TableState>(
          builder: (context, tableState) {
            if (tableState is TableLoading) return const _LoadingBox();

            if (tableState is TableLoaded) {
              // Sync date: backend is source of truth
              if (_selectedDateStr != tableState.response.date) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted)
                    setState(() => _selectedDateStr = tableState.response.date);
                });
              }

              final schedules = scheduleState is ScheduleLoaded
                  ? scheduleState.scheduleResponse.schedules
                  : <Schedule>[];

              final viewTime = _normalizeTime(tableState.response.time);
              final currentSchedule = schedules.cast<Schedule?>().firstWhere(
                (s) =>
                    _normalizeTime(
                      DateTimeHelper.formatApiTime12(s!.startAt),
                    ) ==
                    viewTime,
                orElse: () => null,
              );

              return TableGridWidget(
                response: tableState.response,
                slotTypeMap: scheduleState is ScheduleLoaded
                    ? _buildSlotTypeMap(schedules)
                    : {},
                currentSchedule: currentSchedule,
                schedules: schedules,
                onTimeSlotChanged: (time) =>
                    Modular.get<TableBloc>().add(ChangeTimeSlot(time)),
              );
            }

            if (tableState is TableError) {
              return _ErrorBox(message: tableState.message);
            }

            return _buildNoDataView();
          },
        );
      },
    );
  }

  // ─── Schedule Section ─────────────────────────────────────────────────────

  Widget _buildScheduleSection() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is ScheduleLoading) {
          return const SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ScheduleLoaded) {
          final schedules = state.scheduleResponse.schedules;
          if (schedules.isEmpty) return _buildNoDataView();

          final statuses = _getSchedulesWithStatus(schedules);

          final current = _findByStatus(statuses, ScheduleStatus.now);
          final next = _findByStatus(statuses, ScheduleStatus.next);
          final toShow = [if (current != null) current, if (next != null) next];
          if (toShow.isEmpty) return const SizedBox.shrink();

          return _buildCompactScheduleList(toShow, hasCurrent: current != null);
        }

        if (state is ScheduleError) return _buildScheduleError(state.message);

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildScheduleError(String message) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: color.AppColors.error),
            SizedBox(height: space.m),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.AppColors.error),
            ),
            SizedBox(height: space.m),
            ElevatedButton(
              onPressed: () => ReadContext(context).read<ScheduleBloc>().add(
                LoadSchedules(
                  date: _selectedDateStr.isNotEmpty ? _selectedDateStr : null,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 72,
              color: color.AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No schedule for this day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting another date',
              style: TextStyle(
                fontSize: 13,
                color: color.AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                final s = ReadContext(context).read<ScheduleBloc>().state;
                if (s is ScheduleLoaded &&
                    s.scheduleResponse.availableDates.isNotEmpty) {
                  _onDateSelected(s.scheduleResponse.availableDates.first);
                }
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Go to first available date'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveBanner(Schedule schedule) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_busy,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.leave ?? 'Leave',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Colors.white60,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateTimeHelper.formatTimeRange12(
                          schedule.startAt,
                          schedule.endAt,
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactScheduleList(
    List<ScheduleWithStatus> toShow, {
    required bool hasCurrent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ...toShow.map((s) => _buildScheduleCard(s)),
          if (!_showFullList)
            TextButton(
              onPressed: () => setState(() => _showFullList = true),
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleWithStatus s) {
    return GestureDetector(
      onTap: () => _onScheduleTap(s.schedule),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ScheduleEventCard(
          schedule: s.schedule,
          type: ScheduleCardHelper.resolveCardType(s.schedule),
        ),
      ),
    );
  }
}

// ─── Private helper widgets ───────────────────────────────────────────────────

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 300,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 300, child: Center(child: Text(message)));
}

class _NoTodayDialog extends StatelessWidget {
  const _NoTodayDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min),
      ),
    );
  }
}
