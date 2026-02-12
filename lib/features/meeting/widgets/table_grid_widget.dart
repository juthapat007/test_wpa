// lib/features/meeting/widgets/table_grid_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/widgets/table_detail_sheet.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_card_helper.dart';

class TableGridWidget extends StatefulWidget {
  final TableViewResponse response;
  final Schedule? currentSchedule;
  final ValueChanged<String>? onTimeSlotChanged;
  final List<Schedule>? schedules; // เพิ่ม schedules

  const TableGridWidget({
    super.key,
    required this.response,
    this.currentSchedule,
    this.onTimeSlotChanged,
    this.schedules, // เพิ่มใน constructor
  });

  @override
  State<TableGridWidget> createState() => _TableGridWidgetState();
}

class _TableGridWidgetState extends State<TableGridWidget> {
  String? selectedTableNumber;
  final TransformationController _transformController =
      TransformationController();
  double _currentScale = 1.0;
  bool _showZoomControls = true;
  Timer? _hideControlsTimer;

  @override
  void dispose() {
    _transformController.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale * 1.2).clamp(0.5, 4.0);
      _transformController.value = Matrix4.identity()..scale(_currentScale);
      _showZoomControls = true;
    });
    _resetHideTimer();
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale / 1.2).clamp(0.5, 4.0);
      _transformController.value = Matrix4.identity()..scale(_currentScale);
      _showZoomControls = true;
    });
    _resetHideTimer();
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformController.value = Matrix4.identity();
      _showZoomControls = true;
    });
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showZoomControls = false;
        });
      }
    });
  }

  void _onInteractionStart() {
    setState(() {
      _showZoomControls = true;
    });
    _hideControlsTimer?.cancel();
  }

  void _onInteractionEnd() {
    _resetHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTimeHelper.parseSafeDate(widget.response.date);
    final hasNoTable = widget.response.myTable.isEmpty;

    // Split regular tables and booths
    final regularTables = widget.response.tables
        .where((t) => !t.tableNumber.contains('Booth'))
        .toList();

    final booths = widget.response.tables
        .where((t) => t.tableNumber.contains('Booth'))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // -- Time Slot Header --
          _buildTimeSlotHeader(),
          const SizedBox(height: 12),

          // -- Table Grid (constrained height + pinch-to-zoom) --
          if (hasNoTable)
            _buildNoTableSection(selectedDate, widget.response.time)
          else ...[
            _buildZoomableGrid(regularTables),
            const SizedBox(height: 12),
            _buildLegend(),
            if (booths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Booths',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...booths.map(_buildBoothCard),
            ],
          ],
        ],
      ),
    );
  }

  // ========================================
  // Time Slot Header with popup selector
  // ========================================
  Widget _buildTimeSlotHeader() {
    final currentTime = widget.response.time;
    final timesToday = widget.response.timesToday;
    final dateText = DateTimeHelper.formatFullDate(
      DateTimeHelper.parseSafeDate(widget.response.date),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: color.AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dateText  |  $currentTime',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.AppColors.textPrimary,
              ),
            ),
          ),
          if (timesToday.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showTimeSlotPopup(timesToday, currentTime),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: color.AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Slots',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color.AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ========================================
  // Time Slot Popup
  // ========================================
  void _showTimeSlotPopup(List<String> timesToday, String currentTime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Time Slot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a time to view table assignments',
                        style: TextStyle(
                          fontSize: 13,
                          color: color.AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: timesToday.map((time) {
                          final isSelected = time == currentTime;

                          // Find schedule for this time slot to get status
                          final scheduleForTime = _findScheduleForTime(time);
                          final helper = scheduleForTime != null
                              ? ScheduleCardHelper(scheduleForTime)
                              : null;

                          // Determine colors based on schedule status
                          Color backgroundColor;
                          Color borderColor;
                          Color textColor;

                          if (isSelected) {
                            backgroundColor = color.AppColors.primary;
                            borderColor = color.AppColors.primary;
                            textColor = Colors.white;
                          } else if (helper != null) {
                            // Use status colors from helper
                            backgroundColor = helper.backgroundColor;
                            borderColor = helper.statusColor;
                            textColor = helper.statusColor;
                          } else {
                            // Default colors for slots without schedule
                            backgroundColor = Colors.grey[100]!;
                            borderColor = color.AppColors.border;
                            textColor = color.AppColors.textPrimary;
                          }

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                widget.onTimeSlotChanged?.call(time);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: borderColor,
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    if (helper != null && !isSelected) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        helper.statusText,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: helper.statusColor.withOpacity(
                                            0.7,
                                          ),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to find schedule for a specific time
  Schedule? _findScheduleForTime(String time) {
    if (widget.schedules == null || widget.schedules!.isEmpty) {
      return null;
    }

    try {
      return widget.schedules!.firstWhere((schedule) {
        final scheduleTime = DateTimeHelper.formatTime12(schedule.startAt);
        return scheduleTime == time;
      });
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // Zoomable Grid (InteractiveViewer + constrained height)
  // ========================================
  Widget _buildZoomableGrid(List<TableInfo> regularTables) {
    final tableMap = {
      for (var table in regularTables) table.tableNumber: table,
    };
    final layout = widget.response.layout;
    final rows = layout?.rows ?? _calculateDefaultRows(regularTables.length, 6);
    final columns = layout?.columns ?? 6;

    return Container(
      constraints: const BoxConstraints(maxHeight: 450),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(80),
              onInteractionStart: (details) {
                _onInteractionStart();
              },
              onInteractionEnd: (details) {
                // Track current scale when user stops interacting
                setState(() {
                  _currentScale = _transformController.value
                      .getMaxScaleOnAxis();
                });
                _onInteractionEnd();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(rows, (rowIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: IntrinsicHeight(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: List.generate(columns, (colIndex) {
                                    final tableNumber =
                                        (rowIndex * columns + colIndex + 1)
                                            .toString();
                                    final table = tableMap[tableNumber];

                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: table != null
                                            ? _buildTableCell(
                                                table,
                                                table.tableNumber ==
                                                    widget.response.myTable,
                                              )
                                            : _buildEmptyCell(tableNumber),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Zoom Controls (right side) - with auto-hide
            AnimatedOpacity(
              opacity: _showZoomControls ? 0.85 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Positioned(
                right: 8,
                top: 8,
                child: IgnorePointer(
                  ignoring: !_showZoomControls,
                  child: GestureDetector(
                    onTap: () {
                      // Show controls when tapped
                      setState(() {
                        _showZoomControls = true;
                      });
                      _resetHideTimer();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: _zoomIn,
                            tooltip: 'Zoom In',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            color: color.AppColors.primary,
                          ),
                          Container(
                            width: 36,
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            onPressed: _zoomOut,
                            tooltip: 'Zoom Out',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            color: color.AppColors.primary,
                          ),
                          Container(
                            width: 36,
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          IconButton(
                            icon: const Icon(Icons.crop_free, size: 18),
                            onPressed: _resetZoom,
                            tooltip: 'Reset Zoom',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            color: color.AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Zoom hint overlay (bottom-left)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pinch, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Pinch or use controls to zoom • ${_currentScale.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // No Table Section
  // ========================================
  Widget _buildNoTableSection(DateTime date, String time) {
    final dateText = DateTimeHelper.formatFullDate(date);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 56, color: Colors.grey[400]),
              SizedBox(height: space.m),
              Text(
                'No Table Assigned',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color.AppColors.textPrimary,
                ),
              ),
              SizedBox(height: space.s),
              Text(
                'You don\'t have a table assignment for',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: color.AppColors.textSecondary,
                ),
              ),
              Text(
                '$dateText at $time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.AppColors.textPrimary,
                ),
              ),
              SizedBox(height: space.m),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: color.AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Try selecting another time slot',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // Helper: Calculate Default Rows
  // ========================================
  int _calculateDefaultRows(int tableCount, int columns) {
    return (tableCount / columns).ceil();
  }

  // ========================================
  // Table Cell
  // ========================================
  Widget _buildTableCell(TableInfo table, bool isMyTable) {
    final isSelected = selectedTableNumber == table.tableNumber;
    final isOccupied = table.isOccupied;
    final colors = _getTableCellColors(isMyTable, isSelected, isOccupied);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTableNumber = table.tableNumber;
        });
        _showTableDetails(table, isMyTable);
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          constraints: const BoxConstraints(minWidth: 45, minHeight: 45),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border, width: 2),
            boxShadow: isMyTable || isSelected
                ? [
                    BoxShadow(
                      color: colors.border.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      table.tableNumber,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isMyTable)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.person_pin,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isOccupied)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.person,
                        size: 10,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // Empty Cell
  // ========================================
  Widget _buildEmptyCell(String tableNumber) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        constraints: const BoxConstraints(minWidth: 45, minHeight: 45),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tableNumber,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
                fontWeight: FontWeight.w300,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // Helper: Get Table Cell Colors
  // ========================================
  _TableCellColors _getTableCellColors(
    bool isMyTable,
    bool isSelected,
    bool isOccupied,
  ) {
    if (isMyTable) {
      return _TableCellColors(
        background: color.AppColors.primary,
        border: color.AppColors.primaryDark,
        text: Colors.white,
      );
    }

    if (isSelected) {
      return _TableCellColors(
        background: Colors.orange,
        border: Colors.orange[700]!,
        text: Colors.white,
      );
    }

    if (isOccupied) {
      return _TableCellColors(
        background: Colors.green[50]!,
        border: Colors.green,
        text: Colors.green[900]!,
      );
    }

    return _TableCellColors(
      background: Colors.white,
      border: Colors.grey[300]!,
      text: Colors.black87,
    );
  }

  // ========================================
  // Booth Card
  // ========================================
  Widget _buildBoothCard(TableInfo booth) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.store, color: Colors.purple),
        ),
        title: Text(
          booth.tableNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          booth.isOccupied ? '${booth.delegates.length} delegate(s)' : 'Empty',
        ),
        trailing: Icon(
          booth.isOccupied ? Icons.people : Icons.event_available,
          color: booth.isOccupied ? Colors.green : Colors.grey,
        ),
        onTap: () => _showTableDetails(booth, false),
      ),
    );
  }

  // ========================================
  // Legend
  // ========================================
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(color.AppColors.primary, 'Your Table'),
        _buildLegendItem(Colors.green[50]!, 'Occupied'),
        _buildLegendItem(Colors.white, 'Available'),
      ],
    );
  }

  Widget _buildLegendItem(Color itemColor, String label) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: itemColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ========================================
  // Show Table Details
  // ========================================
  void _showTableDetails(TableInfo table, bool isMyTable) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          TableDetailSheet(table: table, isMyTable: isMyTable),
    );
  }
}

// ========================================
// Helper Class: Table Cell Colors
// ========================================
class _TableCellColors {
  final Color background;
  final Color border;
  final Color text;

  _TableCellColors({
    required this.background,
    required this.border,
    required this.text,
  });
}
