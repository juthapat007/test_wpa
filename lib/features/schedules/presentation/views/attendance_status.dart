import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
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
  // Attendance status options
  final List<String> _statusOptions = [
    'Unable to Attend',
    'Will Be Late',
    'Need to Reschedule',
    'Other',
  ];

  String? _selectedStatus;
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_formKey.currentState!.validate()) {
      // TODO: เรียก API เพื่ออัปเดตสถานะการเข้าร่วม
      final scheduleIds = widget.selectedSchedules.map((s) => s.id).toList();

      debugPrint('📝 Updating attendance status:');
      debugPrint('   Schedule IDs: $scheduleIds');
      debugPrint('   Status: $_selectedStatus');
      debugPrint('   Reason: ${_reasonController.text}');

      // แสดง success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // กลับไปหน้าก่อนหน้า
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Attendance Status',
      currentIndex: -1,
      showAvatar: false,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          120, // 👈 เว้นพื้นที่ให้ปุ่ม
        ),
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
                final startTime = DateFormat('h:mm a').format(schedule.startAt);
                final endTime = DateFormat('h:mm a').format(schedule.endAt);

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
                          crossAxisAlignment: CrossAxisAlignment.start,
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

              // Status Dropdown
              Text(
                'Attendance Status',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color.AppColors.textPrimary,
                ),
              ),
              SizedBox(height: space.s),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                initialValue: _selectedStatus,
                items: _statusOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a status' : null,
              ),

              SizedBox(height: space.l),

              // Reason TextField
              Text(
                'Reason',
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
                    return 'Please provide a reason';
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: space.xs),
                  Expanded(
                    child: AppButton(
                      text: 'Confirm',
                      backgroundColor: color.AppColors.primary,
                      textColor: color.AppColors.textOnPrimary,
                      onPressed: _handleConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
