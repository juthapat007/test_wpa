// lib/features/meeting/presentation/bloc/table_state.dart

part of 'table_bloc.dart';

@immutable
sealed class TableState {}

final class TableInitial extends TableState {}

final class TableLoading extends TableState {}

final class TableLoaded extends TableState {
  final TableViewResponse response;

  TableLoaded(this.response);
}

final class TableError extends TableState {
  final String message;

  TableError(this.message);
}