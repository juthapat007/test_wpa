import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat_room_list_view.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';

class ChatRoomListPage extends StatefulWidget {
  const ChatRoomListPage({super.key});

  @override
  State<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ResetAndLoadChatRooms());
    context.read<ChatBloc>().add(ConnectWebSocket());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Messages',
      currentIndex: 3,
      backgroundColor: AppColors.background,
      appBarStyle: AppBarStyle.elegant,
      body: const ChatRoomListView(),
    );
  }
}
