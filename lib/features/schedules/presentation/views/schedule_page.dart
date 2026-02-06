// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
// import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
// import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
// import 'package:test_wpa/features/schedules/presentation/widgets/date_header.dart';
// import 'package:test_wpa/features/schedules/presentation/widgets/timeline_row.dart';
// import 'package:test_wpa/features/schedules/presentation/widgets/timeline_event_card.dart';
// import 'package:test_wpa/features/schedules/presentation/widgets/empty_schedule_view.dart';
// import 'package:test_wpa/features/schedules/presentation/widgets/error_schedule_view.dart';
// import 'package:test_wpa/features/widgets/app_calendar_bottom_sheet.dart';
// import 'package:test_wpa/features/widgets/app_scaffold.dart';
// import 'package:flutter_modular/flutter_modular.dart';
// import 'package:intl/intl.dart';

// class SchedulePage extends StatefulWidget {
//   const SchedulePage({super.key});

//   @override
//   State<SchedulePage> createState() => _SchedulePageState();
// }

// class _SchedulePageState extends State<SchedulePage> {
//   DateTime selectedDate = DateTime.now();

//   static const double timelineOffset = 40.0;

//   @override
//   void initState() {
//     super.initState();
//     final today = DateTime.now();
//     final todayStr = DateFormat('yyyy-MM-dd').format(today);
//     selectedDate = today;
//     ReadContext(
//       context,
//     ).read<ScheduleBloc>().add(LoadSchedules(date: todayStr));
//   }

//   void _onDateSelected(DateTime date) {
//     setState(() {
//       selectedDate = date;
//     });
//     final dateString = DateFormat('yyyy-MM-dd').format(date);
//     ReadContext(context).read<ScheduleBloc>().add(ChangeDate(dateString));
//   }

//   void _onRetry() {
//     final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
//     ReadContext(
//       context,
//     ).read<ScheduleBloc>().add(LoadSchedules(date: dateString));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(
//           bottom: 100,
//           right: 20,
//         ), // ⬆️ ขึ้นตามแกน Y
//         child: FloatingActionButton(
//           backgroundColor: const Color(0xFF4F46E5),
//           child: const Icon(Icons.event_busy),
//           onPressed: () {
//             Modular.to.pushNamed('/schedule/create');
//           },
//         ),
//       ),

//       body: AppScaffold(
//         title: 'My Schedule',
//         currentIndex: 4,
//         backgroundColor: const Color(0xFFF9FAFB),
//         appBarStyle: AppBarStyle.elegant,
//         actions: [
//           IconButton(
//             onPressed: () => Modular.to.pushNamed('/notification'),
//             icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
//           ),
//         ],

//         body: Stack(
//           children: [
//             // Timeline vertical line - ปรับค่า left เพื่อขยับเส้น
//             Positioned(
//               left: timelineOffset,
//               top: 0,
//               bottom: 0,
//               child: Container(width: 1, color: Colors.grey[200]),
//             ),
//             // Content
//             Column(
//               children: [
//                 DateHeader(
//                   selectedDate: selectedDate,
//                   onCalendarTap: () {
//                     showCalendarBottomSheet(
//                       context: context,
//                       selectedDate: selectedDate,
//                       onDateSelected: _onDateSelected,
//                     );
//                   },
//                 ),
//                 Expanded(
//                   child: BlocBuilder<ScheduleBloc, ScheduleState>(
//                     builder: (context, state) {
//                       if (state is ScheduleLoading) {
//                         return const Center(
//                           child: CircularProgressIndicator(
//                             color: Color(0xFF4F46E5),
//                           ),
//                         );
//                       }

//                       if (state is ScheduleLoaded) {
//                         final response = state.scheduleResponse;

//                         final todayOnlySchedules = response.schedules.where((
//                           s,
//                         ) {
//                           return DateUtils.isSameDay(
//                             s.startAt.toLocal(),
//                             selectedDate,
//                           );
//                         }).toList();

//                         if (todayOnlySchedules.isEmpty) {
//                           return const EmptyScheduleView();
//                         }

//                         return ListView.separated(
//                           padding: const EdgeInsets.only(
//                             left: 16,
//                             right: 16,
//                             bottom: 100,
//                           ),
//                           itemCount: todayOnlySchedules.length,
//                           separatorBuilder: (context, index) =>
//                               const SizedBox(height: 16),
//                           itemBuilder: (context, index) {
//                             final schedule = todayOnlySchedules[index];
//                             return TimelineRow(
//                               schedule: schedule,
//                               cardType: EventCardType.meeting,
//                             );
//                           },
//                         );
//                       }

//                       if (state is ScheduleError) {
//                         return ErrorScheduleView(
//                           message: state.message,
//                           onRetry: _onRetry,
//                         );
//                       }

//                       return const SizedBox.shrink();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/schedules/presentation/views/attendance_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/date_header.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_row.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_event_card.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/empty_schedule_view.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/error_schedule_view.dart';
import 'package:test_wpa/features/widgets/app_calendar_bottom_sheet.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();

  // 🎯 ปรับตรงนี้เพื่อขยับเส้น timeline
  static const double timelineOffset = 42.0;

  // ✨ Selection mode state
  bool isSelectionMode = false;
  Set<int> selectedScheduleIds = {};

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    selectedDate = today;
    ReadContext(
      context,
    ).read<ScheduleBloc>().add(LoadSchedules(date: todayStr));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
      // Clear selection when changing date
      isSelectionMode = false;
      selectedScheduleIds.clear();
    });
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    ReadContext(context).read<ScheduleBloc>().add(ChangeDate(dateString));
  }

  void _onRetry() {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    ReadContext(
      context,
    ).read<ScheduleBloc>().add(LoadSchedules(date: dateString));
  }

  // ✨ Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedScheduleIds.clear();
      }
    });
  }

  // ✨ Toggle schedule selection
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
      // ✨ Floating Action Button
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 100, right: 20),
      //   child: FloatingActionButton(
      //     backgroundColor: isSelectionMode
      //         ? Colors.green
      //         : const Color(0xFF4F46E5),
      //     child: Icon(isSelectionMode ? Icons.check_circle : Icons.event_busy),
      //     onPressed: _toggleSelectionMode,
      //   ),
      // ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 20),
        child: FloatingActionButton(
          backgroundColor: isSelectionMode
              ? Colors.green
              : const Color(0xFF4F46E5),
          child: Icon(isSelectionMode ? Icons.check_circle : Icons.event_busy),
          onPressed: () {
            if (isSelectionMode) {
              // ✨ ถ้าอยู่ใน selection mode แล้วกด = ไปหน้า AttendanceStatus
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceStatus(),
                ),
              );
            } else {
              // ถ้ายังไม่ได้เปิด selection mode = เปิด selection mode
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
        actions: [
          // ✨ Show selected count when in selection mode
          if (isSelectionMode && selectedScheduleIds.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selectedScheduleIds.length} selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () => Modular.to.pushNamed('/notification'),
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
          ),
        ],
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
                DateHeader(
                  selectedDate: selectedDate,
                  onCalendarTap: () {
                    showCalendarBottomSheet(
                      context: context,
                      selectedDate: selectedDate,
                      onDateSelected: _onDateSelected,
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<ScheduleBloc, ScheduleState>(
                    builder: (context, state) {
                      if (state is ScheduleLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4F46E5),
                          ),
                        );
                      }

                      if (state is ScheduleLoaded) {
                        final response = state.scheduleResponse;

                        final todayOnlySchedules = response.schedules.where((
                          s,
                        ) {
                          return DateUtils.isSameDay(
                            s.startAt.toLocal(),
                            selectedDate,
                          );
                        }).toList();

                        if (todayOnlySchedules.isEmpty) {
                          return const EmptyScheduleView();
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100,
                          ),
                          itemCount: todayOnlySchedules.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final schedule = todayOnlySchedules[index];
                            final isSelected = selectedScheduleIds.contains(
                              schedule.id,
                            );

                            // ✨ Wrap with GestureDetector for tap handling
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
