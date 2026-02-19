import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_room_list_widget.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectedChat extends StatelessWidget {
  const ConnectedChat({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatRoomListWidget();
  }
}
