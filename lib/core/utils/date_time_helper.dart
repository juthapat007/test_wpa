// lib/core/utils/date_time_helper.dart

import 'package:intl/intl.dart';

class DateTimeHelper {
  /// แสดงช่วงเวลา เช่น 09:30 - 10:15
  static String formatTimeRange(DateTime startAt, DateTime endAt) {
    final start = startAt.toUtc();
    final end = endAt.toUtc();

    final formatter = DateFormat('HH:mm a');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  /// แสดงเวลาเดี่ยว เช่น 09:30
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm a').format(dateTime.toUtc());
  }

  /// สำหรับส่ง API / query
  static String formatUtcDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime.toUtc());
  }

  static String formatUtcTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime.toUtc());
  }
}
