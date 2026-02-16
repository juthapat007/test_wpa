import 'package:flutter/foundation.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/entities/leave_type.dart';
import 'package:test_wpa/features/schedules/domain/entities/leave_form.dart';

@immutable
sealed class ScheduleState {}

final class ScheduleInitial extends ScheduleState {}

final class ScheduleLoading extends ScheduleState {}

final class ScheduleLoaded extends ScheduleState {
  final ScheduleResponse scheduleResponse;

  ScheduleLoaded(this.scheduleResponse);
}

final class ScheduleError extends ScheduleState {
  final String message;

  ScheduleError(this.message);
}

final class LeaveTypesLoaded extends ScheduleState {
  final List<LeaveType> leaveTypes;

  LeaveTypesLoaded(this.leaveTypes);
}

final class LeaveTypesError extends ScheduleState {
  final String message;

  LeaveTypesError(this.message);
}

final class LeaveFormsSubmitting extends ScheduleState {}

final class LeaveFormsSubmitted extends ScheduleState {
  final LeaveFormResponse response;

  LeaveFormsSubmitted(this.response);
}

final class LeaveFormsSubmitError extends ScheduleState {
  final String message;

  LeaveFormsSubmitError(this.message);
}
