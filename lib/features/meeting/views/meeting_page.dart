import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart';
import 'package:test_wpa/features/meeting/widgets/table_grid_widget.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_event_card.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/features/widgets/app_calendar_bottom_sheet.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'dart:async';

enum ScheduleStatus { past, now, next, upcoming }

class ScheduleWithStatus {
  final Schedule schedule;
  final ScheduleStatus status;

  ScheduleWithStatus(this.schedule, this.status);
}

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      ReadContext(context).read<ScheduleBloc>().add(LoadSchedules(date: today));

      // โหลด TableView ของวันนี้ + เวลาปัจจุบัน
      final currentTime = DateFormat('HH:mm').format(DateTime.now());
      Modular.get<TableBloc>().add(
        LoadTableView(date: today, time: currentTime),
      );
    });

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    ReadContext(
      context,
    ).read<ScheduleBloc>().add(LoadSchedules(date: dateString));

    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    Modular.get<TableBloc>().add(
      LoadTableView(date: dateString, time: currentTime),
    );
  }

  // ========================================
  // ✅ ตรวจสอบว่า schedule สามารถ tap ได้หรือไม่
  // ========================================
  bool _canTapSchedule(Schedule schedule) {
    // ไม่ให้ tap: event, nomeeting, leave
    if (schedule.type == 'event') return false;
    if (schedule.type == 'nomeeting') return false;
    if (schedule.leave != null) return false;

    // ไม่ให้ tap: ถ้าไม่มี table_number
    if (schedule.tableNumber == null || schedule.tableNumber!.isEmpty) {
      return false;
    }

    // ให้ tap: meeting ปกติที่มี table_number
    return true;
  }

  void _onScheduleTap(Schedule schedule) {
    if (!_canTapSchedule(schedule)) return;

    final date = DateFormat('yyyy-MM-dd').format(schedule.startAt.toLocal());
    final time = DateFormat('HH:mm').format(schedule.startAt.toLocal());

    Modular.get<TableBloc>().add(LoadTableView(date: date, time: time));

    // Scroll to top เพื่อดู table grid
    // (Optional) สามารถเพิ่ม ScrollController ได้
  }

  List<ScheduleWithStatus> _getSchedulesWithStatus(List<Schedule> schedules) {
    final result = <ScheduleWithStatus>[];
    Schedule? nextFound;

    for (var schedule in schedules) {
      ScheduleStatus status;

      if (_currentTime.isBefore(schedule.startAt.toLocal())) {
        if (nextFound == null) {
          status = ScheduleStatus.next;
          nextFound = schedule;
        } else {
          status = ScheduleStatus.upcoming;
        }
      } else if (_currentTime.isAfter(schedule.endAt.toLocal())) {
        status = ScheduleStatus.past;
      } else {
        status = ScheduleStatus.now;
      }

      result.add(ScheduleWithStatus(schedule, status));
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
      actions: [
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            showCalendarBottomSheet(
              context: context,
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
            );
          },
          tooltip: 'Select date',
        ),
        const IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: null,
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ========== Table Grid Section ==========
            BlocBuilder<TableBloc, TableState>(
              builder: (context, state) {
                if (state is TableLoading) {
                  return Container(
                    height: 400,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is TableLoaded) {
                  return TableGridWidget(response: state.response);
                }

                if (state is TableError) {
                  return Container(
                    height: 400,
                    child: Center(child: Text(state.message)),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const Divider(thickness: 2, height: 2),

            // ========== Schedule Section ==========
            BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading) {
                  return Container(
                    height: 300,
                    child: const Center(child: CircularProgressIndicator()),
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
                        SizedBox(height: space.l),

                        // ========== Current Meeting ==========
                        if (currentSchedule != null) ...[
                          Text(
                            '📍 CURRENT MEETING',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
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
                          SizedBox(height: space.l),
                        ],

                        // ========== Next Meeting ==========
                        if (nextSchedule != null) ...[
                          Text(
                            '⏭️ NEXT MEETING',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
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
                          SizedBox(height: space.l),
                        ],

                        // ========== Today's Schedule ==========
                        Text(
                          'TODAY\'S SCHEDULE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: space.s),

                        if (schedulesWithStatus.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'No schedules for this date',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...schedulesWithStatus.map((s) {
                            return GestureDetector(
                              onTap: () => _onScheduleTap(s.schedule),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TimelineEventCard(
                                  schedule: s.schedule,
                                  type: EventCardType.meeting,
                                ),
                              ),
                            );
                          }).toList(),

                        SizedBox(height: 100),
                      ],
                    ),
                  );
                }

                if (state is ScheduleError) {
                  return Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: space.m),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: space.m),
                          ElevatedButton(
                            onPressed: () {
                              final dateStr = DateFormat(
                                'yyyy-MM-dd',
                              ).format(_selectedDate);
                              ReadContext(context).read<ScheduleBloc>().add(
                                LoadSchedules(date: dateStr),
                              );
                            },
                            child: Text('Retry'),
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
