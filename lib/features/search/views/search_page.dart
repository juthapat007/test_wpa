import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/features/widgets/app_bottom_navigation_bar.dart';
import 'package:test_wpa/features/widgets/app_text_form_field.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController usernameController;
  //late คือ ตัวแปรห้ามว่าง
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

  void _onSearch() {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter username')));
      return;
    }

    // TODO: ต่อ API search ตรงนี้
    debugPrint('Search username: $username');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Search')),
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
              SizedBox(height: space.l),
              const Expanded(
                child: Text(
                  'Search result will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }
}
