import 'package:flutter/foundation.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';



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