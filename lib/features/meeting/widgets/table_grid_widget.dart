// lib/features/meeting/widgets/table_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/utils/date_time_helper.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/widgets/table_detail_sheet.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/time_slot_chip.dart';

class TableGridWidget extends StatefulWidget {
  final TableViewResponse response;
  final Schedule? currentSchedule;
  final ValueChanged<String>? onTimeSlotChanged;
  final Map<String, TimeSlotType> slotTypeMap;

  const TableGridWidget({
    super.key,
    required this.response,
    this.currentSchedule,
    this.onTimeSlotChanged,
    this.slotTypeMap = const {},
  });

  @override
  State<TableGridWidget> createState() => _TableGridWidgetState();
}

class _TableGridWidgetState extends State<TableGridWidget> {
  String? selectedTableNumber;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTimeHelper.parseSafeDate(widget.response.date);
    final regularTables = widget.response.tables
        .where((t) => !t.tableNumber.contains('Booth'))
        .toList();
    final booths = widget.response.tables
        .where((t) => t.tableNumber.contains('Booth'))
        .toList();
    final hasNoAssignment = widget.response.myTable.isEmpty;
    final hasNoTables = widget.response.tables.isEmpty;

    // ✅ trigger popup หลัง build เสร็จ ถ้าไม่มีโต๊ะ
    if (hasNoTables) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNoTableDialog(context, selectedDate, widget.response.time);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeSlotHeader(),
          const SizedBox(height: 12),

          // ✅ มีโต๊ะ → แสดงปกติ, ไม่มีโต๊ะ → ไม่ render อะไร popup จะขึ้นเอง
          if (!hasNoTables) ...[
            if (!hasNoAssignment) _buildMyTableBanner(),
            if (hasNoAssignment) _buildNoAssignmentBanner(),
            const SizedBox(height: 12),
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
  // My Table Banner
  // ========================================
  Widget _buildMyTableBanner() {
    final myTable = widget.response.myTable;
    final currentTime = widget.response.time;
    final timesToday = widget.response.timesToday;
    final currentIndex = timesToday.indexOf(currentTime);
    final nextTime = (currentIndex >= 0 && currentIndex + 1 < timesToday.length)
        ? timesToday[currentIndex + 1]
        : null;
    final timeRange = nextTime != null
        ? '$currentTime – $nextTime'
        : currentTime;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.AppColors.primary, color.AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.AppColors.primary.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Table Now',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Table $myTable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white60, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      timeRange,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            myTable,
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Time Slot Header
  // ========================================
  Widget _buildTimeSlotHeader() {
    final currentTime = widget.response.time;
    final timesToday = widget.response.timesToday;
    final dateText = DateTimeHelper.formatFullDate(
      DateTimeHelper.parseSafeDate(widget.response.date),
    );
    final currentIndex = timesToday.indexOf(currentTime);
    final nextTime = (currentIndex >= 0 && currentIndex + 1 < timesToday.length)
        ? timesToday[currentIndex + 1]
        : null;
    final timeDisplay = nextTime != null
        ? '$currentTime – $nextTime'
        : currentTime;

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
              '$dateText  |  $timeDisplay',
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
                onTap: () => _showTimeSlotPopup(
                  timesToday,
                  currentTime,
                  widget.slotTypeMap,
                ),
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
  // No Assignment Banner
  // ========================================
  Widget _buildNoAssignmentBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(
            'No table assigned for this time slot',
            style: TextStyle(fontSize: 13, color: Colors.orange[800]),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Time Slot Popup
  // ========================================
  void _showTimeSlotPopup(
    List<String> timesToday,
    String currentTime,
    Map<String, TimeSlotType> slotTypeMap,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              color: Colors.white,
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                maxChildSize: 0.9,
                minChildSize: 0.3,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(timesToday.length, (index) {
                              final time = timesToday[index];
                              final isSelected = time == currentTime;
                              final slotType =
                                  slotTypeMap[time] ?? TimeSlotType.unknown;
                              final nextTime = index + 1 < timesToday.length
                                  ? timesToday[index + 1]
                                  : null;
                              final label = nextTime != null
                                  ? '$time – $nextTime'
                                  : time;
                              return TimeSlotChip(
                                time: label,
                                isSelected: isSelected,
                                type: slotType,
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  widget.onTimeSlotChanged?.call(time);
                                },
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ========================================
  // Zoomable Grid
  // ========================================
  Widget _buildZoomableGrid(List<TableInfo> regularTables) {
    final tableMap = {
      for (var table in regularTables) table.tableNumber: table,
    };
    final layout = widget.response.layout;
    final rows = layout?.rows ?? _calculateDefaultRows(regularTables.length, 6);
    final columns = layout?.columns ?? 6;
    const cellSize = 60.0;
    const spacing = 6.0;
    const padding = 24.0;
    final gridWidth =
        (columns * cellSize) + ((columns - 1) * spacing) + (padding * 2);
    final gridHeight =
        (rows * cellSize) + ((rows - 1) * spacing) + (padding * 2);

    return Container(
      height: 400,
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
              boundaryMargin: EdgeInsets.all(40 / 100),
              constrained: false,
              child: Center(
                child: Container(
                  width: gridWidth,
                  height: gridHeight,
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(rows, (rowIndex) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: rowIndex < rows - 1 ? spacing : 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(columns, (colIndex) {
                            final tableNumber =
                                (rowIndex * columns + colIndex + 1).toString();
                            final table = tableMap[tableNumber];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: colIndex < columns - 1 ? spacing : 0,
                              ),
                              child: SizedBox(
                                width: cellSize,
                                height: cellSize,
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
                      );
                    }),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch, size: 14, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      'Pinch to zoom',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _transformController.value = Matrix4.identity(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.center_focus_strong,
                      size: 18,
                      color: color.AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateDefaultRows(int tableCount, int columns) =>
      (tableCount / columns).ceil();

  Widget _buildTableCell(TableInfo table, bool isMyTable) {
    final isSelected = selectedTableNumber == table.tableNumber;
    final isOccupied = table.isOccupied;
    final colors = _getTableCellColors(isMyTable, isSelected, isOccupied);

    return GestureDetector(
      onTap: () {
        setState(() => selectedTableNumber = table.tableNumber);
        _showTableDetails(table, isMyTable);
      },
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.tableNumber,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            if (isMyTable)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.person_pin, size: 14, color: Colors.white),
              )
            else if (isOccupied)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.person, size: 12, color: Colors.green[900]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCell(String tableNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Center(
        child: Text(
          tableNumber,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  _TableCellColors _getTableCellColors(
    bool isMyTable,
    bool isSelected,
    bool isOccupied,
  ) {
    if (isMyTable)
      return _TableCellColors(
        background: color.AppColors.primary,
        border: color.AppColors.primaryDark,
        text: Colors.white,
      );
    if (isSelected)
      return _TableCellColors(
        background: Colors.orange,
        border: Colors.orange[700]!,
        text: Colors.white,
      );
    if (isOccupied)
      return _TableCellColors(
        background: Colors.green[50]!,
        border: Colors.green,
        text: Colors.green[900]!,
      );
    return _TableCellColors(
      background: Colors.white,
      border: Colors.grey[300]!,
      text: Colors.black87,
    );
  }

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

  // ========================================
  // ✅ No Table Dialog — popup ลอยตรงกลาง
  // ========================================
  void _showNoTableDialog(BuildContext context, DateTime date, String time) {
    final dateText = DateTimeHelper.formatFullDate(date);
    final timesToday = widget.response.timesToday;
    final currentIndex = timesToday.indexOf(time);
    final nextSlot = (currentIndex >= 0 && currentIndex + 1 < timesToday.length)
        ? timesToday[currentIndex + 1]
        : null;
    final nextNextSlot =
        (currentIndex >= 0 && currentIndex + 2 < timesToday.length)
        ? timesToday[currentIndex + 2]
        : null;
    final nextTimeRange = (nextSlot != null && nextNextSlot != null)
        ? '$nextSlot – $nextNextSlot'
        : nextSlot;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Table Assigned',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "You don't have a table assignment for",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: color.AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$dateText at $time',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (nextTimeRange != null) ...[
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Next slot',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onTimeSlotChanged?.call(nextSlot!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: color.AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: color.AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nextTimeRange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color.AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
