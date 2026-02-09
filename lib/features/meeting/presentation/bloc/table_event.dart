// lib/features/meeting/presentation/bloc/table_event.dart

part of 'table_bloc.dart';

@immutable
sealed class TableEvent {}

class LoadTableView extends TableEvent {
  final String? date;
  final String? time;

  LoadTableView({this.date, this.time});
}

class ChangeTimeSlot extends TableEvent {
  final String time;

  ChangeTimeSlot(this.time);
}

class ChangeDate extends TableEvent {
  final String date;

  ChangeDate(this.date);
}
