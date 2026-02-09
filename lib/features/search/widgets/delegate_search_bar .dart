import 'package:flutter/material.dart';

class DelegateSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSearch;

  const DelegateSearchBar({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.textInputAction = TextInputAction.search,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextFormField(
        controller: controller,
        textInputAction: textInputAction,
        onFieldSubmitted: onSearch,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
