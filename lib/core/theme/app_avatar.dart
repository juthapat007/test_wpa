import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const AppAvatar({super.key, this.imageUrl, this.radius = 20, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl == null || imageUrl!.isEmpty
          ? const AssetImage('assets/images/empty_state.png')
          : NetworkImage(imageUrl!) as ImageProvider,
    );

    if (onTap == null) return avatar;

    return GestureDetector(onTap: onTap, child: avatar);
  }
}
