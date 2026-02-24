// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:test_wpa/core/theme/app_colors.dart' as color;
// import 'package:test_wpa/core/theme/app_colors.dart';
// import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
// import 'package:test_wpa/features/chat/views/chat_room_list_view.dart';
// import 'package:test_wpa/features/chat/views/friends_list_view.dart';
// import 'package:test_wpa/features/widgets/app_scaffold.dart';

// class ChatRoomListWidget extends StatefulWidget {
//   const ChatRoomListWidget({super.key});

//   @override
//   State<ChatRoomListWidget> createState() => _ChatRoomListWidgetState();
// }

// class _ChatRoomListWidgetState extends State<ChatRoomListWidget>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     context.read<ChatBloc>()
//       ..add(ResetAndLoadChatRooms())
//       ..add(ConnectWebSocket());
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       title: 'Connection',
//       currentIndex: 3,
//       appBarStyle: AppBarStyle.elegant,
//       backgroundColor: color.AppColors.background,
//       body: Column(
//         children: [
//           TabBar(
//             controller: _tabController,
//             labelColor: AppColors.primary,
//             unselectedLabelColor: AppColors.textSecondary,
//             indicatorColor: AppColors.primary,
//             indicatorWeight: 3,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//             tabs: const [
//               Tab(text: 'Messages'),
//               Tab(text: 'Friends'),
//             ],
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: const [ChatRoomListView(), FriendsListView()],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/data/services/chat_websocket_service.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat_room_list_view.dart';
import 'package:test_wpa/features/chat/views/friends_list_view.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ChatRoomListWidget extends StatefulWidget {
  const ChatRoomListWidget({super.key});

  @override
  State<ChatRoomListWidget> createState() => _ChatRoomListWidgetState();
}

class _ChatRoomListWidgetState extends State<ChatRoomListWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // ✅ โหลด rooms เสมอเมื่อเปิดหน้า
    ReadContext(context).read<ChatBloc>().add(ResetAndLoadChatRooms());

    // ✅ Connect WebSocket เฉพาะเมื่อยังไม่ได้ connect
    // (AppShell อาจ connect ไปแล้ว — ไม่ต้อง connect ซ้ำ)
    final wsService = Modular.get<ChatWebSocketService>();
    if (!wsService.isConnected) {
      ReadContext(context).read<ChatBloc>().add(ConnectWebSocket());
    }
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
