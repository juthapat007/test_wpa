import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';

class EmptyScheduleView extends StatelessWidget {
  const EmptyScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
          SizedBox(height: space.m),
          Text(
            'No schedules for this date',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
