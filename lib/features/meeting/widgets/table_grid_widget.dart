// lib/features/meeting/widgets/table_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

class TableGridWidget extends StatefulWidget {
  final TableViewResponse response;

  const TableGridWidget({super.key, required this.response});

  @override
  State<TableGridWidget> createState() => _TableGridWidgetState();
}

class _TableGridWidgetState extends State<TableGridWidget> {
  String? selectedTableNumber;

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTime.parse(widget.response.date);

    final regularTables = widget.response.tables
        .where((t) => !t.tableNumber.contains('Booth'))
        .toList();

    final booths = widget.response.tables
        .where((t) => t.tableNumber.contains('Booth'))
        .toList();

    final hasNoTable = widget.response.myTable.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ แสดงเสมอ
          _buildDateTimeHeader(selectedDate, widget.response.time),
          SizedBox(height: space.m),

          // ไม่มีโต๊ะ → centered empty state
          if (hasNoTable)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _buildNoTableAssignedCard(
                  selectedDate,
                  widget.response.time,
                ),
              ),
            )
          // ✅ มีโต๊ะ → layout ปกติ
          else ...[
            // _buildMyTableCard(widget.response),
            // SizedBox(height: space.l),
            _buildTableGrid(regularTables, widget.response.myTable),
            SizedBox(height: space.l),

            if (booths.isNotEmpty) ...[
              Text(
                'Booths',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: space.m),
              ...booths.map(_buildBoothCard).toList(),
              SizedBox(height: space.l),
            ],

            _buildLegend(),
          ],
        ],
      ),
    );
  }

  // ✅ Widget แสดงวันที่และเวลา
  Widget _buildDateTimeHeader(DateTime date, String time) {
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('EEE, d MMM yyyy').format(date)} at $time',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                Text(
                  'Time: $currentTime',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับกรณีไม่มีโต๊ะ
  Widget _buildNoTableAssignedCard(DateTime date, String time) {
    return Card(
      color: Colors.grey[100],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            SizedBox(height: space.m),
            Text(
              'No Table Assigned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: space.s),
            Text(
              'You don\'t have a table assignment for',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            Text(
              '${DateFormat('EEE, d MMM yyyy').format(date)} at $time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: space.m),
            Container(
              padding: const EdgeInsets.all(12), // ✅ responsive
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    'Please check other time slots',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildMyTableCard(TableViewResponse response) {
  //   final myTableInfo = response.tables.firstWhere(
  //     (t) => t.tableNumber == response.myTable,
  //     orElse: () => response.tables.first,
  //   );

  //   return Card(
  //     color: Colors.blue[50],
  //     elevation: 4,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Row(
  //         children: [
  //           Icon(Icons.table_restaurant, color: Colors.blue, size: 26),
  //           SizedBox(width: 12),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Your Table',
  //                   style: TextStyle(fontSize: 14, color: Colors.grey[700]),
  //                 ),
  //                 Text(
  //                   'Table ${response.myTable}',
  //                   style: TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.blue,
  //                   ),
  //                 ),
  //                 if (myTableInfo.delegates.isNotEmpty)
  //                   Text(
  //                     '${myTableInfo.delegates.length} delegate(s)',
  //                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTableGrid(List<TableInfo> tables, String myTable) {
    const columns = 6;
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
                return Flexible(
                  // ✅ เพิ่ม Flexible หรือ Expanded
                  child: _buildTableCell(table, table.tableNumber == myTable),
                );
              }).toList(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTableCell(TableInfo table, bool isMyTable) {
    final isSelected = selectedTableNumber == table.tableNumber;
    final isOccupied = table.isOccupied;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isMyTable) {
      bgColor = Colors.blue;
      borderColor = Colors.blue;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = Colors.orange;
      borderColor = Colors.orange;
      textColor = Colors.white;
    } else if (isOccupied) {
      bgColor = Colors.green[100]!;
      borderColor = Colors.green;
      textColor = Colors.green[900]!;
    } else {
      bgColor = Colors.white;
      borderColor = Colors.grey[300]!;
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTableNumber = table.tableNumber;
        });
        _showTableDetails(table, isMyTable);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.tableNumber,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (isOccupied && !isMyTable && !isSelected)
              Icon(Icons.person, size: 12, color: Colors.green[900]),
          ],
        ),
      ),
    );
  }

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
          child: Icon(Icons.store, color: Colors.purple),
        ),
        title: Text(
          booth.tableNumber,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          booth.isOccupied ? '${booth.delegates.length} delegate(s)' : 'Empty',
        ),
        trailing: booth.isOccupied
            ? Icon(Icons.people, color: Colors.green)
            : Icon(Icons.event_available, color: Colors.grey),
        onTap: () => _showTableDetails(booth, false),
      ),
    );
  }

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
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  void _showTableDetails(TableInfo table, bool isMyTable) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                  SizedBox(height: 20),

                  // Table info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMyTable ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.table_restaurant,
                          color: isMyTable ? Colors.white : Colors.grey[700],
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Table ${table.tableNumber}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isMyTable)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Your Table',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Delegates
                  if (table.delegates.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Table Available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Delegates (${table.delegates.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...table.delegates.map((delegate) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(delegate.avatarUrl),
                            onBackgroundImageError: (_, __) {},
                            child: delegate.avatarUrl.isEmpty
                                ? Text(
                                    delegate.delegateName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                  )
                                : null,
                          ),
                          title: Text(
                            delegate.delegateName,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (delegate.title?.isNotEmpty ?? false)
                                Text(delegate.title!),
                              Text(
                                delegate.company,
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
