// lib/core/utils/date_time_helper.dart

import 'package:intl/intl.dart';

class DateTimeHelper {
  //  (สำหรับแสดงผลบน UI)

  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEE, d MMM yyyy').format(dateTime);
  }

  /// แสดงเวลาแบบ 24-hour: "09:30"
  static String formatTime24(DateTime dateTime) {
    return DateFormat(
      'HH:mm',
    ).format(dateTime); // 🔧 แก้เป็น HH:mm สำหรับ 24-hour จริงๆ
  }

  /// แสดงเวลาแบบ 12-hour + AM/PM: "9:30 AM"
  static String formatTime12(DateTime dateTime) {
    return DateFormat('h:mm ').format(dateTime); // มีเว้นวรรค สำหรับแสดงผล UI
  }

  /// แสดงช่วงเวลา 24-hour: "09:30–10:15"
  static String formatTimeRange24(DateTime startAt, DateTime endAt) {
    return '${formatTime24(startAt)}–${formatTime24(endAt)}';
  }

  /// แสดงช่วงเวลา 12-hour: "9:30 AM – 10:15 AM"
  static String formatTimeRange12(DateTime startAt, DateTime endAt) {
    return '${formatTime12(startAt)} – ${formatTime12(endAt)}';
  }

  /// แสดงวันที่ + ช่วงเวลา: "Mon, 5 Feb 2026  •  09:30–10:15"
  static String formatDateTimeRange(
    DateTime date,
    DateTime startAt,
    DateTime endAt,
  ) {
    return '${formatFullDate(date)}  •  ${formatTimeRange24(startAt, endAt)}';
  }

  // ========================================
  // API Formats (สำหรับส่ง API / Query)
  // ========================================

  /// Format วันที่สำหรับ API: "2026-02-05"
  static String formatApiDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Format เวลาสำหรับ API (12-hour + AM/PM ไม่มีเว้นวรรค): "9:30:AM"
  static String formatApiTime(DateTime dateTime) {
    return DateFormat(
      'h:mm:a',
    ).format(dateTime); // ใช้ 'h:mm:a' (มี colon, ไม่มีเว้นวรรค) → "10:01:AM"
  }

  /// Format เวลาสำหรับ API (12-hour + AM/PM มีเว้นวรรค): "9:30 AM"
  static String formatApiTime12(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  // ========================================
  // Deprecated Methods (เก็บไว้เพื่อ backward compatibility)
  // ========================================

  @Deprecated('Use formatTimeRange24() or formatTimeRange12() instead')
  static String formatTimeRange(DateTime startAt, DateTime endAt) {
    return formatTimeRange24(startAt, endAt);
  }

  @Deprecated('Use formatTime24() or formatTime12() instead')
  static String formatTime(DateTime dateTime) {
    return formatTime24(dateTime);
  }

  @Deprecated('Use formatApiDate() instead')
  static String formatUtcDate(DateTime dateTime) {
    return formatApiDate(dateTime);
  }

  @Deprecated('Use formatApiTime() instead')
  static String formatUtcTime(DateTime dateTime) {
    return formatApiTime(dateTime);
  }

  // ========================================
  // Smart Parsers (รองรับทั้ง ISO และ Human Time)
  // ========================================

  /// Parse time string ที่อาจเป็น ISO datetime หรือ human time เช่น "9:00 AM"
  /// ถ้าเป็น human time จะรวมกับ conferenceDate เพื่อสร้าง DateTime ที่สมบูรณ์
  static DateTime parseFlexibleDateTime(
    String timeString,
    String? conferenceDate,
  ) {
    // 1. ลอง ISO datetime ก่อน (เช่น "2025-02-05T09:00:00.000Z")
    final isoResult = DateTime.tryParse(timeString);
    if (isoResult != null) return isoResult;

    // 2. ถ้าไม่ใช่ ISO ให้ parse เป็น human time (เช่น "9:00 AM", "9:00:AM")
    return _parseHumanTime(timeString, conferenceDate);
  }

  /// Parse human time string เช่น "9:00 AM", "9:00:AM", "10:30 PM"
  /// รวมกับ conferenceDate (เช่น "2025-02-05") เพื่อสร้าง DateTime
  static DateTime _parseHumanTime(String timeStr, String? conferenceDate) {
    // Normalize: เปลี่ยน "9:00:AM" -> "9:00 AM"
    String normalized = timeStr.trim();
    // จัดการ format "h:mm:a" (colon ก่อน AM/PM)
    final colonAmPmRegex = RegExp(
      r'(\d{1,2}:\d{2}):(AM|PM)',
      caseSensitive: false,
    );
    final colonMatch = colonAmPmRegex.firstMatch(normalized);
    if (colonMatch != null) {
      normalized = '${colonMatch.group(1)} ${colonMatch.group(2)}';
    }

    // Parse ด้วย intl
    try {
      final timeOnly = DateFormat('h:mm a').parse(normalized);

      // สร้าง base date จาก conferenceDate หรือใช้วันนี้
      DateTime baseDate;
      if (conferenceDate != null && conferenceDate.isNotEmpty) {
        baseDate = DateTime.tryParse(conferenceDate) ?? DateTime.now();
      } else {
        baseDate = DateTime.now();
      }

      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        timeOnly.hour,
        timeOnly.minute,
      );
    } catch (e) {
      // Fallback: ถ้า parse ไม่ได้เลย ใช้วันนี้
      print('⚠️ DateTimeHelper: Cannot parse time "$timeStr", using now()');
      return DateTime.now();
    }
  }

  /// Parse date string ที่อาจเป็น ISO date หรือ format อื่น
  /// Safety wrapper รอบ DateTime.parse
  static DateTime parseSafeDate(String dateString) {
    final result = DateTime.tryParse(dateString);
    if (result != null) return result;

    // ลอง format อื่นๆ
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

  /// เช็คว่าเป็นวันเดียวกันหรือไม่
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// เช็คว่าเป็นวันนี้หรือไม่
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// เช็คว่าเป็นอนาคตหรือไม่
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// เช็คว่าเป็นอดีตหรือไม่
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }
}
