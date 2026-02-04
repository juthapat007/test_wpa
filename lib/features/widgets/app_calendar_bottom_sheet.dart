import 'package:flutter/material.dart';
import 'app_calendar.dart';

Future<void> showCalendarBottomSheet({
  required BuildContext context,
  required DateTime selectedDate,
  required ValueChanged<DateTime> onDateSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            AppCalendar(
              selectedDate: selectedDate,
              onDateSelected: (date) {
                onDateSelected(date);
                Navigator.of(context).pop(); // ปิด popup
              },
            ),
          ],
        ),
      );
    },
  );
}
