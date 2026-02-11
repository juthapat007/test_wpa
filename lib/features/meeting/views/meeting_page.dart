import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart';
import 'package:test_wpa/features/meeting/widgets/table_grid_widget.dart';
import 'package:test_wpa/features/meeting/widgets/time_slot_selector.dart';
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

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  String _selectedDateStr = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());
      _loadInitialTableView();
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  void _loadInitialTableView() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final scheduleState = ReadContext(context).read<ScheduleBloc>().state;

    String dateToUse;
    String timeToUse;

    if (scheduleState is ScheduleLoaded) {
      final response = scheduleState.scheduleResponse;
      final schedules = response.schedules;
      dateToUse = response.date;

      if (_selectedDateStr.isEmpty && dateToUse.isNotEmpty) {
        setState(() {
          _selectedDateStr = dateToUse;
        });
      }

      final now = DateTime.now();

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

  void _onScheduleTap(Schedule schedule) {
    if (schedule.type != 'meeting') return;
    if (schedule.tableNumber == null || schedule.tableNumber!.isEmpty) return;

    final date = DateTimeHelper.formatApiDate(schedule.startAt);
    final time = DateTimeHelper.formatApiTime12(schedule.startAt);

    Modular.get<TableBloc>().add(LoadTableView(date: date, time: time));
  }

  Schedule? _getCurrentSchedule(List<Schedule> schedules) {
    try {
      return schedules.firstWhere((s) {
        return _currentTime.isAfter(s.startAt) &&
            _currentTime.isBefore(s.endAt);
      });
    } catch (e) {
      return null;
    }
  }

  Schedule? _getNextSchedule(List<Schedule> schedules) {
    try {
      return schedules.firstWhere((s) {
        return _currentTime.isBefore(s.startAt);
      });
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
                  return TableGridWidget(response: state.response);
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

            SizedBox(height: space.l),

            // ========== Current/Next Meeting Cards ==========
            BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is ScheduleLoaded) {
                  final schedules = state.scheduleResponse.schedules;
                  final currentSchedule = _getCurrentSchedule(schedules);
                  final nextSchedule = _getNextSchedule(schedules);
                  return Column(children: [Text('test')]);
                  // return Column(
                  //   children: [
                  //     // Current & Next Meeting Cards
                  //     if (currentSchedule != null || nextSchedule != null)
                  //       Padding(
                  //         padding: const EdgeInsets.symmetric(horizontal: 16),
                  //         child: Row(
                  //           children: [
                  //             // Current Meeting
                  //             if (currentSchedule != null)
                  //               Expanded(
                  //                 child: Column(
                  //                   crossAxisAlignment:
                  //                       CrossAxisAlignment.start,
                  //                   children: [
                  //                     Text(
                  //                       'CURRENT',
                  //                       style: TextStyle(
                  //                         fontSize: 11,
                  //                         fontWeight: FontWeight.bold,
                  //                         color: color.AppColors.textSecondary,
                  //                         letterSpacing: 0.5,
                  //                       ),
                  //                     ),
                  //                     SizedBox(height: space.xs),
                  //                     GestureDetector(
                  //                       onTap: () =>
                  //                           _onScheduleTap(currentSchedule),
                  //                       child: _buildCompactCard(
                  //                         currentSchedule,
                  //                         color.AppColors.primary,
                  //                         'NOW',
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             if (currentSchedule != null &&
                  //                 nextSchedule != null)
                  //               SizedBox(width: space.m),
                  //             // Next Meeting
                  //             if (nextSchedule != null)
                  //               Expanded(
                  //                 child: Column(
                  //                   crossAxisAlignment:
                  //                       CrossAxisAlignment.start,
                  //                   children: [
                  //                     Text(
                  //                       'NEXT',
                  //                       style: TextStyle(
                  //                         fontSize: 11,
                  //                         fontWeight: FontWeight.bold,
                  //                         color: color.AppColors.textSecondary,
                  //                         letterSpacing: 0.5,
                  //                       ),
                  //                     ),
                  //                     SizedBox(height: space.xs),
                  //                     GestureDetector(
                  //                       onTap: () =>
                  //                           _onScheduleTap(nextSchedule),
                  //                       child: _buildCompactCard(
                  //                         nextSchedule,
                  //                         color.AppColors.warning,
                  //                         'NEXT',
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //           ],
                  //         ),
                  //       ),

                  //     SizedBox(height: space.l),

                  //     // Time Slot Selector
                  //     TimeSlotSelector(
                  //       schedules: schedules,
                  //       onSlotTap: _onScheduleTap,
                  //       currentSchedule: currentSchedule,
                  //       nextSchedule: nextSchedule,
                  //     ),

                  //     SizedBox(height: space.xl),
                  //   ],
                  // );
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

  Widget _buildCompactCard(Schedule schedule, Color accentColor, String label) {
    final startTime = DateTimeHelper.formatTime12(schedule.startAt);
    final endTime = DateTimeHelper.formatTime12(schedule.endAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$startTime - $endTime',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: space.xs),

          // Company/Delegate
          if (schedule.teamDelegates?.isNotEmpty ?? false) ...[
            Text(
              schedule.teamDelegates!.first.company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            Text(
              schedule.teamDelegates!.map((d) => d.name).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color.AppColors.textSecondary,
              ),
            ),
          ],

          // Table
          if (schedule.tableNumber != null) ...[
            SizedBox(height: space.xs),
            Row(
              children: [
                Icon(Icons.table_restaurant, size: 10, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  'Table ${schedule.tableNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
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
