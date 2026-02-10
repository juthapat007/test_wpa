// lib/features/meeting/widgets/table_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/widgets/table_detail_sheet.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';

class TableGridWidget extends StatefulWidget {
  final TableViewResponse response;
  final Schedule? currentSchedule;

  const TableGridWidget({
    super.key,
    required this.response,
    this.currentSchedule,
  });

  @override
  State<TableGridWidget> createState() => _TableGridWidgetState();
}

class _TableGridWidgetState extends State<TableGridWidget> {
  String? selectedTableNumber;

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTime.parse(widget.response.date);
    final hasNoTable = widget.response.myTable.isEmpty;

    // แยก regular tables กับ booths
    final regularTables = widget.response.tables
        .where((t) => !t.tableNumber.contains('Booth'))
        .toList();

    final booths = widget.response.tables
        .where((t) => t.tableNumber.contains('Booth'))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateTimeHeader(selectedDate, widget.currentSchedule),
          SizedBox(height: space.m),

          if (hasNoTable)
            _buildNoTableSection(selectedDate, widget.response.time)
          else
            _buildTableSection(regularTables, booths),
        ],
      ),
    );
  }

  // ========================================
  // Date/Time Header
  // ========================================
  Widget _buildDateTimeHeader(DateTime date, Schedule? schedule) {
    print('🧪 schedule is null? ${schedule == null}');
    if (schedule != null) {
      print('🧪 startAt: ${schedule.startAt}');
      print('🧪 endAt: ${schedule.endAt}');
    }

    final dateText = DateFormat('EEE, d MMM yyyy').format(date);

    final timeText = schedule != null
        ? '${DateFormat('HH:mm').format(schedule.startAt.toUtc())}'
              '–'
              '${DateFormat('HH:mm').format(schedule.endAt.toUtc())}'
        : widget.response.time;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$dateText  •  $timeText',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // No Table Section
  // ========================================
  Widget _buildNoTableSection(DateTime date, String time) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Card(
          color: color.AppColors.surface,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                SizedBox(height: space.m),
                Text(
                  'No Table Assigned',
                  style: TextStyle(
                    fontSize: 18,
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
                  '${DateFormat('EEE, d MMM yyyy').format(date)} at $time',
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
                    horizontal: 16,
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
                        size: 16,
                        color: color.AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Please check other time slots',
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
      ),
    );
  }

  // ========================================
  // Table Section (มีโต๊ะ)
  // ========================================
  Widget _buildTableSection(
    List<TableInfo> regularTables,
    List<TableInfo> booths,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableGrid(regularTables, widget.response.myTable),
        SizedBox(height: space.l),

        if (booths.isNotEmpty) ...[
          const Text(
            'Booths',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: space.m),
          ...booths.map(_buildBoothCard),
          SizedBox(height: space.l),
        ],

        _buildLegend(),
      ],
    );
  }

  // ========================================
  // Table Grid
  // ========================================
  //ตอนนี้ยังไม่จัด ui ของโต๊ะอย่างถูกต้อง
  Widget _buildTableGrid(List<TableInfo> tables, String myTable) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ ปรับ columns ตามขนาดหน้าจอ
        final columns = constraints.maxWidth > 600 ? 6 : 6;
        final rows = (tables.length / columns).ceil();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: List.generate(rows, (rowIndex) {
              final startIndex = rowIndex * columns;
              final endIndex = (startIndex + columns).clamp(0, tables.length);
              final rowTables = tables.sublist(startIndex, endIndex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rowTables.map((table) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildTableCell(
                          table,
                          table.tableNumber == myTable,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ========================================
  // Table Cell
  // ========================================
  Widget _buildTableCell(TableInfo table, bool isMyTable) {
    final isSelected = selectedTableNumber == table.tableNumber;
    final isOccupied = table.isOccupied;

    // ✅ ใช้ helper method เพื่อลด complexity
    final colors = _getTableCellColors(isMyTable, isSelected, isOccupied);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTableNumber = table.tableNumber;
        });
        _showTableDetails(table, isMyTable);
      },
      child: AspectRatio(
        aspectRatio: 1, // ✅ ทำให้เป็นสี่เหลี่ยมจัตุรัสเสมอ
        child: Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border, width: 2),
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
              if (isOccupied && !isMyTable && !isSelected)
                Icon(Icons.person, size: 12, color: Colors.green[900]),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Helper method สำหรับสี
  _TableCellColors _getTableCellColors(
    bool isMyTable,
    bool isSelected,
    bool isOccupied,
  ) {
    if (isMyTable) {
      return _TableCellColors(
        background: Colors.blue,
        border: Colors.blue,
        text: Colors.white,
      );
    }

    if (isSelected) {
      return _TableCellColors(
        background: Colors.orange,
        border: Colors.orange,
        text: Colors.white,
      );
    }

    if (isOccupied) {
      return _TableCellColors(
        background: Colors.green[100]!,
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
      margin: const EdgeInsets.only(bottom: 12),
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
        _buildLegendItem(Colors.blue, 'Your Table'),
        _buildLegendItem(Colors.green[100]!, 'Occupied'),
        _buildLegendItem(Colors.white, 'Available'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
// Helper Class
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
