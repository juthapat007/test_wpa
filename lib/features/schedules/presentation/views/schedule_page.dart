import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_row.dart';
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
  static const double _timelineOffset = 25.0;

  bool _isSelectionMode = false;
  Set<int> _selectedScheduleIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = ReadContext(context).read<ScheduleBloc>();
      if (bloc.state is! ScheduleLoaded) {
        bloc.add(LoadSchedules());
      }
    });
  }

  // ─── Date selection ───────────────────────────────────────────────────────

  void _onDateSelected(String date) {
    debugPrint('📅 onDateSelected: $date');
    setState(() => _selectedScheduleIds.clear());
    //ล้าง schedule เดิมเพราะ user เปลี่ยนวันใหม่
    ReadContext(context).read<ScheduleBloc>().add(LoadSchedules(date: date));
    //สั่งโหลด schedule ของวันที่เลือกใหม่
    Modular.get<TableBloc>().add(LoadTableView(date: date));
    //table/meeting grid ของวันที่เลือกด้วย เพราะทั้ง 2 ส่วนต้องแสดงวันเดียวกัน
  }

  // ─── Retry ────────────────────────────────────────────────────────────────

  void _onRetry() {
    final state = ReadContext(context).read<ScheduleBloc>().state;
    final date = state is ScheduleLoaded ? state.selectedDate : null;
    ReadContext(context).read<ScheduleBloc>().add(LoadSchedules(date: date));
  }

  // ─── Selection mode ───────────────────────────────────────────────────────

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedScheduleIds.clear();
      //ถ้าอกจากโหมดselection จะ clear รายการที่เลือกไว้ด้วย
    });
  }
  //การสลับโหมดไปมา  เข้า/ออก selection mode

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

  // ─── Proceed to attendance ────────────────────────────────────────────────

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
    if (state is! ScheduleLoaded) return; //เช็คว่ามีข้อมูลมั้ย

    final selectedSchedules = state.scheduleResponse.schedules
        .where((s) => _selectedScheduleIds.contains(s.id))
        .toList();

    final currentDate = state.selectedDate; //กรองเฉพาะที่เลือก

    final result = await Modular.to.pushNamed<bool>(
      '/attendance',
      arguments: selectedSchedules,
    ); // ไปหน้า attendance รอ result

    if (!mounted) return;

    setState(() {
      _isSelectionMode = false;
      _selectedScheduleIds.clear();
    });

    ReadContext(context).read<ScheduleBloc>().add(
      LoadSchedules(date: currentDate),
    ); //รีโหลดวันเดิม

    if (result == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Leave submitted successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.AppColors.surface,
      floatingActionButton: _buildFAB(),
      body: AppScaffold(
        title: 'My Schedule',
        currentIndex: 4,
        backgroundColor: const Color(0xFFF9FAFB),
        appBarStyle: AppBarStyle.elegant,
        showBottomNavBar: true,
        body: Stack(
          children: [
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
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

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

  Widget _buildDateTabBar() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded) return const SizedBox(height: 16);
        final response = state.scheduleResponse;
        if (response.availableDates.isEmpty) return const SizedBox(height: 16);

        return DateTabBar(
          key: ValueKey(state.selectedDate), //rebuild เมื่อวันเปลี่ยน
          availableDates: response.availableDates,
          selectedDate: state.selectedDate, //highlight วันที่ถูกต้อง
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
          for (final s in schedules) {
            debugPrint('📋 id:${s.id} type:${s.type} leave:${s.leave}');
          }
          if (schedules.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No events today',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select another date from the tab above',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: height.m),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: space.s),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final isSelected = _selectedScheduleIds.contains(schedule.id);
              final isSelectable =
                  schedule.leave == null &&
                  schedule.type ==
                      'meeting'; //การลาจะทำได้แค่เมื่อ card เป็น meeting เท่านั้น

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
