import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_room_list_item.dart';
import 'package:test_wpa/features/chat/presentation/widgets/empty_state_widget.dart';

class ChatRoomListView extends StatelessWidget {
  const ChatRoomListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      // ✅ FIX: listenWhen — ฟัง error เท่านั้น
      listenWhen: (_, curr) => curr is ChatError,
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
      buildWhen: (_, curr) =>
          curr is ChatLoading ||
          curr is ChatRoomsLoaded ||
          curr is ChatInitial ||
          curr is ChatError,
      builder: (context, state) {
        if (state is ChatLoading || state is ChatInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ChatRoomsLoaded) {
          return _RoomList(rooms: state.rooms);
        }

        // ChatError ถูก handle ใน listener แล้ว
        // แต่ถ้า state เป็น error และยังไม่มี rooms → แสดง empty
        return const _EmptyRooms();
      },
    );
  }
}

class _RoomList extends StatelessWidget {
  final List<ChatRoom> rooms;

  const _RoomList({required this.rooms});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const _EmptyRooms();

    return RefreshIndicator(
      onRefresh: () async {
        ReadContext(context).read<ChatBloc>().add(LoadChatRooms());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return ChatRoomCard(
            room: room,
            onTap: () {
              ReadContext(context).read<ChatBloc>().add(SelectChatRoom(room));
              Modular.to.pushNamed('/chat/room');
            },
            onProfileTap: () {
              final id = int.tryParse(room.participantId);
              if (id != null) Modular.to.pushNamed('/other_profile/$id');
            },
          );
        },
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: 'No conversations yet',
      message: 'Start chatting with delegates',
    );
  }
}
