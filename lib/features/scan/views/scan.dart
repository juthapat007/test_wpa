import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:test_wpa/features/scan/views/qr_scanner_screen.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> with SingleTickerProviderStateMixin {
  String? _delegateId;
  String? _userName;

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
    String? name;
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        name = userData['name'];
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
                      'QR Code ไม่ถูกต้อง',
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
      backgroundColor: const Color(0xFFF9FAFB),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: space.m),
            _buildToggleModeButton(),
            const SizedBox(height: space.xl),
            if (_userName != null) ...[
              Text(
                '$_userName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: space.xs),
            ],

            Container(
              padding: const EdgeInsets.all(space.l),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                  const SizedBox(height: space.l),
                  if (_delegateId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: space.l,
                        vertical: space.m,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primaryLight.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: space.s),
                          Text(
                            'ID: $_delegateId',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: space.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleModeButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _openScanner,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: space.l,
            vertical: space.m,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.9),
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: space.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'สลับโหมด',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'สแกน QR Code คนอื่น',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: space.s),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
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
