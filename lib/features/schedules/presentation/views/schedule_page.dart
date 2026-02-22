import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart'
    hide ChangeDate;
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/schedules/presentation/views/attendance_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_row.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/states/empty_schedule_view.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/states/error_schedule_view.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';
import 'package:test_wpa/features/widgets/date_tab_bar.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const double timelineOffset = 42.0;

  bool isSelectionMode = false;
  Set<int> selectedScheduleIds = {};
  String _selectedDateStr = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());
    });
  }

  void _onDateSelected(String dateString) {
    setState(() {
      _selectedDateStr = dateString;
      selectedScheduleIds.clear();
    });
    ReadContext(context).read<ScheduleBloc>().add(ChangeDate(dateString));
  }

  void _onRetry() {
    ReadContext(context).read<ScheduleBloc>().add(
      LoadSchedules(
        date: _selectedDateStr.isNotEmpty ? _selectedDateStr : null,
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) selectedScheduleIds.clear();
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedScheduleIds.clear();
    });
  }

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

  void _proceedToAttendanceStatus() async {
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

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AttendanceStatus(selectedSchedules: selectedSchedules),
        ),
      );

      // ✅ เปลี่ยนจาก if (result == true) เป็น if (mounted) เสมอ
      if (mounted) {
        setState(() {
          isSelectionMode = false;
          selectedScheduleIds.clear();
        });
        ReadContext(context).read<ScheduleBloc>().add(
          LoadSchedules(
            date: _selectedDateStr.isNotEmpty ? _selectedDateStr : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.AppColors.surface,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: 'cancel_selection',
                backgroundColor: color.AppColors.error,
                onPressed: _cancelSelectionMode,
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: height.xxl),
            child: FloatingActionButton(
              heroTag: 'main_action',
              backgroundColor: isSelectionMode
                  ? color.AppColors.success
                  : color.AppColors.warning,
              onPressed: () {
                if (isSelectionMode) {
                  _proceedToAttendanceStatus();
                } else {
                  _toggleSelectionMode();
                }
              },
              child: Icon(
                isSelectionMode ? Icons.check_circle : Icons.event_busy,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
            Column(
              children: [
                // ──────────── Date Tab Bar ────────────
                BlocBuilder<ScheduleBloc, ScheduleState>(
                  buildWhen: (prev, curr) => curr is ScheduleLoaded,
                  builder: (context, state) {
                    if (state is ScheduleLoaded) {
                      final response = state.scheduleResponse;

                      // ✅ ครั้งแรก: ใช้ response.date เป็น source of truth
                      if (_selectedDateStr.isEmpty &&
                          response.availableDates.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _selectedDateStr = response.date);
                            // Preload table state สำหรับ Meeting page ที่ใช้ shared bloc
                            Modular.get<TableBloc>().add(
                              LoadTableView(date: response.date),
                            );
                          }
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

                // ──────────── Schedule List ────────────
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
                        final schedules = state.scheduleResponse.schedules;
                        if (schedules.isEmpty) return const EmptyScheduleView();

                        return ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: height.l,
                          ),
                          itemCount: schedules.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: height.m),
                          itemBuilder: (context, index) {
                            final schedule = schedules[index];
                            final isSelected = selectedScheduleIds.contains(
                              schedule.id,
                            );
                            final isSelectable =
                                schedule.leave == null &&
                                schedule.type == 'meeting';

                            return GestureDetector(
                              onTap: isSelectionMode && isSelectable
                                  ? () => _toggleScheduleSelection(schedule.id)
                                  : null,
                              child: Opacity(
                                opacity: isSelectionMode && !isSelectable
                                    ? 0.4
                                    : 1.0,
                                child: TimelineRow(
                                  schedule: schedule,
                                  cardType: ScheduleCardHelper.resolveCardType(
                                    schedule,
                                  ),
                                  isSelectionMode:
                                      isSelectionMode && isSelectable,
                                  isSelected: isSelected,
                                ),
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
