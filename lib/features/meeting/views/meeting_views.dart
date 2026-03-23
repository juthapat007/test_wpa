import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart';
import 'package:test_wpa/features/meeting/widgets/table_grid_widget.dart';
import 'package:test_wpa/features/notification/presentation/bloc/friends_cubit.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/time_slot_chip.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';
import 'package:test_wpa/features/widgets/add_button_outline.dart';
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
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  bool _showFullList = false;
  bool _shownNoTodayDialog = false;
  String _selectedDateStr = '';
  bool _userSelectedTime = false;
  List<String> _tableDays = [];
  String? _delegateId;
  bool _tableInitialized = false;

  // ─── Helpers ────────────────────────────────────────────────────────────

  String _nowHHmm() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ✅ อยู่ใน class level — เรียกได้จากทุกที่
  String _nearestSlotTime(List<String> timesToday) {
    if (timesToday.isEmpty) return _nowHHmm();

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    String? bestSlot;
    int bestDiff = 99999;

    for (final t in timesToday) {
      try {
        final parsed = DateTime.parse(t).toLocal();
        final slotMinutes = parsed.hour * 60 + parsed.minute;
        final diff = nowMinutes - slotMinutes;

        // เอา slot ที่ผ่านมาแล้ว (diff >= 0) และใกล้ที่สุด
        if (diff >= 0 && diff < bestDiff) {
          bestDiff = diff;
          bestSlot = t;
        }
      } catch (_) {}
    }

    // ถ้าไม่มี slot ที่ผ่านมาเลย ให้ใช้ slot แรก
    if (bestSlot == null && timesToday.isNotEmpty) {
      bestSlot = timesToday.first;
    }

    if (bestSlot == null) return _nowHHmm();

    final parsed = DateTime.parse(bestSlot).toLocal();
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadDelegateId();
    Modular.get<FriendsCubit>().loadFriends();
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _currentTime = DateTime.now()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ReadContext(context).read<ScheduleBloc>().state;
      if (state is ScheduleLoaded) {
        _onFirstScheduleLoaded(state.scheduleResponse);
      } else if (state is! ScheduleLoading) {
        ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─── Actions ────────────────────────────────────────────────────────────

  void _onDateSelected(String date) {
    debugPrint('📅 onDateSelected: $date');
    setState(() {
      _selectedDateStr = date;
      _showFullList = true;
      _userSelectedTime = false;
    });
    ReadContext(context).read<ScheduleBloc>().add(LoadSchedules(date: date));

    final tableState = Modular.get<TableBloc>().state;
    final timesToday = tableState is TableLoaded
        ? tableState.response.timesToday
        : <String>[];
    final snappedTime = _nearestSlotTime(timesToday);

    Modular.get<TableBloc>().add(LoadTableView(date: date, time: snappedTime));
  }

  void _onScheduleTap(Schedule schedule) {
    if (!_isSelectableSchedule(schedule)) return;
    if (schedule.type == 'event') return;

    Modular.get<TableBloc>().add(
      LoadTableView(
        date: DateTimeHelper.formatApiDate(schedule.startAt),
        time: DateTimeHelper.formatApiTime12(schedule.startAt),
      ),
    );
  }

  // void _onFirstScheduleLoaded(scheduleResponse) {
  //   final dates = scheduleResponse.availableDates;
  //   if (dates.isEmpty) return;
  //   Modular.get<TableBloc>().add(LoadTableView(time: _nowHHmm()));
  // }
  void _onFirstScheduleLoaded(scheduleResponse) {
    final dates = scheduleResponse.availableDates;
    if (dates.isEmpty) return;
    // ไม่ส่งวันที่ไปก่อน ให้ backend return days มาก่อน
    Modular.get<TableBloc>().add(LoadTableView());
  }
  // ─── Helpers ────────────────────────────────────────────────────────────

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

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Meetings',
      currentIndex: 0,
      appBarStyle: AppBarStyle.elegant,
      backgroundColor: color.AppColors.background,
      body: BlocConsumer<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          if (state is ScheduleLoaded && _selectedDateStr.isEmpty) {
            _onFirstScheduleLoaded(state.scheduleResponse);
          }
        },
        builder: (context, scheduleState) {
          if (scheduleState is ScheduleLoading ||
              scheduleState is ScheduleInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (scheduleState is ScheduleError) {
            return Center(child: Text(scheduleState.message));
          }

          return BlocBuilder<TableBloc, TableState>(
            builder: (context, tableState) {
              final hasNoData =
                  tableState is TableLoaded &&
                  tableState.response.tables.isEmpty &&
                  tableState.response.myTable.isEmpty &&
                  tableState.response.timesToday.isEmpty;

              if (hasNoData) {
                return Center(child: _buildNoDataView());
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDateTabBar(scheduleState),
                    _buildTableGridSection(scheduleState),
                    _buildScheduleSection(scheduleState),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Sections ───────────────────────────────────────────────────────────

  Widget _buildDateTabBar(ScheduleState scheduleState) {
    if (scheduleState is! ScheduleLoaded) return const SizedBox(height: 16);
    if (_tableDays.isEmpty) return const SizedBox(height: 16);

    final selected = _tableDays.contains(_selectedDateStr)
        ? _selectedDateStr
        : _tableDays.first;

    return DateTabBar(
      key: ValueKey(selected),
      availableDates: _tableDays,
      selectedDate: selected,
      onDateSelected: _onDateSelected,
    );
  }

  Widget _buildScheduleSection(ScheduleState scheduleState) {
    if (scheduleState is! ScheduleLoaded) return const SizedBox.shrink();
    final schedules = scheduleState.scheduleResponse.schedules;
    if (schedules.isEmpty) return const SizedBox.shrink();
    final statuses = _getSchedulesWithStatus(schedules);
    final current = _findByStatus(statuses, ScheduleStatus.now);
    final next = _findByStatus(statuses, ScheduleStatus.next);
    final toShow = [if (current != null) current, if (next != null) next];
    if (toShow.isEmpty) return const SizedBox.shrink();
    return _buildCompactScheduleList(toShow, hasCurrent: current != null);
  }

  Widget _buildTableGridSection(ScheduleState scheduleState) {
    return BlocListener<TableBloc, TableState>(
      listener: (context, tableState) {
        if (tableState is! TableLoaded) return;

        final responseDate = tableState.response.date;

        if (!_tableInitialized) {
          _tableInitialized = true;
          final days = tableState.response.days;
          final timesToday = tableState.response.timesToday;
          final today = DateTimeHelper.formatApiDate(DateTime.now());
          final firstAvailableDate = days.contains(today)
              ? today
              : days.isNotEmpty
              ? days.first
              : tableState.response.date;
          final snappedTime = _nearestSlotTime(timesToday);

          //debugPrint
          debugPrint('🕐 now: ${DateTime.now()}');
          debugPrint('📅 today: $today');
          debugPrint('📅 days: $days');
          debugPrint('📅 selected: $firstAvailableDate');
          debugPrint('⏰ snappedTime: $snappedTime');

          setState(() {
            _tableDays = days;
            _selectedDateStr = firstAvailableDate;
          });

          ReadContext(
            context,
          ).read<ScheduleBloc>().add(LoadSchedules(date: firstAvailableDate));

          Modular.get<TableBloc>().add(
            LoadTableView(date: firstAvailableDate, time: snappedTime),
          );
          return;
        }
        if (tableState.response.days.isNotEmpty) {
          setState(() {
            _tableDays = tableState.response.days;
          });
        }

        if (responseDate != _selectedDateStr && !_shownNoTodayDialog) {
          _shownNoTodayDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AppDialog(
                icon: Icons.calendar_month_outlined,
                iconColor: color.AppColors.warning,
                title: 'No data for this date',
                description:
                    'No meeting data found for the selected date.\n'
                    'Nearest available date is $responseDate.',
                actions: [
                  AppDialogAction(
                    label: 'Go to $responseDate',
                    isPrimary: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedDateStr = responseDate;
                        _shownNoTodayDialog = false;
                        _userSelectedTime = false;
                      });
                      Modular.get<TableBloc>().add(
                        LoadTableView(date: responseDate, time: _nowHHmm()),
                      );
                    },
                    backgroundColor: null,
                  ),
                ],
              ),
            );
          });
        }
      },
      child: BlocBuilder<TableBloc, TableState>(
        builder: (context, tableState) {
          if (tableState is TableLoading) return const _LoadingBox();
          if (tableState is TableLoaded) {
            final schedules = scheduleState is ScheduleLoaded
                ? scheduleState.scheduleResponse.schedules
                : <Schedule>[];
            final viewTime = _normalizeTime(tableState.response.time);
            final currentSchedule = schedules.cast<Schedule?>().firstWhere(
              (s) =>
                  _normalizeTime(DateTimeHelper.formatApiTime12(s!.startAt)) ==
                  viewTime,
              orElse: () => null,
            );
            return TableGridWidget(
              response: tableState.response,
              myDelegateId: int.tryParse(_delegateId ?? '0') ?? 0,
              slotTypeMap: scheduleState is ScheduleLoaded
                  ? _buildSlotTypeMap(schedules)
                  : {},
              currentSchedule: currentSchedule,
              schedules: schedules,
              currentTime: _currentTime,
              onTimeSlotChanged: (time) {
                _userSelectedTime = true;
                Modular.get<TableBloc>().add(
                  ChangeTimeSlot(time, date: tableState.response.date),
                );
              },
            );
          }
          if (tableState is TableError)
            return _ErrorBox(message: tableState.message);
          return const SizedBox.shrink();
        },
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
              color: color.AppColors.textSecondary.withValues(alpha: 0.4),
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
                color: color.AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            AddButtonOutline(
              onPressed: () {
                if (_tableDays.isNotEmpty) {
                  _onDateSelected(_tableDays.first);
                }
              },
              icon: Icons.chevron_left,
              text: 'Go to first available date',
              isLoading: false,
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

  Future<void> _loadDelegateId() async {
    final id = await const FlutterSecureStorage().read(key: 'delegate_id');
    if (mounted) setState(() => _delegateId = id);
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
