import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';

String _encodeBase64(Uint8List bytes) {
  String mime = 'image/jpeg';
  if (bytes.length >= 4) {
    if (bytes[0] == 0x89 && bytes[1] == 0x50)
      mime = 'image/png';
    else if (bytes[0] == 0x52 && bytes[1] == 0x49)
      mime = 'image/webp';
  }
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

/// Reusable chat input field with send button + image picker
class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String imageBase64)? onSendImage;
  final VoidCallback? onChanged;
  final String? hintText;

  /// callback เมื่อ user เลือกรูป — ส่ง base64 data URI กลับไป

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.onSendImage,
    this.onChanged,
    this.hintText,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _picker = ImagePicker();
  bool _isSendingImage = false;

  // ── เลือกรูปจาก Gallery หรือ Camera ───────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // ตรวจขนาด — max 5MB
      const maxBytes = 5 * 1024 * 1024;
      if (bytes.lengthInBytes > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large (max 5MB)'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // ตรวจ format
      final mimeType = _detectMimeType(bytes);
      if (mimeType == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unsupported image type (jpeg, png, webp only)'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() => _isSendingImage = true);

      // ✅ encode ใน isolate — ไม่บล็อก UI
      final base64Uri = await compute(_encodeBase64, bytes);

      // ✅ แก้: widget.onSendImage?.call() ไม่ใช่ onSendImage()
      widget.onSendImage?.call(base64Uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  /// ตรวจ magic bytes เพื่อหา MIME type
  String? _detectMimeType(List<int> bytes) {
    if (bytes.length < 4) return null;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null; // format ไม่รองรับ (เช่น gif)
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ── ปุ่มเลือกรูป ─────────────────────────────────────────────────
            _isSendingImage
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.image, color: AppColors.primary),
                    onPressed: widget.onSendImage != null
                        ? () => _pickImage(ImageSource.gallery)
                        : null,
                  ),

            // ── ปุ่มถ่ายรูปจาก Camera ────────────────────────────────────────
            if (!_isSendingImage)
              IconButton(
                icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                onPressed: widget.onSendImage != null
                    ? () => _pickImage(ImageSource.camera)
                    : null,
              ),

            const SizedBox(width: 4),

            const SizedBox(width: 4),

            // ── Text field ────────────────────────────────────────────────────
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: (_) => widget.onChanged?.call(),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.border,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
              ),
            ),

            const SizedBox(width: 8),

            // ── Send button ───────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: widget.onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
