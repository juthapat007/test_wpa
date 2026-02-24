import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/entities/leave_type.dart';
import 'package:test_wpa/features/schedules/domain/entities/leave_form.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_bloc.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';
import 'package:test_wpa/features/widgets/bottom_action_bar.dart';
import 'package:intl/intl.dart';

class AttendanceStatus extends StatefulWidget {
  final List<Schedule> selectedSchedules;
  const AttendanceStatus({super.key, required this.selectedSchedules});

  @override
  State<AttendanceStatus> createState() => _AttendanceStatusState();
}

class _AttendanceStatusState extends State<AttendanceStatus> {
  LeaveType? _selectedLeaveType;
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Modular.get<ScheduleBloc>().add(LoadLeaveTypes());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) return;
    final leaveForms = widget.selectedSchedules
        .map(
          (s) => LeaveForm(
            scheduleId: s.id,
            leaveTypeId: _selectedLeaveType!.id,
            explanation: _reasonController.text.trim(),
          ),
        )
        .toList();
    ReadContext(context).read<ScheduleBloc>().add(
      SubmitLeaveForms(LeaveFormsRequest(leaves: leaveForms)),
    );
  }

  void _onStateChanged(BuildContext context, ScheduleState state) {
    if (state is LeaveTypesError) {
      _showSnackBar(state.message, Colors.red);
    } else if (state is LeaveFormsSubmitted) {
      _showSnackBar('Leave forms submitted successfully! ✓', Colors.green);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else if (state is LeaveFormsSubmitError) {
      _showSnackBar('Error: ${state.message}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: Modular.get<ScheduleBloc>(),
      child: BlocConsumer<ScheduleBloc, ScheduleState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final isLoading = state is ScheduleLoading;
          final isSubmitting = state is LeaveFormsSubmitting;
          final leaveTypes = state is LeaveTypesLoaded
              ? state.leaveTypes
              : <LeaveType>[];

          return Scaffold(
            backgroundColor: color.AppColors.background,
            appBar: AppBar(
              title: const Text(
                'Attendance Status',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: color.AppColors.textPrimary,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: Colors.grey[200], height: 1),
              ),
            ),
            bottomNavigationBar: BottomActionBar(
              onCancel: () => Navigator.pop(context),
              onConfirm: _handleConfirm,
              isLoading: isSubmitting,
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      _buildForm(leaveTypes),
                      if (isSubmitting) _buildLoadingOverlay(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildForm(List<LeaveType> leaveTypes) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(space.m, space.m, space.m, space.m + 80),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: space.s),
            _SectionLabel(icon: Icons.category_outlined, label: 'Leave Type'),
            SizedBox(height: space.s),
            _LeaveTypeDropdown(
              leaveTypes: leaveTypes,
              value: _selectedLeaveType,
              onChanged: (v) => setState(() => _selectedLeaveType = v),
            ),
            SizedBox(height: space.l),
            _SectionLabel(icon: Icons.edit_note_outlined, label: 'Explanation'),
            SizedBox(height: space.s),
            _ExplanationField(controller: _reasonController),
            SizedBox(height: space.l),
            Row(
              children: [
                const Text(
                  'Selected Meetings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color.AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.selectedSchedules.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: space.s),
            ...widget.selectedSchedules.map((s) => _ScheduleCard(schedule: s)),
            SizedBox(height: space.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() => Container(
    color: Colors.black.withOpacity(0.3),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Submitting...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Private widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: color.AppColors.primary),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color.AppColors.textPrimary,
        ),
      ),
    ],
  );
}

class _LeaveTypeDropdown extends StatelessWidget {
  final List<LeaveType> leaveTypes;
  final LeaveType? value;
  final ValueChanged<LeaveType?> onChanged;

  const _LeaveTypeDropdown({
    required this.leaveTypes,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<LeaveType>(
    decoration: InputDecoration(
      hintText: 'Select leave type',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: color.AppColors.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    value: value,
    items: leaveTypes
        .where((t) => t.active)
        .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
        .toList(),
    onChanged: onChanged,
    validator: (v) => v == null ? 'Please select a leave type' : null,
  );
}

class _ExplanationField extends StatelessWidget {
  final TextEditingController controller;
  const _ExplanationField({required this.controller});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: 4,
    decoration: InputDecoration(
      hintText: 'Please provide details...',
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: color.AppColors.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.all(14),
    ),
    validator: (v) => (v == null || v.trim().isEmpty)
        ? 'Please provide an explanation'
        : null,
  );
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('h:mm a').format(schedule.startAt);
    final end = DateFormat('h:mm a').format(schedule.endAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              size: 18,
              color: color.AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$start – $end',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (schedule.delegate?.company != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    schedule.delegate!.company!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Table ${schedule.tableNumber}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
        ],
      ),
    );
  }
}
