// lib/features/meeting/views/table_grid_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/presentation/bloc/table_bloc.dart';
import 'package:intl/intl.dart';

class TableGridPage extends StatefulWidget {
  final String? initialDate;
  final String? initialTime;

  const TableGridPage({super.key, this.initialDate, this.initialTime});

  @override
  State<TableGridPage> createState() => _TableGridPageState();
}

class _TableGridPageState extends State<TableGridPage> {
  String? selectedTableNumber;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<TableBloc>().add(
      LoadTableView(date: widget.initialDate, time: widget.initialTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TableBloc>().add(LoadTableView());
            },
          ),
        ],
      ),
      body: BlocBuilder<TableBloc, TableState>(
        builder: (context, state) {
          if (state is TableLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TableLoaded) {
            return _buildContent(state.response);
          }

          if (state is TableError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: space.m),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: space.m),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TableBloc>().add(LoadTableView());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(TableViewResponse response) {
    _selectedDate = DateTime.parse(response.date);
    // จัดโต๊ะเป็น rows (แยกตาม table_number)
    final regularTables = response.tables
        .where((t) => !t.tableNumber.contains('Booth'))
        .toList();
    final booths = response.tables
        .where((t) => t.tableNumber.contains('Booth'))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time selector
          _buildTimeSelector(response),
          SizedBox(height: space.l),

          // Date selector
          _buildDateSelector(response),
          SizedBox(height: space.l),

          // My Table info
          if (response.myTable.isNotEmpty) ...[
            _buildMyTableCard(response),
            SizedBox(height: space.l),
          ],
          // Table Grid
          Text(
            'Tables (${regularTables.length} total)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: space.m),
          _buildTableGrid(regularTables, response.myTable),
          SizedBox(height: space.l),

          // Booths
          if (booths.isNotEmpty) ...[
            Text(
              'Booths',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: space.m),
            ...booths.map((booth) => _buildBoothCard(booth)).toList(),
          ],

          SizedBox(height: space.l),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(TableViewResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Slot',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: space.s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: response.timesToday.map((time) {
              final isSelected = time == response.time;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<TableBloc>().add(ChangeTimeSlot(time));
                    }
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(TableViewResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          DateFormat('EEE, d MMM yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 13),
        ),
        // Row(
        //   children: [
        //     Text(
        //       'Date',
        //       style: TextStyle(
        //         fontSize: 14,
        //         fontWeight: FontWeight.w500,
        //         color: Colors.grey[700],
        //       ),
        //     ),
        //     Spacer(),
        //     // Calendar button
        //     IconButton(
        //       icon: Icon(Icons.calendar_month, color: Colors.blue),
        //       onPressed: () => _showDatePicker(context, response),
        //       tooltip: 'Select date',
        //     ),
        //   ],
        // ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: response.days.map((day) {
              final isSelected = day == response.date;
              final date = DateTime.parse(day);
              final formatted = DateFormat('MMM dd').format(date);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(formatted),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<TableBloc>().add(ChangeDate(day));
                    }
                  },
                  selectedColor: Colors.green,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    TableViewResponse response,
  ) async {
    // Parse available dates
    final availableDates = response.days.map((d) => DateTime.parse(d)).toList();
    final firstDate = availableDates.first;
    final lastDate = availableDates.last;
    final initialDate = DateTime.parse(response.date);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
      selectableDayPredicate: (date) {
        // Only allow dates that are in available dates
        return availableDates.any(
          (d) =>
              d.year == date.year && d.month == date.month && d.day == date.day,
        );
      },
    );

    if (selectedDate != null && context.mounted) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      context.read<TableBloc>().add(ChangeDate(formattedDate));
    }
  }

  Widget _buildMyTableCard(TableViewResponse response) {
    final myTableInfo = response.tables.firstWhere(
      (t) => t.tableNumber == response.myTable,
      orElse: () => response.tables.first,
    );

    return Card(
      color: Colors.blue[50],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.table_restaurant, color: Colors.blue, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Table',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    'Table ${response.myTable}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  if (myTableInfo.delegates.isNotEmpty)
                    Text(
                      '${myTableInfo.delegates.length} delegate(s)',
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

  Widget _buildTableGrid(List<TableInfo> tables, String myTable) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tables.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final table = tables[index];
          return _buildTableCell(table, table.tableNumber == myTable);
        },
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
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
