import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/schedules/presentation/views/attendance_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_row.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_event_card.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/empty_schedule_view.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/error_schedule_view.dart';
import 'package:test_wpa/features/widgets/date_tab_bar.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // Timeline offset for the vertical line
  static const double timelineOffset = 42.0;

  // Selection mode state
  bool isSelectionMode = false;
  Set<int> selectedScheduleIds = {};

  // Tracks the currently selected date string from available_dates
  String _selectedDateStr = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load without date param -- backend returns default date + available_dates
      ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());
    });
  }

  void _onDateSelected(String dateString) {
    setState(() {
      _selectedDateStr = dateString;
      isSelectionMode = false;
      selectedScheduleIds.clear();
    });
    ReadContext(context).read<ScheduleBloc>().add(ChangeDate(dateString));
  }

  void _onRetry() {
    if (_selectedDateStr.isNotEmpty) {
      ReadContext(
        context,
      ).read<ScheduleBloc>().add(LoadSchedules(date: _selectedDateStr));
    } else {
      ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());
    }
  }

  // Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedScheduleIds.clear();
      }
    });
  }

  // Toggle schedule selection
  void _toggleScheduleSelection(int scheduleId) {
    if (!isSelectionMode) return;

    setState(() {
      if (selectedScheduleIds.contains(scheduleId)) {
        selectedScheduleIds.remove(scheduleId);
      } else {
        selectedScheduleIds.add(scheduleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.AppColors.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 20),
        child: FloatingActionButton(
          backgroundColor: isSelectionMode
              ? color.AppColors.success
              : color.AppColors.warning,
          child: Icon(isSelectionMode ? Icons.check_circle : Icons.event_busy),
          onPressed: () {
            if (isSelectionMode) {
              if (selectedScheduleIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select at least one meeting'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final state = ReadContext(context).read<ScheduleBloc>().state;
              if (state is ScheduleLoaded) {
                final selectedSchedules = state.scheduleResponse.schedules
                    .where((s) => selectedScheduleIds.contains(s.id))
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AttendanceStatus(selectedSchedules: selectedSchedules),
                  ),
                );
              }
            } else {
              _toggleSelectionMode();
            }
          },
        ),
      ),
      body: AppScaffold(
        title: 'My Schedule',
        currentIndex: 4,
        backgroundColor: const Color(0xFFF9FAFB),
        appBarStyle: AppBarStyle.elegant,
        showBottomNavBar: true,
        body: Stack(
          children: [
            // Timeline vertical line
            Positioned(
              left: timelineOffset,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.grey[200]),
            ),
            // Content
            Column(
              children: [
                // BlocBuilder to get available_dates for the DateTabBar
                BlocBuilder<ScheduleBloc, ScheduleState>(
                  buildWhen: (prev, curr) {
                    // Only rebuild the date bar when the loaded response changes
                    if (curr is ScheduleLoaded) return true;
                    return false;
                  },
                  builder: (context, state) {
                    if (state is ScheduleLoaded) {
                      final response = state.scheduleResponse;

                      // Sync _selectedDateStr on first load
                      if (_selectedDateStr.isEmpty &&
                          response.date.isNotEmpty) {
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
                    // While loading or error, show nothing for the tab bar
                    return const SizedBox(height: 16);
                  },
                ),
                // Schedule list
                Expanded(
                  child: BlocBuilder<ScheduleBloc, ScheduleState>(
                    builder: (context, state) {
                      if (state is ScheduleLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: color.AppColors.primary,
                          ),
                        );
                      }

                      if (state is ScheduleLoaded) {
                        final response = state.scheduleResponse;
                        final schedules = response.schedules;

                        if (schedules.isEmpty) {
                          return const EmptyScheduleView();
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100,
                          ),
                          itemCount: schedules.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final schedule = schedules[index];
                            final isSelected = selectedScheduleIds.contains(
                              schedule.id,
                            );

                            return GestureDetector(
                              onTap: () =>
                                  _toggleScheduleSelection(schedule.id),
                              child: TimelineRow(
                                schedule: schedule,
                                cardType: EventCardType.meeting,
                                isSelectionMode: isSelectionMode,
                                isSelected: isSelected,
                              ),
                            );
                          },
                        );
                      }

                      if (state is ScheduleError) {
                        return ErrorScheduleView(
                          message: state.message,
                          onRetry: _onRetry,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
