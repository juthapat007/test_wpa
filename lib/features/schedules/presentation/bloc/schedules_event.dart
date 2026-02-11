import 'package:flutter/foundation.dart';

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
