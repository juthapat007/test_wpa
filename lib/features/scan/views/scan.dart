import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_wpa/features/widgets/app_bottom_navigation_bar.dart';

class Scan extends StatelessWidget {
  const Scan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('scan')),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 2),
    );
  }
}
