import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? centerWidget;

  const AppAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.leading,
    this.actions,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      leading: leading,
      title: centerWidget ?? (title != null ? Text(title!) : null),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
