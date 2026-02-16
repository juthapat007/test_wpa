import 'package:flutter/foundation.dart';
import 'package:test_wpa/features/schedules/domain/entities/leave_form.dart';

@immutable
sealed class ScheduleEvent {}

class LoadSchedules extends ScheduleEvent {
  final String? date;

  LoadSchedules({this.date});
}

class ChangeDate extends ScheduleEvent {
  final String date;

  ChangeDate(this.date);
}

class LoadLeaveTypes extends ScheduleEvent {}

class SubmitLeaveForms extends ScheduleEvent {
  final LeaveFormsRequest request;

  SubmitLeaveForms(this.request);
}
