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
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_event_card.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/features/widgets/app_calendar_bottom_sheet.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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

      // ⏰ รอให้ schedule โหลดเสร็จก่อน แล้วค่อยหาเวลาที่เหมาะสม
      _loadInitialTableView();
    });

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  // 🔍 หา current/next schedule แล้วยิง table view ด้วย start_time ของมัน
  void _loadInitialTableView() async {
    await Future.delayed(
      Duration(milliseconds: 500),
    ); // รอ schedule bloc โหลดเสร็จ

    final scheduleState = ReadContext(context).read<ScheduleBloc>().state;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String timeToUse;

    if (scheduleState is ScheduleLoaded) {
      final schedules = scheduleState.scheduleResponse.schedules;
      final now = DateTime.now(); // ใช้ local time เพราะ schedule เป็น local time แล้ว

      print('🕐 Current local time: $now');
      print('📋 Available schedules: ${schedules.length}');

      // Debug: แสดงเวลาของทุก schedule
      for (var s in schedules) {
        print('   Schedule ${s.id}: ${s.startAt} to ${s.endAt}');
      }

      // หา schedule ที่ปัจจุบันอยู่ในช่วง หรือ schedule ถัดไป
      Schedule? targetSchedule;

      // 1. หา ongoing schedule (กำลังเกิดขึ้นอยู่)
      for (var s in schedules) {
        if (now.isAfter(s.startAt) && now.isBefore(s.endAt)) {
          targetSchedule = s;
          print('✅ Found ONGOING schedule: ${s.id}');
          break;
        }
      }

      // 2. ถ้าไม่มี ongoing ให้หา next schedule (schedule ถัดไปที่จะมาถึง)
      if (targetSchedule == null) {
        for (var s in schedules) {
          if (now.isBefore(s.startAt)) {
            targetSchedule = s;
            print('✅ Found NEXT schedule: ${s.id}');
            break;
          }
        }
      }

      // ใช้ start_time ของ schedule ที่เจอ
      if (targetSchedule != null) {
        // 🔧 Debug: ลองทั้ง 3 format
        final format1 = DateFormat(
          'h:mm a',
        ).format(targetSchedule.startAt); // "10:01 AM"
        final format2 = DateFormat(
          'h:mm:a',
        ).format(targetSchedule.startAt); // "10:01:AM"
        final format3 = DateFormat(
          'HH:mm',
        ).format(targetSchedule.startAt); // "10:01"

        print('🔍 Time formats:');
        print('   Format 1 (h:mm a):  $format1');
        print('   Format 2 (h:mm:a):  $format2');
        print('   Format 3 (HH:mm):   $format3');

        // ใช้ formatApiTime12 ซึ่งเป็น "h:mm a" (เช่น "9:00 AM")
        timeToUse = DateTimeHelper.formatApiTime12(targetSchedule.startAt);
        print(
          '🎯 Using schedule time: $timeToUse (from schedule ${targetSchedule.id})',
        );
      } else {
        // ถ้าไม่มี schedule เลย (ทุก schedule ผ่านไปแล้ว) ใช้เวลาปัจจุบัน
        timeToUse = DateTimeHelper.formatApiTime12(DateTime.now());
        print('⚠️ No upcoming schedule, using current time: $timeToUse');
      }
    } else {
      // ถ้า schedule ยังไม่โหลด ใช้เวลาปัจจุบัน
      timeToUse = DateTimeHelper.formatApiTime12(DateTime.now());
      print('⚠️ Schedule not loaded yet, using current time: $timeToUse');
    }

    print('📤 Sending to TableBloc: date=$today, time=$timeToUse');
    Modular.get<TableBloc>().add(LoadTableView(date: today, time: timeToUse));
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

    final currentTime = DateTimeHelper.formatApiTime12(DateTime.now());
    Modular.get<TableBloc>().add(
      LoadTableView(date: dateString, time: currentTime),
    );
  }

  // ========================================
  //  ตรวจสอบว่า schedule สามารถ tap ได้หรือไม่
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

    final date = DateTimeHelper.formatApiDate(schedule.startAt);
    final time = DateTimeHelper.formatApiTime12(schedule.startAt);
    final timeEnd = DateTimeHelper.formatApiTime12(schedule.endAt);
    print('🔍 Tapped schedule - Date: $date, Time: $time - $timeEnd');

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
            DateHeader(
              selectedDate: _selectedDate,
              onCalendarTap: () {
                showCalendarBottomSheet(
                  context: context,
                  selectedDate: _selectedDate,
                  onDateSelected: _onDateSelected,
                );
              },
            ),
            // ========== Table Grid Section ==========
            BlocBuilder<TableBloc, TableState>(
              builder: (context, state) {
                if (state is TableLoading) {
                  return Container(
                    height: 300,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is TableLoaded) {
                  return TableGridWidget(response: state.response);
                }

                if (state is TableError) {
                  return Container(
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

                        // SizedBox(height: 100),
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
