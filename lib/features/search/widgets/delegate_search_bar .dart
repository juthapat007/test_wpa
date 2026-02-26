import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;

class DelegateSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSearch;
  final Duration debounceDuration;

  const DelegateSearchBar({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.textInputAction = TextInputAction.search,
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<DelegateSearchBar> createState() => _DelegateSearchBarState();
}

class _DelegateSearchBarState extends State<DelegateSearchBar> {
  Timer? _debounce;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearch(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: widget.controller,
        textInputAction: widget.textInputAction,
        onChanged: _onChanged,
        onFieldSubmitted: widget.onSearch,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color.AppColors.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: color.AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}
