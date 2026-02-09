import 'package:flutter/material.dart';

class ProfileInfoCard extends StatelessWidget {
  final String label;
  final Widget child;

  const ProfileInfoCard({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
