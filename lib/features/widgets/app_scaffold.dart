import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_app_bar.dart';
import 'package:test_wpa/core/theme/app_avatar.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'app_bottom_navigation_bar.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppBarStyle { standard, elegant }

class AppScaffold extends StatelessWidget {
  final String icon;
  final String title;
  final int currentIndex;
  final Widget? body;
  final List<Widget>? actions;
  final bool showAvatar;
  final Color? backgroundColor;
  final AppBarStyle appBarStyle;
  final bool showBottomNavBar;

  const AppScaffold({
    super.key,
    this.icon = '',
    required this.title,
    required this.currentIndex,
    this.body,
    this.actions,
    this.showAvatar = true,
    this.backgroundColor,
    this.appBarStyle = AppBarStyle.standard,
    this.showBottomNavBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBarStyle == AppBarStyle.elegant
          ? _buildElegantAppBar(context)
          : AppAppBar(
              title: title,
              leading: showAvatar
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          String? avatarUrl;

                          if (state is AuthAuthenticated) {
                            avatarUrl = state.avatarUrl;
                          }

                          return AppAvatar(
                            imageUrl: avatarUrl,
                            onTap: () {
                              Modular.to.pushNamed('/profile');
                            },
                          );
                        },
                      ),
                    )
                  : null,
              actions: actions ?? _defaultActions(context),
            ),
      body: body,
      bottomNavigationBar: !showBottomNavBar || currentIndex == -1
          ? null
          : _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildElegantAppBar(BuildContext context) {
    final resolvedActions = actions ?? _defaultActions(context);

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Row(
            children: [
              // Avatar
              if (showAvatar)
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String? avatarUrl;

                    if (state is AuthAuthenticated) {
                      avatarUrl = state.avatarUrl;
                    }

                    return GestureDetector(
                      onTap: () => Modular.to.pushNamed('/profile'),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),

                          image: avatarUrl != null && avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/empty_state.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              if (showAvatar) const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF312E81),
                  ),
                ),
              ),
              // Actions
              if (resolvedActions != null) ...resolvedActions,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60), // ปรับเลขตรงนี้
      child: Container(
        decoration: BoxDecoration(),
        child: AppBottomNavigationBar(currentIndex: currentIndex),
      ),
    );
  }

  List<Widget>? _defaultActions(BuildContext context) {
    switch (appBarStyle) {
      case AppBarStyle.standard:
        return [
          IconButton(
            onPressed: () => Modular.to.pushNamed('/notification'),
            icon: const Icon(
              Icons.notifications_outlined,
              color: color.AppColors.textSecondary,
            ),
          ),
        ];

      case AppBarStyle.elegant:
        return [
          IconButton(
            onPressed: () => Modular.to.pushNamed('/notification'),
            icon: const Icon(
              Icons.notifications_outlined,
              color: color.AppColors.textSecondary,
            ),
          ),
        ];
    }
  }
}
