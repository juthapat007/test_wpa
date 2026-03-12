import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:test_wpa/features/profile/presentation/bloc/profile_event.dart';

class ProfileAvatar extends StatefulWidget {
  final String avatarUrl;
  const ProfileAvatar({super.key, required this.avatarUrl});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _token;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final storage = Modular.get<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');
    if (mounted) setState(() => _token = token);
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);
    ReadContext(
      context,
    ).read<ProfileBloc>().add(UpdateAvatar(File(picked.path)));
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.avatarUrl.trim();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // avatar แค่แสดงรูป ไม่ต้อง onTap แล้ว
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : imageUrl.isNotEmpty && _token != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: 110,
                          height: 110,
                          headers: {
                            'Authorization': 'Bearer $_token',
                            'Accept': 'image/*',
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                          errorBuilder: (_, __, ___) => _defaultAvatar(),
                        )
                      : _defaultAvatar(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: _pickAndUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Change photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
    );
  }
}
