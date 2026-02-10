import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository scheduleRepository;

  ScheduleBloc({required this.scheduleRepository}) : super(ScheduleInitial()) {
    on<LoadSchedules>(_onLoadSchedules);
    on<ChangeDate>(_onChangeDate);
  }

  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    try {
      final scheduleResponse = await scheduleRepository.getSchedule(
        year: event.year,
        date: event.date,
      );
      emit(ScheduleLoaded(scheduleResponse));
    } catch (e) {
      print('ScheduleBloc error: $e');
      emit(ScheduleError('Cannot load schedules: $e'));
    }
  }

  Future<void> _onChangeDate(
    ChangeDate event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    try {
      final scheduleResponse = await scheduleRepository.getSchedule(
        date: event.date,
      );
      emit(ScheduleLoaded(scheduleResponse));
    } catch (e) {
      print('ScheduleBloc error: $e');
      emit(ScheduleError('Cannot load schedules: $e'));
    }
  }
}
