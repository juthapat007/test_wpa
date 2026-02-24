import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:test_wpa/features/scan/views/qr_scanner_screen.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> with SingleTickerProviderStateMixin {
  String? _delegateId;
  String? _userName;
  String? _userTitle;
  String? _userCompany;
  String? _userTeam;
  String? _currentQrBase64;

  final _storage = const FlutterSecureStorage();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final id = await _storage.read(key: 'delegate_id');
    final userDataStr = await _storage.read(key: 'user_data');

    String? name, title, company, team;
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        name = userData['name'];
        title = userData['title'];
        company = userData['company']?['name'] ?? userData['company'];
        team = userData['team']?['name'] ?? userData['team'];
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }

    setState(() {
      _delegateId = id;
      _userName = name;
    });

    if (id != null && mounted) {
      ReadContext(context).read<ScanBloc>().add(LoadQrCode(id));
    }
  }

  Future<void> _openScanner() async {
    _animationController.forward().then((_) => _animationController.reverse());

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      _navigateToOtherProfile(result);
    }
  }

  void _navigateToOtherProfile(String qrData) {
    try {
      int? delegateId;
      qrData = qrData.trim();

      if (qrData.startsWith('{') && qrData.endsWith('}')) {
        final jsonData = jsonDecode(qrData);
        if (jsonData.containsKey('delegate_id')) {
          delegateId = int.tryParse(jsonData['delegate_id'].toString());
        } else if (jsonData.containsKey('id')) {
          delegateId = int.tryParse(jsonData['id'].toString());
        } else if (jsonData.containsKey('delegateId')) {
          delegateId = int.tryParse(jsonData['delegateId'].toString());
        }
      } else {
        delegateId = int.tryParse(qrData);
      }

      if (delegateId == null) {
        throw Exception('Cannot parse delegate_id from QR data: $qrData');
      }

      Modular.to.pushNamed(
        '/other_profile',
        arguments: {'delegate_id': delegateId},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: space.m),
                  const Expanded(
                    child: Text(
                      'QR Code wrong',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: space.s),
              Text(
                'Data: ${qrData.length > 50 ? '${qrData.substring(0, 50)}...' : qrData}',
                style: const TextStyle(fontSize: 12),
              ),
              Text('Error: $e', style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'QR CODE',
      currentIndex: 2,
      backgroundColor: AppColors.background,
      appBarStyle: AppBarStyle.elegant,
      body: _delegateId == null
          ? const Center(child: CircularProgressIndicator())
          : BlocBuilder<ScanBloc, ScanState>(
              builder: (context, state) {
                if (state is ScanLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ScanError) {
                  return _buildErrorState(state.message);
                }
                if (state is ScanLoaded) {
                  return _buildQrCodeView(state.qrCodeBase64);
                }
                return _buildEmptyState();
              },
            ),
    );
  }

  Widget _buildQrCodeView(String qrCodeBase64) {
    _currentQrBase64 = qrCodeBase64;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_userName != null) ...[
              Text(
                '$_userName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_userTitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  '$_userTitle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              SizedBox(height: space.m),
            ],

            Container(
              padding: const EdgeInsets.all(space.l),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(space.l),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: _buildQrCodeImage(qrCodeBase64),
                  ),
                ],
              ),
            ),
            const SizedBox(height: space.l),

            // ========== Action Buttons ==========
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan QR',
                  color: AppColors.secondary,
                  onTap: _openScanner,
                ),
                _buildActionButton(
                  icon: Icons.download_rounded,
                  label: 'Save QR',
                  color: AppColors.primary,
                  onTap: _saveQrCode,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: AppColors.primaryLight,
                  onTap: _shareQrCode,
                ),
              ],
            ),
            const SizedBox(height: space.m),
          ],
        ),
      ),
    );
  }

  // ========== Action Button Widget ==========

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(space.m),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(
                16,
              ), // 👈 เปลี่ยนจาก shape: BoxShape.circle
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: space.s),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ========== Save QR ==========
  // Future<void> _saveQrCode() async {
  //   // TODO: implement save to gallery
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: const Row(
  //         children: [
  //           Icon(Icons.check_circle, color: Colors.white),
  //           SizedBox(width: 8),
  //           Text('QR Code saved to gallery'),
  //         ],
  //       ),
  //       backgroundColor: AppColors.primary,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }
  // ========== Save QR to Gallery ==========
  Future<void> _saveQrCode() async {
    if (_currentQrBase64 == null) return;

    try {
      final base64String = _currentQrBase64!.contains(',')
          ? _currentQrBase64!.split(',').last
          : _currentQrBase64!;
      final bytes = base64Decode(base64String);

      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(bytes),
        quality: 100,
        name:
            'QR_${_delegateId ?? 'code'}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      final success = result['isSuccess'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'บันทึก QR Code ลงแกลเลอรีแล้ว' : 'บันทึกไม่สำเร็จ',
              ),
            ],
          ),
          backgroundColor: success ? AppColors.primary : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ========== Share QR ==========
  Future<void> _shareQrCode() async {
    if (_currentQrBase64 == null) return;

    try {
      final base64String = _currentQrBase64!.contains(',')
          ? _currentQrBase64!.split(',').last
          : _currentQrBase64!;
      final bytes = base64Decode(base64String);

      // เขียนไฟล์ชั่วคราว
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_${_delegateId ?? 'code'}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'QR Code${_userName != null ? " ของ $_userName" : ""}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ========== Search Dialog ==========
  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Search by ID'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter Delegate ID',
              prefixIcon: const Icon(Icons.person_search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) {
              final id = int.tryParse(controller.text.trim());
              if (id != null) {
                Navigator.pop(ctx);
                Modular.to.pushNamed(
                  '/other_profile',
                  arguments: {'delegate_id': id},
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final id = int.tryParse(controller.text.trim());
                if (id != null) {
                  Navigator.pop(ctx);
                  Modular.to.pushNamed(
                    '/other_profile',
                    arguments: {'delegate_id': id},
                  );
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQrCodeImage(String qrCodeBase64) {
    try {
      final base64String = qrCodeBase64.contains(',')
          ? qrCodeBase64.split(',').last
          : qrCodeBase64;
      final bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildQrCodeError(),
        ),
      );
    } catch (e) {
      return _buildQrCodeError();
    }
  }

  Widget _buildQrCodeError() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: space.m),
          Text(
            'ไม่สามารถแสดง QR Code',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: space.s),
          Text(
            'กรุณาลองใหม่อีกครั้ง',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(space.xl),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 100,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: space.xl),
            Text(
              'ไม่พบ QR Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: space.m),
            Text(
              'กรุณาลองใหม่อีกครั้ง หรือติดต่อเจ้าหน้าที่',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(space.xl),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 100,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: space.xl),
            Text(
              'เกิดข้อผิดพลาด',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: space.m),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
