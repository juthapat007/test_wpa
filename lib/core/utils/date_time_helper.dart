// lib/core/utils/date_time_helper.dart

import 'package:intl/intl.dart';

class DateTimeHelper {
  // ========================================
  // UI Display Formats
  // ========================================

  /// "Mon, 5 Feb 2026"
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEE, d MMM yyyy').format(dateTime);
  }

  /// "9:30 AM"  — แสดงเวลาแบบ 12-hour บน UI
  static String formatTime12(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// "04:40 AM - 05:00 AM"
  static String formatTimeRange12(DateTime startAt, DateTime endAt) {
    final fmt = DateFormat('hh:mm a');
    return '${fmt.format(startAt.toLocal())} - ${fmt.format(endAt.toLocal())}';
  }

  /// "09:30–10:15"
  static String formatTimeRange24(DateTime startAt, DateTime endAt) {
    final fmt = DateFormat('HH:mm');
    return '${fmt.format(startAt)}–${fmt.format(endAt)}';
  }

  /// "Mon, 5 Feb 2026  •  09:30–10:15"
  static String formatDateTimeRange(
    DateTime date,
    DateTime startAt,
    DateTime endAt,
  ) {
    return '${formatFullDate(date)}  •  ${formatTimeRange24(startAt, endAt)}';
  }

  // ========================================
  // API Formats (ส่งให้ Backend)
  // ========================================

  /// "2026-02-05"
  static String formatApiDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// "9:30 AM"  — ใช้ส่ง query param และแสดง time slot
  static String formatApiTime12(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  // ========================================
  // Parsers
  // ========================================

  /// Parse ISO datetime string → local DateTime
  /// รองรับ "2026-02-05T09:00:00.000Z" (UTC) หรือ "2026-02-05T09:00:00" (local)
  static DateTime parseFlexibleDateTime(
    String timeString,
    String? conferenceDate,
  ) {
    final isoResult = DateTime.tryParse(timeString);
    if (isoResult != null) {
      return isoResult.toLocal();
    }

    // Fallback: ถ้ายังมี human time หลุดมา
    print('⚠️ DateTimeHelper: Unexpected non-ISO time "$timeString"');
    return DateTime.now();
  }

  /// Parse date string → DateTime ("2026-02-05" หรือ "05/02/2026")
  static DateTime parseSafeDate(String dateString) {
    final result = DateTime.tryParse(dateString);
    if (result != null) return result;

    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (_) {}

    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (_) {}

    print('⚠️ DateTimeHelper: Cannot parse date "$dateString", using now()');
    return DateTime.now();
  }

  // ========================================
  // Helper Methods
  // ========================================

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isFuture(DateTime date) => date.isAfter(DateTime.now());

  static bool isPast(DateTime date) => date.isBefore(DateTime.now());
}
