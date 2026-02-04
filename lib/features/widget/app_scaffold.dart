import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_app_bar.dart';
import 'package:test_wpa/core/theme/app_avatar.dart';
import 'app_bottom_navigation_bar.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final int currentIndex;
  final Widget? body;
  final List<Widget>? actions;
  final bool showAvatar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    this.body,
    this.actions,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: title,
        leading: showAvatar
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AppAvatar(
                  onTap: () {
                    Modular.to.pushNamed('/profile');
                  },
                ),
              )
            : null,
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: AppBottomNavigationBar(currentIndex: currentIndex),
    );
  }
}
