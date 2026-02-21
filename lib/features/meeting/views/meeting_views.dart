import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_event_card.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/features/widgets/date_tab_bar.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'dart:async';
import 'package:test_wpa/features/schedules/presentation/widgets/time_slot_chip.dart';

class MeetingWidget extends StatefulWidget {
  const MeetingWidget({super.key});

  @override
  State<MeetingWidget> createState() => _MeetingWidgetState();
}

class _MeetingWidgetState extends State<MeetingWidget> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  String _selectedDateStr = '';
  bool _isChangingDate = false;
  Map<String, TimeSlotType> _buildSlotTypeMap(List<Schedule> schedules) {
    final map = <String, TimeSlotType>{};
    for (final s in schedules) {
      final timeKey = DateTimeHelper.formatApiTime12(s.startAt);

      TimeSlotType slotType;
      if (s.leave != null) {
        slotType = TimeSlotType.leave;
      } else {
        switch (s.type) {
          case 'event':
            slotType = TimeSlotType.breakTime;
            break;
          case 'nomeeting':
            slotType = TimeSlotType.free;
            break;
          default:
            slotType = TimeSlotType.meeting;
        }
      }

      // เก็บ key แบบ normalized เพื่อ match ง่าย
      map[_normalizeTime(timeKey)] = slotType;
    }
    return map;
  }

  // เพิ่ม helper method ใน _MeetingWidgetState
  String _normalizeTime(String t) => t.replaceAll(' ', '').toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load without date param -- backend returns default date + available_dates
      ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());

      // Wait for schedule to load, then load table view with the best matching time
      _loadInitialTableView();
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh ทุกครั้งที่กลับมาที่หน้านี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ReadContext(context).read<TableBloc>().add(LoadTableView());
      }
    });
  }

  /// Find the current/next schedule and load the table view using its start_time.
  void _loadInitialTableView() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final scheduleState = ReadContext(context).read<ScheduleBloc>().state;

    String dateToUse;
    String timeToUse;

    if (scheduleState is ScheduleLoaded) {
      final response = scheduleState.scheduleResponse;
      final schedules = response.schedules;
      dateToUse = response.date;

      // Sync the selected date
      if (_selectedDateStr.isEmpty && dateToUse.isNotEmpty) {
        setState(() {
          _selectedDateStr = dateToUse;
        });
      }

      final now = DateTime.now();

      // Find ongoing or next schedule
      Schedule? targetSchedule;
      for (var s in schedules) {
        if (now.isAfter(s.startAt) && now.isBefore(s.endAt)) {
          targetSchedule = s;
          break;
        }
      }
      if (targetSchedule == null) {
        for (var s in schedules) {
          if (now.isBefore(s.startAt)) {
            targetSchedule = s;
            break;
          }
        }
      }

      if (targetSchedule != null) {
        timeToUse = DateTimeHelper.formatTime12(targetSchedule.startAt);
      } else {
        timeToUse = DateTimeHelper.formatTime12(DateTime.now());
      }
    } else {
      // Schedule not loaded yet, use defaults
      dateToUse = DateTimeHelper.formatApiDate(DateTime.now());
      timeToUse = DateTimeHelper.formatApiTime12(DateTime.now());
    }

    Modular.get<TableBloc>().add(
      LoadTableView(date: dateToUse, time: timeToUse),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onDateSelected(String dateString) {
    setState(() {
      _selectedDateStr = dateString;
      _isChangingDate = true; //mark ว่ากำลังเปลี่ยนวัน
    });
    ReadContext(
      context,
    ).read<ScheduleBloc>().add(LoadSchedules(date: dateString));

    final currentTime = DateTimeHelper.formatApiTime12(DateTime.now());
    Modular.get<TableBloc>().add(
      LoadTableView(date: dateString, time: currentTime),
    );
  }

  // ========================================
  // Check if schedule can be tapped to load table
  // ========================================
  bool _canTapSchedule(Schedule schedule) {
    if (schedule.type == 'event') return false;
    if (schedule.type == 'nomeeting') return false;
    if (schedule.leave != null) return false;
    if (schedule.tableNumber == null || schedule.tableNumber!.isEmpty) {
      return false;
    }
    return true;
  }

  void _onScheduleTap(Schedule schedule) {
    if (!_canTapSchedule(schedule)) return;

    final date = DateTimeHelper.formatApiDate(schedule.startAt);
    final time = DateTimeHelper.formatApiTime12(schedule.startAt);

    Modular.get<TableBloc>().add(LoadTableView(date: date, time: time));
  }

  Widget _buildLeaveBanner(Schedule schedule) {
    final timeRange = DateTimeHelper.formatTimeRange12(
      schedule.startAt,
      schedule.endAt,
    );
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
                        timeRange,
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

  List<ScheduleWithStatus> _getSchedulesWithStatus(List<Schedule> schedules) {
    final result = <ScheduleWithStatus>[];
    Schedule? nextFound;

    for (var schedule in schedules) {
      ScheduleStatus status;

      if (_currentTime.isBefore(schedule.startAt)) {
        if (nextFound == null) {
          status = ScheduleStatus.next;
          nextFound = schedule;
        } else {
          status = ScheduleStatus.upcoming;
        }
      } else if (_currentTime.isAfter(schedule.endAt)) {
        status = ScheduleStatus.past;
      } else {
        status = ScheduleStatus.now;
      }
      result.add(ScheduleWithStatus(schedule: schedule, status: status));
    }

    return result;
  }

  ScheduleWithStatus? _getCurrentSchedule(List<ScheduleWithStatus> schedules) {
    try {
      return schedules.firstWhere((s) => s.status == ScheduleStatus.now);
    } catch (e) {
      return null;
    }
  }

  ScheduleWithStatus? _getNextSchedule(List<ScheduleWithStatus> schedules) {
    try {
      return schedules.firstWhere((s) => s.status == ScheduleStatus.next);
    } catch (e) {
      return null;
    }
  }

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
            // ========== Date Header ==========
            const DateHeader(),

            // ========== Date Tab Bar ==========
            BlocBuilder<ScheduleBloc, ScheduleState>(
              buildWhen: (prev, curr) => curr is ScheduleLoaded,
              builder: (context, state) {
                if (state is ScheduleLoaded) {
                  final response = state.scheduleResponse;

                  if (_selectedDateStr.isEmpty && response.date.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedDateStr = response.date;
                      });
                    });
                  } else if (_isChangingDate &&
                      response.date == _selectedDateStr) {
                    // ✅ โหลดเสร็จแล้ว และ response ตรงกับที่เลือก
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _isChangingDate = false);
                    });
                  }

                  return DateTabBar(
                    availableDates: response.availableDates,
                    selectedDate: _selectedDateStr.isNotEmpty
                        ? _selectedDateStr
                        : response.date,
                    onDateSelected: _onDateSelected,
                  );
                }
                //DateTabBar ยังแสดงอยู่ด้วย selected date เดิม
                if (state is ScheduleLoading) {
                  return DateTabBar(
                    availableDates: const [],
                    selectedDate: _selectedDateStr,
                    onDateSelected: _onDateSelected,
                  );
                }
                return const SizedBox(height: 16);
              },
            ),

            // ========== Table Grid Section ==========
            BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, scheduleState) {
                // ตรวจสอบ schedule ปัจจุบัน/ถัดไป
                if (scheduleState is ScheduleLoaded) {
                  final schedulesWithStatus = _getSchedulesWithStatus(
                    scheduleState.scheduleResponse.schedules,
                  );
                  final current =
                      _getCurrentSchedule(schedulesWithStatus)?.schedule ??
                      _getNextSchedule(schedulesWithStatus)?.schedule;

                  // leave != null → banner แดง ไม่แสดง grid
                  if (current != null && current.leave != null) {
                    return _buildLeaveBanner(current);
                  }

                  // type == event หรือ table_number == null → ซ่อน grid
                  if (current != null &&
                      (current.type == 'event' ||
                          current.tableNumber == null ||
                          current.tableNumber!.isEmpty)) {
                    return const SizedBox.shrink();
                  }
                }

                // แสดง TableGrid ตามปกติ
                return BlocBuilder<TableBloc, TableState>(
                  builder: (context, state) {
                    if (_isChangingDate) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is TableLoading) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state is TableLoaded) {
                      if (state.response.date != _selectedDateStr &&
                          _selectedDateStr.isNotEmpty) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final slotTypeMap = scheduleState is ScheduleLoaded
                          ? _buildSlotTypeMap(
                              scheduleState.scheduleResponse.schedules,
                            )
                          : <String, TimeSlotType>{};
                      Schedule? currentScheduleForTable;
                      if (scheduleState is ScheduleLoaded) {
                        final schedules =
                            scheduleState.scheduleResponse.schedules;
                        final viewTime = state.response.time
                            .replaceAll(' ', '')
                            .toLowerCase();
                        for (final s in schedules) {
                          final t = DateTimeHelper.formatApiTime12(
                            s.startAt,
                          ).replaceAll(' ', '').toLowerCase();
                          if (t == viewTime) {
                            currentScheduleForTable = s;
                            break;
                          }
                        }
                      }
                      return TableGridWidget(
                        response: state.response,
                        slotTypeMap: slotTypeMap,
                        currentSchedule: currentScheduleForTable,
                        schedules:
                            scheduleState
                                is ScheduleLoaded // ✅ เพิ่ม
                            ? scheduleState.scheduleResponse.schedules
                            : [],
                        onTimeSlotChanged: (time) {
                          Modular.get<TableBloc>().add(ChangeTimeSlot(time));
                        },
                      );
                    }

                    if (state is TableError) {
                      return SizedBox(
                        height: 300,
                        child: Center(child: Text(state.message)),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),

            // ========== Schedule Section ==========
            BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading || _isChangingDate) {
                  return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is ScheduleLoaded) {
                  final schedulesWithStatus = _getSchedulesWithStatus(
                    state.scheduleResponse.schedules,
                  );
                  final currentSchedule = _getCurrentSchedule(
                    schedulesWithStatus,
                  );
                  final nextSchedule = _getNextSchedule(schedulesWithStatus);
                }

                if (state is ScheduleError) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: color.AppColors.error,
                          ),
                          SizedBox(height: space.m),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: color.AppColors.error),
                          ),
                          SizedBox(height: space.m),
                          ElevatedButton(
                            onPressed: () {
                              if (_selectedDateStr.isNotEmpty) {
                                ReadContext(context).read<ScheduleBloc>().add(
                                  LoadSchedules(date: _selectedDateStr),
                                );
                              } else {
                                ReadContext(
                                  context,
                                ).read<ScheduleBloc>().add(LoadSchedules());
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
