import 'package:flutter/cupertino.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';

//ยังไม่ได้ต่อ api
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final TextEditingController usernameController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBarStyle: AppBarStyle.elegant,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: AppTextFormField(
                  controller: usernameController,
                  label: 'Search username...',
                  icon: CupertinoIcons.search,
                  textInputAction: TextInputAction.search,
                  //ต่อ api
                  // onSubmitted: (_) => _onSearch(),
                ),
              ),
              const SizedBox(height: space.l),
            ],
          ),
        ),
      ),
    );
  }
}
