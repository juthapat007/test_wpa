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
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:intl/intl.dart';

class AttendanceStatus extends StatefulWidget {
  final List<Schedule> selectedSchedules;

  const AttendanceStatus({super.key, required this.selectedSchedules});

  @override
  State<AttendanceStatus> createState() => _AttendanceStatusState();
}

class _AttendanceStatusState extends State<AttendanceStatus> {
  List<LeaveType> _leaveTypes = [];
  LeaveType? _selectedLeaveType;
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  void _loadLeaveTypes() {
    Modular.get<ScheduleBloc>().add(LoadLeaveTypes());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a leave type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // สร้าง leave forms จาก selected schedules
    final leaveForms = widget.selectedSchedules.map((schedule) {
      return LeaveForm(
        scheduleId: schedule.id,
        leaveTypeId: _selectedLeaveType!.id,
        explanation: _reasonController.text.trim(),
      );
    }).toList();

    final request = LeaveFormsRequest(leaves: leaveForms);

    // Log ข้อมูลที่จะส่ง
    debugPrint('📝 Submitting leave forms:');
    debugPrint(
      '   Schedule IDs: ${widget.selectedSchedules.map((s) => s.id).toList()}',
    );
    debugPrint(
      '   Leave Type: ${_selectedLeaveType!.displayName} (ID: ${_selectedLeaveType!.id})',
    );
    debugPrint('   Explanation: ${_reasonController.text}');
    debugPrint('   JSON: ${request.toJson()}');

    // ส่ง event ไปยัง BLoC
    Modular.get<ScheduleBloc>().add(SubmitLeaveForms(request));
  }

  void _handleSubmitSuccess() {
    // แสดง success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave forms submitted successfully! ✓'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // รอ 1 วินาทีแล้วกลับไปหน้าก่อนหน้า
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context, true); // ส่ง true กลับไปเพื่อบอกว่าส่งสำเร็จ
      }
    });
  }

  void _handleSubmitError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: Modular.get<ScheduleBloc>(),
      child: AppScaffold(
        title: 'Attendance Status',
        currentIndex: -1,
        showAvatar: false,
        body: BlocConsumer<ScheduleBloc, ScheduleState>(
          listener: (context, state) {
            // จัดการ leave types loaded
            if (state is LeaveTypesLoaded) {
              setState(() {
                _leaveTypes = state.leaveTypes;
                _isLoading = false;
              });
            } else if (state is LeaveTypesError) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
            // จัดการ submit states
            else if (state is LeaveFormsSubmitting) {
              setState(() {
                _isSubmitting = true;
              });
            } else if (state is LeaveFormsSubmitted) {
              setState(() {
                _isSubmitting = false;
              });
              _handleSubmitSuccess();
            } else if (state is LeaveFormsSubmitError) {
              setState(() {
                _isSubmitting = false;
              });
              _handleSubmitError(state.message);
            }
          },
          builder: (context, state) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected Schedules Section
                        Text(
                          'Selected Meetings (${widget.selectedSchedules.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color.AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: space.m),

                        // List of selected schedules
                        ...widget.selectedSchedules.map((schedule) {
                          final startTime = DateFormat(
                            'h:mm a',
                          ).format(schedule.startAt);
                          final endTime = DateFormat(
                            'h:mm a',
                          ).format(schedule.endAt);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  color: color.AppColors.warning,
                                  size: 20,
                                ),
                                SizedBox(width: space.s),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$startTime - $endTime',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (schedule.delegate?.company != null)
                                        Text(
                                          schedule.delegate!.company!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      Text(
                                        'Table ${schedule.tableNumber}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        SizedBox(height: space.l),

                        // Leave Type Dropdown
                        Text(
                          'Leave Type',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color.AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: space.s),

                        DropdownButtonFormField<LeaveType>(
                          decoration: InputDecoration(
                            labelText: 'Select leave type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          value: _selectedLeaveType,
                          items: _leaveTypes.where((type) => type.active).map((
                            LeaveType type,
                          ) {
                            return DropdownMenuItem<LeaveType>(
                              value: type,
                              child: Text(type.displayName),
                            );
                          }).toList(),
                          onChanged: (LeaveType? newValue) {
                            setState(() {
                              _selectedLeaveType = newValue;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Please select a leave type'
                              : null,
                        ),

                        SizedBox(height: space.l),

                        // Reason TextField
                        Text(
                          'Explanation',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color.AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: space.s),

                        TextFormField(
                          controller: _reasonController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Please provide details...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide an explanation';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: space.xl),

                        // Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Cancel',
                                backgroundColor: color.AppColors.background,
                                textColor: color.AppColors.textPrimary,
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                              ),
                            ),
                            SizedBox(width: space.xs),
                            Expanded(
                              child: AppButton(
                                text: _isSubmitting
                                    ? 'Submitting...'
                                    : 'Confirm',
                                backgroundColor: color.AppColors.primary,
                                textColor: color.AppColors.textOnPrimary,
                                onPressed: _isSubmitting
                                    ? null
                                    : _handleConfirm,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (_isSubmitting)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Submitting leave forms...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
