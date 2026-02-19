import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_room_list_item.dart';
import 'package:test_wpa/features/chat/presentation/widgets/empty_state_widget.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ChatRoomListView extends StatelessWidget {
  const ChatRoomListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
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
            return EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              message: 'Start chatting with delegates',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ReadContext(context).read<ChatBloc>().add(LoadChatRooms());
            },
            child: Column(
              children: [
                // Connection status
                // ConnectionStatusIndicator(
                //   isConnected: state.isWebSocketConnected,
                // ),

                // Chat rooms list
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
                        onProfileTap: () {
                          // ✅ แค่ navigate ไป profile อย่างเดียว ไม่ต้อง SelectChatRoom
                          final id = int.tryParse(room.participantId);
                          if (id != null) {
                            Modular.to.pushNamed('/other-profile/$id');
                          }
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
    );
  }
}
