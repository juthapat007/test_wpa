// lib/features/meeting/presentation/bloc/table_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/domain/repositories/table_repository.dart';

part 'table_event.dart';
part 'table_state.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  final TableRepository tableRepository;

  TableBloc({required this.tableRepository}) : super(TableInitial()) {
    on<LoadTableView>(_onLoadTableView);
    on<ChangeTimeSlot>(_onChangeTimeSlot);
    on<ChangeDate>(_onChangeDate);
  }

  // Future<void> _onLoadTableView(
  //   LoadTableView event,
  //   Emitter<TableState> emit,
  // ) async {
  //   emit(TableLoading());
  //   try {
  //     final response = await tableRepository.getTableView(
  //       date: event.date,
  //       time: event.time,
  //     );
  //     emit(TableLoaded(response));
  //   } catch (e) {
  //     print('TableBloc error: $e');
  //     emit(TableError('Cannot load table view: $e'));
  //   }
  // }
  // ที่ table_bloc.dart
  Future<void> _onLoadTableView(
    LoadTableView event,
    Emitter<TableState> emit,
  ) async {
    print('📥 TableBloc: Loading with date=${event.date}, time=${event.time}');
    emit(TableLoading());
    try {
      final response = await tableRepository.getTableView(
        date: event.date,
        time: event.time,
      );
      print('✅ TableBloc: Loaded ${response.tables.length} tables');
      print('✅ TableBloc: myTable = ${response.myTable}');
      print('✅ TableBloc: Emitting TableLoaded state');
      emit(TableLoaded(response));
    } catch (e) {
      print('❌ TableBloc error: $e');
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
    } catch (e) {
      emit(TableError('Cannot change time slot: $e'));
    }
  }

  Future<void> _onChangeDate(ChangeDate event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      final response = await tableRepository.getTableView(date: event.date);
      emit(TableLoaded(response));
    } catch (e) {
      emit(TableError('Cannot change date: $e'));
    }
  }
}
