import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
// import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart'
//     hide ChangeDate;
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
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
  static const double _timelineOffset = 38.0;

  bool _isSelectionMode = false;
  Set<int> _selectedScheduleIds = {};
  String _selectedDateStr = '';

  @override
  void initState() {
    super.initState();
    // ✅ ยิง LoadSchedules ครั้งเดียวตอน init เท่านั้น
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ReadContext(context).read<ScheduleBloc>().add(LoadSchedules());
      }
    });
  }

  // ─── Date selection ──────────────────────────────────────────────────────────

  void _onDateSelected(String date) {
    setState(() {
      _selectedDateStr = date;
      _selectedScheduleIds.clear();
    });
    ReadContext(context).read<ScheduleBloc>().add(ChangeDate(date));
  }

  // ─── Retry ───────────────────────────────────────────────────────────────────

  void _onRetry() {
    ReadContext(context).read<ScheduleBloc>().add(
      LoadSchedules(
        date: _selectedDateStr.isNotEmpty ? _selectedDateStr : null,
      ),
    );
  }

  // ─── Selection mode ──────────────────────────────────────────────────────────

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedScheduleIds.clear();
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedScheduleIds.clear();
    });
  }

  void _toggleScheduleSelection(int scheduleId) {
    if (!_isSelectionMode) return;
    setState(() {
      if (_selectedScheduleIds.contains(scheduleId)) {
        _selectedScheduleIds.remove(scheduleId);
      } else {
        _selectedScheduleIds.add(scheduleId);
      }
    });
  }

  // ─── Proceed to attendance ───────────────────────────────────────────────────

  Future<void> _proceedToAttendanceStatus() async {
    if (_selectedScheduleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one meeting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final state = ReadContext(context).read<ScheduleBloc>().state;
    if (state is! ScheduleLoaded) return;

    final selectedSchedules = state.scheduleResponse.schedules
        .where((s) => _selectedScheduleIds.contains(s.id))
        .toList();

    final result = await Modular.to.pushNamed<bool>(
      '/attendance',
      arguments: selectedSchedules,
    );

    if (!mounted) return;

    setState(() {
      _isSelectionMode = false;
      _selectedScheduleIds.clear();
    });

    ReadContext(context).read<ScheduleBloc>().add(
      LoadSchedules(
        date: _selectedDateStr.isNotEmpty ? _selectedDateStr : null,
      ),
    );

    if (result == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Leave submitted successfully! ✓'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      });
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.AppColors.surface,
      floatingActionButton: _buildFAB(),
      // ✅ BlocListener จัดการ side effects แยกจาก BlocBuilder
      body: BlocListener<ScheduleBloc, ScheduleState>(
        listenWhen: (_, curr) =>
            curr is ScheduleLoaded && _selectedDateStr.isEmpty,
        listener: (context, state) {
          if (state is! ScheduleLoaded) return;
          final response = state.scheduleResponse;
          if (response.availableDates.isEmpty) return;
        },
        child: AppScaffold(
          title: 'My Schedule',
          currentIndex: 4,
          backgroundColor: const Color(0xFFF9FAFB),
          appBarStyle: AppBarStyle.elegant,
          showBottomNavBar: true,
          body: Stack(
            children: [
              // Timeline vertical line
              Positioned(
                left: _timelineOffset,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: Colors.grey[200]),
              ),
              Column(
                children: [
                  _buildDateTabBar(),
                  Expanded(child: _buildScheduleList()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSelectionMode)
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
          padding: const EdgeInsets.only(bottom: 150),
          child: FloatingActionButton(
            heroTag: 'main_action',
            backgroundColor: _isSelectionMode
                ? color.AppColors.success
                : color.AppColors.warning,
            onPressed: _isSelectionMode
                ? _proceedToAttendanceStatus
                : _toggleSelectionMode,
            child: Icon(
              _isSelectionMode ? Icons.check_circle : Icons.event_busy,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ BlocBuilder นี้ไม่มี side effect แล้ว — แค่ render UI
  Widget _buildDateTabBar() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      buildWhen: (prev, curr) =>
          curr is ScheduleLoaded && prev is! ScheduleLoaded,
      builder: (context, state) {
        if (state is! ScheduleLoaded) return const SizedBox(height: 16);

        final response = state.scheduleResponse;
        return DateTabBar(
          availableDates: response.availableDates,
          selectedDate: _selectedDateStr.isNotEmpty
              ? _selectedDateStr
              : response.date,
          onDateSelected: _onDateSelected,
        );
      },
    );
  }

  Widget _buildScheduleList() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is ScheduleLoading) {
          return const Center(
            child: CircularProgressIndicator(color: color.AppColors.primary),
          );
        }

        if (state is ScheduleLoaded) {
          final schedules = state.scheduleResponse.schedules;
          if (schedules.isEmpty) return const EmptyScheduleView();

          return ListView.separated(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: height.l),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: space.s),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final isSelected = _selectedScheduleIds.contains(schedule.id);
              final isSelectable =
                  schedule.leave == null && schedule.type == 'meeting';

              return GestureDetector(
                onTap: (_isSelectionMode && isSelectable)
                    ? () => _toggleScheduleSelection(schedule.id)
                    : null,
                child: Opacity(
                  opacity: (_isSelectionMode && !isSelectable) ? 0.4 : 1.0,
                  child: TimelineRow(
                    schedule: schedule,
                    cardType: ScheduleCardHelper.resolveCardType(schedule),
                    isSelectionMode: _isSelectionMode && isSelectable,
                    isSelected: isSelected,
                  ),
                ),
              );
            },
          );
        }

        if (state is ScheduleError) {
          return ErrorScheduleView(message: state.message, onRetry: _onRetry);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
