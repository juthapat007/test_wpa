import 'package:flutter/material.dart';

class SomeoneProfile extends StatefulWidget {
  const SomeoneProfile({super.key});

  @override
  State<SomeoneProfile> createState() => _SomeoneProfileState();
}

class _SomeoneProfileState extends State<SomeoneProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Someone Profile'),
      ),
      body: const Center(
        child: Text('Someone Profile View'),
      ),
    );
  }
}
