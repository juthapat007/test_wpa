import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';

void showEditProfileDialog({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String field,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _EditProfileDialog(
      title: title,
      currentValue: currentValue,
      field: field,
      parentContext: context,
    ),
  );
}

// ✨ แยกเป็น StatefulWidget เพื่อจัดการ lifecycle ได้ดีขึ้น
class _EditProfileDialog extends StatefulWidget {
  final String title;
  final String currentValue;
  final String field;
  final BuildContext parentContext;

  const _EditProfileDialog({
    required this.title,
    required this.currentValue,
    required this.field,
    required this.parentContext,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    // ✅ Dispose controller ตอนที่ widget ถูก dispose จริงๆ
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_isSubmitting) return; // ป้องกันกดซ้ำ

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final newValue = _controller.text.trim();

      // ✅ ปิด dialog ก่อน
      Navigator.of(context).pop();

      // ✅ ส่ง event หลังจากปิด dialog แล้ว
      // ใช้ parentContext เพื่อเข้าถึง ProfileBloc
      widget.parentContext.read<ProfileBloc>().add(
        UpdateProfileField(field: widget.field, value: newValue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.title}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            labelText: widget.title,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter ${widget.title}';
            }
            return null;
          },
          maxLines: 1,
          onFieldSubmitted: (_) => _handleSave(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
