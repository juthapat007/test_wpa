import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_room_list_item.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';

class ChatRoomListPage extends StatefulWidget {
  const ChatRoomListPage({super.key});

  @override
  State<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  late TextEditingController usernameController;
  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    // Load chat rooms และเชื่อมต่อ WebSocket
    ReadContext(context).read<ChatBloc>().add(LoadChatRooms());
    ReadContext(context).read<ChatBloc>().add(ConnectWebSocket());
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chat',
      currentIndex: 3,
      backgroundColor: AppColors.background,
      appBarStyle: AppBarStyle.elegant,

      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatRoomsLoaded) {
            if (state.rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: space.m),
                    Text(
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: space.s),
                    Text(
                      'Search for delegates to start chatting',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ReadContext(context).read<ChatBloc>().add(LoadChatRooms());
              },
              child: Column(
                children: [
                  // Connection status indicator
                  if (!state.isWebSocketConnected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: AppColors.warning.withOpacity(0.2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connecting...',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AppTextFormField(
                      controller: usernameController,
                      label: 'Search username...',
                      icon: CupertinoIcons.search,
                      textInputAction: TextInputAction.search,
                    ),
                  ),

                  // Chat rooms list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.rooms.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 88),
                      itemBuilder: (context, index) {
                        final room = state.rooms[index];
                        return ChatRoomListItem(
                          room: room,
                          onTap: () {
                            ReadContext(
                              context,
                            ).read<ChatBloc>().add(SelectChatRoom(room));
                            Modular.to.pushNamed('/chat/room');
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}
