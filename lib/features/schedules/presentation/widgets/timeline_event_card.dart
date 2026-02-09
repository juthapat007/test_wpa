import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:intl/intl.dart';

enum EventCardType { meeting, empty, breakTime }

class TimelineEventCard extends StatelessWidget {
  final Schedule? schedule;
  final EventCardType type;

  const TimelineEventCard({super.key, this.schedule, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case EventCardType.meeting:
        return _MeetingCard(schedule: schedule!);
      case EventCardType.empty:
        return const _EmptySlotCard();
      case EventCardType.breakTime:
        return const _BreakTimeCard();
    }
  }
}

class _MeetingCard extends StatelessWidget {
  final Schedule schedule;

  const _MeetingCard({required this.schedule});

  // ========================================
  // ✅ การจำแนกประเภท
  // ========================================

  // 1️⃣ ลา
  bool _isOnLeave() {
    return schedule.leave != null;
  }

  // 2️⃣ Event (Break Time, Coffee, Lunch, etc.)
  bool _isEvent() {
    return schedule.type == 'event';
  }

  // 3️⃣ No Meeting (ไม่มี meeting แต่ยังเป็นช่วงเวลาที่ว่าง)
  bool _isNoMeeting() {
    return schedule.type == 'nomeeting';
  }

  // 4️⃣ Meeting ปกติ
  bool _isMeeting() {
    return schedule.type == 'meeting';
  }

  // ========================================
  // ✅ สีและสถานะ
  // ========================================

  Color _getStatusColor() {
    // 1️⃣ ลา → สีแดง
    if (_isOnLeave()) {
      return Colors.red[600]!;
    }

    // 2️⃣ Event → สีเหลือง/ส้ม
    if (_isEvent()) {
      return Colors.amber[600]!;
    }

    // 3️⃣ No Meeting → สีเทาอ่อน
    if (_isNoMeeting()) {
      return Colors.grey[400]!;
    }

    // 4️⃣ Meeting ปกติ → ดูตามเวลา
    final now = DateTime.now();
    if (schedule.endAt.isBefore(now)) {
      return Colors.green[600]!; // ผ่านไปแล้ว
    } else if (schedule.startAt.isBefore(now) && schedule.endAt.isAfter(now)) {
      return const Color(0xFF4F46E5); // กำลังเกิดขึ้น
    } else {
      return Colors.orange[600]!; // ยังไม่ถึง
    }
  }

  String _getStatusText() {
    if (_isOnLeave()) return 'LEAVE';
    if (_isEvent()) return 'BREAK';
    if (_isNoMeeting()) return 'FREE';

    final now = DateTime.now();
    if (schedule.endAt.isBefore(now)) {
      return 'PASSED';
    } else if (schedule.startAt.isBefore(now) && schedule.endAt.isAfter(now)) {
      return 'ONGOING';
    } else {
      return 'UPCOMING';
    }
  }

  Color _getBackgroundColor() {
    if (_isOnLeave()) return Colors.red[50]!;
    if (_isEvent()) return Colors.amber[50]!;
    if (_isNoMeeting()) return Colors.grey[50]!;
    return Colors.white;
  }

  Border? _getBorder() {
    if (_isOnLeave()) return Border.all(color: Colors.red[200]!, width: 2);
    if (_isEvent()) return Border.all(color: Colors.amber[200]!, width: 2);
    if (_isNoMeeting()) return Border.all(color: Colors.grey[300]!, width: 2);
    return null;
  }

  // ========================================
  // ✅ ดึงข้อมูล Delegates
  // ========================================

  String _getDelegateInfo() {
    // Event
    if (_isEvent()) {
      return schedule.title ?? 'Event';
    }

    // No Meeting
    if (_isNoMeeting()) {
      final teamDelegates = schedule.teamDelegates;
      if (teamDelegates == null || teamDelegates.isEmpty) {
        return 'Free time';
      }
      // แสดงชื่อคนแรก (หรือทั้งหมดถ้าต้องการ)
      return teamDelegates.map((d) => d.name).join(', ');
    }

    // Meeting
    if (_isMeeting()) {
      final teamDelegates = schedule.teamDelegates;
      if (teamDelegates == null || teamDelegates.isEmpty) {
        return 'Unknown';
      }
      return teamDelegates.first.company;
    }

    return 'N/A';
  }

  String? _getDelegateName() {
    if (!_isMeeting()) return null;

    final teamDelegates = schedule.teamDelegates;
    if (teamDelegates == null || teamDelegates.isEmpty) return null;

    return teamDelegates.map((d) => d.name).join(', ');
  }

  // ========================================
  // ✅ UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    final startTime = DateFormat('HH:mm').format(schedule.startAt.toLocal());
    final endTime = DateFormat('HH:mm').format(schedule.endAt.toLocal());
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(10),
        border: _getBorder(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== Header Row ==========
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // เวลา
                  Text(
                    '$startTime - $endTime',
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  // Table number หรือ icon
                  if (_isMeeting() && schedule.tableNumber != null)
                    Text(
                      'Table ${schedule.tableNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  if (_isEvent())
                    Row(
                      children: [
                        Icon(
                          Icons.coffee_outlined,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Break Time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                  if (_isNoMeeting())
                    Row(
                      children: [
                        Icon(
                          Icons.free_breakfast,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Free Time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ========== Content ==========

          // ข้อมูลหลัก (Company/Title/Name)
          Text(
            _getDelegateInfo(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),

          // ชื่อ delegate (ถ้ามี)
          if (_getDelegateName() != null) ...[
            const SizedBox(height: 4),
            Text(
              _getDelegateName()!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],

          // Country (ถ้ามี)
          if (schedule.country.isNotEmpty && _isMeeting()) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.flag, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  schedule.country,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ========================================
// Empty Slot & Break Time Cards
// ========================================

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: Colors.grey[200]!),
      child: Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          'No Meeting',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 18,
            color: Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

class _BreakTimeCard extends StatelessWidget {
  const _BreakTimeCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: Colors.amber[200]!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.amber[50]?.withOpacity(0.3)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Break',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 20,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: Colors.amber[700],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.amber[100]?.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.coffee_outlined,
                color: Colors.amber[700],
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (var metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
