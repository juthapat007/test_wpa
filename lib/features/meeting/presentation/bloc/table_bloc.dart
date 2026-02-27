import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/domain/repositories/table_repository.dart';

part 'table_event.dart';
part 'table_state.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  final TableRepository tableRepository;

  TableBloc({required this.tableRepository}) : super(TableInitial()) {
    on<LoadTableView>(_onLoadTableView, transformer: droppable());
    on<ChangeTimeSlot>(_onChangeTimeSlot, transformer: droppable());
    on<ChangeDate>(_onChangeDate, transformer: droppable());
  }

  Future<void> _onLoadTableView(
    LoadTableView event,
    Emitter<TableState> emit,
  ) async {
    emit(TableLoading());
    try {
      final response = await tableRepository.getTableView(
        date: event.date,
        time: event.time,
      );
      emit(TableLoaded(response));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(TableError('Cannot load table view: $e'));
    }
  }

  Future<void> _onChangeTimeSlot(
    ChangeTimeSlot event,
    Emitter<TableState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TableLoaded) return;

    emit(TableLoading());
    try {
      final response = await tableRepository.getTableView(
        date: currentState.response.date,
        time: event.time,
      );
      emit(TableLoaded(response));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(TableError('Cannot change time slot: $e'));
    }
  }

  Future<void> _onChangeDate(ChangeDate event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      final response = await tableRepository.getTableView(date: event.date);
      emit(TableLoaded(response));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(TableError('Cannot change date: $e'));
    }
  }
}
