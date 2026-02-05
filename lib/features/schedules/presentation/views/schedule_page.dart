import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/features/widgets/app_calendar_bottom_sheet.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();

  @override
  // void initState() {
  //   super.initState();
  //   // Load schedules สำหรับวันที่เลือก
  //   final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
  //   context.read<ScheduleBloc>().add(LoadSchedules(date: dateString));
  // }
  void initState() {
    super.initState();

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    selectedDate = today;

    context.read<ScheduleBloc>().add(LoadSchedules(date: todayStr));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    // Load schedules ใหม่ตามวันที่เลือก
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    context.read<ScheduleBloc>().add(ChangeDate(dateString));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Schedule',
      currentIndex: 4,
      actions: const [
        IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null),
      ],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Date picker row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate.toLocal().toString().split(' ')[0],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () {
                      showCalendarBottomSheet(
                        context: context,
                        selectedDate: selectedDate,
                        onDateSelected: _onDateSelected,
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: space.m),

              // Schedule list
              Expanded(
                child: BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder: (context, state) {
                    if (state is ScheduleLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ScheduleLoaded) {
                      final response = state.scheduleResponse;

                      final todayOnlySchedules = response.schedules.where((s) {
                        return DateUtils.isSameDay(
                          s.startAt.toLocal(),
                          selectedDate,
                        );
                      }).toList();
                      if (response.schedules.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: space.m),
                              Text(
                                'No schedules for this date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: todayOnlySchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = todayOnlySchedules[index];

                          final startTime = DateFormat(
                            'HH:mm',
                          ).format(schedule.startAt.toLocal());
                          final endTime = DateFormat(
                            'HH:mm',
                          ).format(schedule.endAt.toLocal());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time and duration
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '$startTime - $endTime',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${schedule.durationMinutes} min',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: space.s),
                                  Divider(),
                                  SizedBox(height: space.s),

                                  // Delegate info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blue[100],
                                        child: Text(
                                          schedule.delegate?.name
                                                  ?.substring(0, 1)
                                                  .toUpperCase() ??
                                              '?',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              schedule.delegate?.name ??
                                                  'No delegate yet',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (schedule
                                                    .delegate
                                                    ?.company
                                                    ?.isNotEmpty ??
                                                false)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  schedule.delegate?.company ??
                                                      '',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Table number
                                  if (schedule.tableNumber.isNotEmpty) ...[
                                    SizedBox(height: space.s),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.table_restaurant,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Table ${schedule.tableNumber}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Country
                                  if (schedule.country.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          schedule.country,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }

                    if (state is ScheduleError) {
                      return Center(
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
                                final dateString = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(selectedDate);
                                context.read<ScheduleBloc>().add(
                                  LoadSchedules(date: dateString),
                                );
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
