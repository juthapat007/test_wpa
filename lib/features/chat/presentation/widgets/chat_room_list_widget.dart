// lib/features/chat/presentation/pages/chat_room_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat_room_list_view.dart';
import 'package:test_wpa/features/chat/views/friends_list_view.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat_room_list_view.dart';
import 'package:test_wpa/features/chat/views/friends_list_view.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';

class ChatRoomListWidget extends StatefulWidget {
  const ChatRoomListWidget({super.key});

  @override
  State<ChatRoomListWidget> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ChatBloc>().add(ResetAndLoadChatRooms());
    context.read<ChatBloc>().add(ConnectWebSocket());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Connection',
      currentIndex: 3,

      appBarStyle: AppBarStyle.elegant,
      backgroundColor: color.AppColors.background,
      body: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Messages'),
              Tab(text: 'Friends'),
            ],
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [ChatRoomListView(), FriendsListView()],
            ),
          ),
        ],
      ),
    );
  }
}
