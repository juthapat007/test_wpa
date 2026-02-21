import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/widgets/table_cell_widget.dart';
import 'package:test_wpa/features/meeting/widgets/table_detail_sheet.dart';
import 'package:test_wpa/features/meeting/widgets/table_grid_banners.dart';
import 'package:test_wpa/features/meeting/widgets/table_legend_widget.dart';
import 'package:test_wpa/features/meeting/widgets/table_slot_header.dart';
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
  String? _selectedTableNumber;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regularTables = widget.response.tables
        .where((t) => !t.tableNumber.contains('Booth'))
        .toList();
    final booths = widget.response.tables
        .where((t) => t.tableNumber.contains('Booth'))
        .toList();
    final hasNoAssignment = widget.response.myTable.isEmpty;
    final hasNoTables = widget.response.tables.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TableSlotHeader(
            response: widget.response,
            slotTypeMap: widget.slotTypeMap,
            onTimeSlotChanged: widget.onTimeSlotChanged,
          ),
          const SizedBox(height: 12),
          if (hasNoTables)
            NoTableCard(
              response: widget.response,
              onTimeSlotChanged: widget.onTimeSlotChanged,
            )
          else ...[
            if (!hasNoAssignment) MyTableBanner(response: widget.response),
            if (hasNoAssignment) const NoAssignmentBanner(),
            const SizedBox(height: 12),
            _buildZoomableGrid(regularTables),
            const SizedBox(height: 12),
            const TableLegend(showLeave: true),
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

  Widget _buildZoomableGrid(List<TableInfo> regularTables) {
    final tableMap = {for (var t in regularTables) t.tableNumber: t};
    final layout = widget.response.layout;
    final rows = layout?.rows ?? _calculateRows(regularTables.length, 6);
    final columns = layout?.columns ?? 6;
    const spacing = 6.0;
    const padding = 24.0;

    final screenWidth = MediaQuery.of(context).size.width - 32;
    final cellSize =
        ((screenWidth - (padding * 2) - ((columns - 1) * spacing)) / columns)
            .clamp(40.0, 60.0);

    final gridWidth =
        (columns * cellSize) + ((columns - 1) * spacing) + (padding * 2);
    final gridHeight =
        (rows * cellSize) + ((rows - 1) * spacing) + (padding * 2);

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(40),
              constrained: false,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: Container(
                    width: gridWidth,
                    height: gridHeight,
                    padding: const EdgeInsets.all(padding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(rows, (rowIndex) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: rowIndex < rows - 1 ? spacing : 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(columns, (colIndex) {
                              final number = (rowIndex * columns + colIndex + 1)
                                  .toString();
                              final table = tableMap[number];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: colIndex < columns - 1 ? spacing : 0,
                                ),
                                child: SizedBox(
                                  width: cellSize,
                                  height: cellSize,
                                  child: table != null
                                      ? () {
                                          final isMyTable =
                                              table.tableNumber ==
                                              widget.response.myTable;
                                          final isOnLeave =
                                              isMyTable &&
                                              widget.currentSchedule?.leave !=
                                                  null;
                                          return TableCellWidget(
                                            table: table,
                                            isMyTable: isMyTable,
                                            isSelected:
                                                _selectedTableNumber ==
                                                table.tableNumber,
                                            isOnLeave: isOnLeave,
                                            onTap: () {
                                              setState(
                                                () => _selectedTableNumber =
                                                    table.tableNumber,
                                              );
                                              _showTableDetails(
                                                table,
                                                isMyTable,
                                              );
                                            },
                                          );
                                        }()
                                      : EmptyTableCell(tableNumber: number),
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
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
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
                    child: const Icon(
                      Icons.center_focus_strong,
                      size: 18,
                      color: AppColors.primary,
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
          color: booth.isOccupied ? AppColors.success : AppColors.textSecondary,
        ),
        onTap: () => _showTableDetails(booth, false),
      ),
    );
  }

  void _showTableDetails(TableInfo table, bool isMyTable) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TableDetailSheet(table: table, isMyTable: isMyTable),
    );
  }

  int _calculateRows(int tableCount, int columns) =>
      (tableCount / columns).ceil();
}
