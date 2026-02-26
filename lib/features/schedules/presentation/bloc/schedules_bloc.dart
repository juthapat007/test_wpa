import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository scheduleRepository;

  ScheduleBloc({required this.scheduleRepository}) : super(ScheduleInitial()) {
    on<LoadSchedules>(_onLoadSchedules);
    on<ChangeDate>(_onChangeDate);
    on<LoadLeaveTypes>(_onLoadLeaveTypes);
    on<SubmitLeaveForms>(_onSubmitLeaveForms);
  }

  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<ScheduleState> emit,
  ) async {
    print('ScheduleBloc: Loading with date=${event.date}'); //  ลบ year ออก
    emit(ScheduleLoading());

    try {
      final scheduleResponse = await scheduleRepository.getSchedule(
        date: event.date,
      );

      print(
        '✅ ScheduleBloc: Loaded ${scheduleResponse.schedules.length} schedules',
      );
      print('✅ ScheduleBloc: Status = ${scheduleResponse.status}');

      emit(ScheduleLoaded(scheduleResponse));
    } catch (e, stackTrace) {
      print('❌ ScheduleBloc error: $e');
      print('❌ StackTrace: $stackTrace');
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

  Future<void> _onLoadLeaveTypes(
    LoadLeaveTypes event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      final leaveTypes = await scheduleRepository.getLeaveTypes();
      print('✅ ScheduleBloc: Loaded ${leaveTypes.length} leave types');
      emit(LeaveTypesLoaded(leaveTypes));
    } catch (e) {
      print('❌ ScheduleBloc error loading leave types: $e');
      emit(LeaveTypesError('Cannot load leave types: $e'));
    }
  }

  Future<void> _onSubmitLeaveForms(
    SubmitLeaveForms event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(LeaveFormsSubmitting());

    try {
      print('📤 ScheduleBloc: Submitting leave forms...');

      final response = await scheduleRepository.submitLeaveForms(event.request);

      if (response.success) {
        print('✅ ScheduleBloc: Leave forms submitted successfully');
        emit(LeaveFormsSubmitted(response));
      } else {
        print('❌ ScheduleBloc: Submit failed: ${response.message}');
        emit(LeaveFormsSubmitError(response.message));
      }
    } catch (e) {
      print('❌ ScheduleBloc error submitting leave forms: $e');
      emit(LeaveFormsSubmitError('Failed to submit leave forms: $e'));
    }
  }
}
