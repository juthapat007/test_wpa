import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/schedules/data/services/schedule_others_api.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule_others_response.dart';
import 'package:test_wpa/features/schedules/domain/repositories/schedule_others_repository.dart';

class ScheduleOthersRepositoryImpl implements ScheduleOthersRepository {
  final ScheduleOthersApi api;

  ScheduleOthersRepositoryImpl({required this.api});

  @override
  Future<ScheduleOthersResponse> getScheduleOthers(
    int delegateId, {
    String? date,
  }) async {
    try {
      final json = await api.getScheduleOthers(delegateId, date: date);

      final rawDates = json['available_dates'] as List<dynamic>? ?? [];
      final availableDates = rawDates.map((d) => d.toString()).toList();

      final selectedDate = (json['date'] as String?) ?? '';

      final rawSchedules = json['schedules'] as List<dynamic>? ?? [];
      final schedules = rawSchedules
          .map((s) => _parseSchedule(s as Map<String, dynamic>))
          .toList();

      return ScheduleOthersResponse(
        availableDates: availableDates,
        selectedDate: selectedDate,
        schedules: schedules,
      );
    } catch (e) {
      print(' ScheduleOthersRepositoryImpl error: $e');
      throw Exception('Failed to load schedule others: $e');
    }
  }

  Schedule _parseSchedule(Map<String, dynamic> s) {
    final conferenceDate = s['conference_date'] as String? ?? '';
    final delegateJson = s['delegate'] as Map<String, dynamic>?;
    final teamJson = s['team_delegates'] as List<dynamic>?;

    return Schedule(
      id: s['id'] as int? ?? 0,
      type: s['type'] as String?,
      title: s['title'] as String?,
      startAt: DateTimeHelper.parseFlexibleDateTime(
        s['start_at'] as String,
        conferenceDate,
      ),
      endAt: DateTimeHelper.parseFlexibleDateTime(
        s['end_at'] as String,
        conferenceDate,
      ),
      tableNumber: s['table_number'] as String?,
      country: s['country'] as String? ?? '',
      conferenceDate: conferenceDate,
      durationMinutes: s['duration_minutes'] as int?,
      leave: s['leave'],
      delegate: delegateJson != null
          ? ScheduleDelegate(
              id: delegateJson['id'] as int?,
              name: delegateJson['name'] as String?,
              company: delegateJson['company'] as String?,
            )
          : null,
      teamDelegates: teamJson?.map((t) {
        final tm = t as Map<String, dynamic>;
        return TeamDelegate(
          id: tm['id'] as int,
          name: tm['name'] as String? ?? '',
          company: tm['company'] as String? ?? '',
        );
      }).toList(),
    );
  }
}
