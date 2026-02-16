// lib/features/schedules/domain/entities/leave_form.dart

class LeaveForm {
  final int scheduleId;
  final int leaveTypeId;
  final String explanation;

  const LeaveForm({
    required this.scheduleId,
    required this.leaveTypeId,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'leave_type_id': leaveTypeId,
      'explanation': explanation,
    };
  }
}

class LeaveFormsRequest {
  final List<LeaveForm> leaves;

  const LeaveFormsRequest({required this.leaves});

  Map<String, dynamic> toJson() {
    return {'leaves': leaves.map((leave) => leave.toJson()).toList()};
  }
}

class LeaveFormResponse {
  final bool success;
  final String message;
  final dynamic data;

  const LeaveFormResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LeaveFormResponse.fromJson(Map<String, dynamic> json) {
    return LeaveFormResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Leave forms submitted successfully',
      data: json['data'],
    );
  }
}
