import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_room_list_item.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ChatRoomListPage extends StatefulWidget {
  const ChatRoomListPage({super.key});

  @override
  State<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  @override
  void initState() {
    super.initState();
    // Load chat rooms และเชื่อมต่อ WebSocket
    ReadContext(context).read<ChatBloc>().add(LoadChatRooms());
    ReadContext(context).read<ChatBloc>().add(ConnectWebSocket());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Messages',
      currentIndex: 3,
      backgroundColor: AppColors.background,
      appBarStyle: AppBarStyle.elegant,
      actions: [
        IconButton(
          onPressed: () => Modular.to.pushNamed('/notification'),
          icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
        ),
      ],
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: space.s),
                    Text(
                      'Start chatting with delegates',
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
                      color: AppColors.warning.withOpacity(0.1),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Chat rooms list with Cards
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.rooms.length,
                      itemBuilder: (context, index) {
                        final room = state.rooms[index];
                        return ChatRoomCard(
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
