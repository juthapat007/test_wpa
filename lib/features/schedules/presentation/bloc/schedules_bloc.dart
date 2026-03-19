import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_event.dart';
import 'package:test_wpa/features/schedules/presentation/bloc/schedules_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository scheduleRepository;

  ScheduleBloc({required this.scheduleRepository}) : super(ScheduleInitial()) {
    on<LoadSchedules>(_onLoadSchedules, transformer: droppable());
    on<ChangeDate>(_onChangeDate, transformer: droppable());
    on<LoadLeaveTypes>(_onLoadLeaveTypes, transformer: droppable());
    on<SubmitLeaveForms>(_onSubmitLeaveForms);
  }

  // Future<void> _onLoadSchedules(
  //   LoadSchedules event,
  //   Emitter<ScheduleState> emit,
  // ) async {
  //   emit(ScheduleLoading());
  //   try {
  //     final response = await scheduleRepository.getSchedule(date: event.date);
  //     emit(ScheduleLoaded(response));
  //   } catch (e, stackTrace) {
  //     addError(e, stackTrace);
  //     emit(ScheduleError('Cannot load schedules: $e'));
  //   }
  // }

  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<ScheduleState> emit,
  ) async {
    final prevDates = state is ScheduleLoaded
        ? (state as ScheduleLoaded).scheduleResponse.availableDates
        : <String>[];

    emit(ScheduleLoading());
    try {
      final response = await scheduleRepository.getSchedule(date: event.date);

      final finalResponse =
          response.availableDates.isEmpty && prevDates.isNotEmpty
          ? ScheduleResponse(
              status: response.status,
              availableYears: response.availableYears,
              year: response.year,
              availableDates: prevDates,
              date: response.date,
              schedules: response.schedules,
              message: response.message,
            )
          : response;

      // ✅ เลือก selectedDate ที่ถูกต้อง
      final dates = finalResponse.availableDates;
      final selectedDate = event.date != null && dates.contains(event.date)
          ? event.date!
          : dates.isNotEmpty
          ? dates
                .first // ← ใช้วันแรกเสมอถ้าไม่ได้ระบุ
          : finalResponse.date;

      emit(ScheduleLoaded(finalResponse, selectedDate: selectedDate));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(ScheduleError('Cannot load schedules: $e'));
    }
  }

  Future<void> _onChangeDate(
    ChangeDate event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    try {
      final response = await scheduleRepository.getSchedule(date: event.date);
      emit(ScheduleLoaded(response));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(ScheduleError('Cannot load schedules: $e'));
    }
  }

  Future<void> _onLoadLeaveTypes(
    LoadLeaveTypes event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      final leaveTypes = await scheduleRepository.getLeaveTypes();
      emit(LeaveTypesLoaded(leaveTypes));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(LeaveTypesError('Cannot load leave types: $e'));
    }
  }

  Future<void> _onSubmitLeaveForms(
    SubmitLeaveForms event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(LeaveFormsSubmitting());
    try {
      final response = await scheduleRepository.submitLeaveForms(event.request);
      if (response.success) {
        emit(LeaveFormsSubmitted(response));
      } else {
        emit(LeaveFormsSubmitError(response.message));
      }
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(LeaveFormsSubmitError('Failed to submit leave forms: $e'));
    }
  }
}
