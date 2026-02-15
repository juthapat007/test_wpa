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
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_event_card.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/features/widgets/date_tab_bar.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'dart:async';

class MeetingWidget extends StatefulWidget {
  const MeetingWidget({super.key});

  @override
  State<MeetingWidget> createState() => _MeetingWidgetState();
}

class _MeetingWidgetState extends State<MeetingWidget> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  String _selectedDateStr = '';

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
        timeToUse = DateTimeHelper.formatApiTime12(targetSchedule.startAt);
      } else {
        timeToUse = DateTimeHelper.formatApiTime12(DateTime.now());
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
                  }

                  return DateTabBar(
                    availableDates: response.availableDates,
                    selectedDate: _selectedDateStr.isNotEmpty
                        ? _selectedDateStr
                        : response.date,
                    onDateSelected: _onDateSelected,
                  );
                }
                return const SizedBox(height: 16);
              },
            ),

            // ========== Table Grid Section ==========
            BlocBuilder<TableBloc, TableState>(
              builder: (context, state) {
                if (state is TableLoading) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is TableLoaded) {
                  return TableGridWidget(
                    response: state.response,
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
            ),

            // ========== Schedule Section ==========
            BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading) {
                  return const SizedBox(
                    height: 300,
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

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ========== Current Meeting ==========
                        if (currentSchedule != null) ...[
                          Text(
                            'CURRENT MEETING',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color.AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: space.s),
                          GestureDetector(
                            onTap: () =>
                                _onScheduleTap(currentSchedule.schedule),
                            child: TimelineEventCard(
                              schedule: currentSchedule.schedule,
                              type: EventCardType.meeting,
                            ),
                          ),
                          SizedBox(height: space.m),
                        ],

                        // ========== Next Meeting ==========
                        if (nextSchedule != null) ...[
                          Text(
                            'NEXT MEETING',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color.AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: space.s),
                          GestureDetector(
                            onTap: () => _onScheduleTap(nextSchedule.schedule),
                            child: TimelineEventCard(
                              schedule: nextSchedule.schedule,
                              type: EventCardType.meeting,
                            ),
                          ),
                          SizedBox(height: space.m),
                        ],

                        // ========== Today's Schedule ==========
                        Text(
                          'TODAY\'S SCHEDULE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color.AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: space.s),

                        if (schedulesWithStatus.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'No schedules for this date',
                                style: TextStyle(
                                  color: color.AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ...schedulesWithStatus.map((s) {
                            final canTap = _canTapSchedule(s.schedule);
                            return GestureDetector(
                              onTap: () => _onScheduleTap(s.schedule),
                              child: Opacity(
                                opacity: canTap ? 1.0 : 0.7,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: TimelineEventCard(
                                    schedule: s.schedule,
                                    type: EventCardType.meeting,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  );
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
