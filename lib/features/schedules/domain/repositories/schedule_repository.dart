import 'package:test_wpa/features/schedules/domain/entities/leave_form.dart';
import 'package:test_wpa/features/schedules/domain/entities/leave_type.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';

abstract class ScheduleRepository {
  Future<ScheduleResponse> getSchedule({String? year, String? date});
  Future<List<LeaveType>> getLeaveTypes();
  Future<LeaveFormResponse> submitLeaveForms(LeaveFormsRequest request);
}
