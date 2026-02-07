import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:intl/intl.dart';

enum EventCardType { meeting, empty, breakTime }

enum LeaveStatus { onLeave, available }

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

  bool _isOnLeave() {
    return schedule.leave != null;
  }

  bool _isEvent() {
    return schedule.type == 'event';
  }

  bool _isUnknownDelegate() {
    // ✅ ตรวจสอบว่า delegate เป็น unknown หรือไม่
    final delegate = schedule.delegate;
    if (delegate == null) return true;
    if (delegate.id == null) return true;
    if (delegate.name?.toLowerCase() == 'unknown') return true;
    if (delegate.company?.toLowerCase() == 'n/a') return true;
    return false;
  }

  Color _getStatusColor() {
    // ✨ เพิ่มเช็ค leave ก่อน
    if (_isOnLeave()) {
      return Colors.red[600]!;
    }

    // ✨ เพิ่มเช็ค event (break time)
    if (_isEvent() || schedule.tableNumber.isEmpty) {
      return Colors.amber[600]!;
    }

    // ✅ ถ้า delegate เป็น unknown = สีเทา
    if (_isUnknownDelegate()) {
      return Colors.grey[600]!;
    }

    final now = DateTime.now();
    if (schedule.endAt.isBefore(now)) {
      return Colors.green[600]!;
    } else if (schedule.startAt.isBefore(now) && schedule.endAt.isAfter(now)) {
      return const Color(0xFF4F46E5);
    } else {
      return Colors.orange[600]!;
    }
  }

  String _getStatusText() {
    if (_isOnLeave()) {
      return 'LEAVE';
    }

    // ✨ เพิ่มเช็ค event (break time)
    if (_isEvent() || schedule.tableNumber.isEmpty) {
      return 'BREAK';
    }

    // ✅ ถ้า delegate เป็น unknown = TBD (To Be Determined)
    if (_isUnknownDelegate()) {
      return 'TBD';
    }

    final now = DateTime.now();
    if (schedule.endAt.isBefore(now)) {
      return 'PASSED';
    } else if (schedule.startAt.isBefore(now) && schedule.endAt.isAfter(now)) {
      return 'ONGOING';
    } else {
      return 'UPCOMING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final startTime = DateFormat('HH:mm').format(schedule.startAt.toLocal());
    final endTime = DateFormat('HH:mm').format(schedule.endAt.toLocal());
    final statusColor = _getStatusColor();
    final isBreakTime = _isEvent() || schedule.tableNumber.isEmpty;
    final isUnknown = _isUnknownDelegate();
    final isOnLeave = _isOnLeave();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnLeave
            ? Colors.red[50]
            : isBreakTime
            ? Colors.amber[50]
            : isUnknown
            ? Colors.grey[100]
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isOnLeave
            ? Border.all(
                color: Colors.red[200]!,
                width: 2,
              ) // ✨ เพิ่ม border สีแดง
            : isBreakTime
            ? Border.all(color: Colors.amber[200]!, width: 2)
            : isUnknown
            ? Border.all(color: Colors.grey[300]!, width: 2)
            : null,
        // border: isBreakTime
        //     ? Border.all(color: Colors.red[200]!, width: 2)
        //     : isBreakTime
        //     ? Border.all(color: Colors.amber[200]!, width: 2)
        //     : isUnknown
        //     ? Border.all(color: Colors.grey[300]!, width: 2)
        //     : null,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$startTime - $endTime ',
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // ✅ แสดง Table number เฉพาะเมื่อไม่ใช่ Break Time
                  if (!isBreakTime)
                    Text(
                      'Table ${schedule.tableNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isUnknown
                            ? Colors.grey[500]
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  // ✅ แสดง "Break Time" เมื่อเป็น Break
                  if (isBreakTime)
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
                ],
              ),
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
          // ✅ แสดงข้อมูลบริษัทเฉพาะเมื่อไม่ใช่ Break Time
          if (!isBreakTime) ...[
            // ✅ แสดงข้อความพิเศษสำหรับ Unknown Delegate
            if (isUnknown)
              Row(
                children: [
                  Icon(Icons.help_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Waiting for confirmation',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                schedule.delegate?.company ?? 'No company',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              if (schedule.delegate?.name != null) ...[
                const SizedBox(height: 4),
                Text(
                  schedule.delegate!.name!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              if (schedule.country.isNotEmpty) ...[
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
          ],
          // ✅ แสดงข้อความพิเศษสำหรับ Break Time
          if (isBreakTime)
            Text(
              'Rest and recharge',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.amber[700],
              ),
            ),
        ],
      ),
    );
  }
}

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
