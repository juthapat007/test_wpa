// lib/features/scan/views/scan.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  String? _delegateId;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadDelegateId();
  }

  Future<void> _loadDelegateId() async {
    final id = await _storage.read(key: 'delegate_id');
    setState(() {
      _delegateId = id;
    });

    if (id != null && mounted) {
      context.read<ScanBloc>().add(LoadQrCode(id));
    }
  }

  void _refreshQrCode() {
    if (_delegateId != null) {
      context.read<ScanBloc>().add(RefreshQrCode(_delegateId!));
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
    return RefreshIndicator(
      onRefresh: () async {
        _refreshQrCode();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: space.xl),

              // ข้อความแนะนำ
              Text(
                'QR Code ของคุณ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: space.s),
              Text(
                'แสดง QR Code นี้เพื่อเช็คอิน',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: space.xl),

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(space.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // QR Code Image
                    Container(
                      padding: const EdgeInsets.all(space.m),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: _buildQrCodeImage(qrCodeBase64),
                    ),

                    const SizedBox(height: space.l),

                    // Delegate ID
                    if (_delegateId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: space.m,
                          vertical: space.s,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: $_delegateId',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: space.xl),

              // ปุ่ม Refresh
              OutlinedButton.icon(
                onPressed: _refreshQrCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh QR Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: space.l,
                    vertical: space.m,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: space.xl),

              // คำแนะนำการใช้งาน
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCodeImage(String qrCodeBase64) {
    try {
      // ตรวจสอบว่ามี prefix หรือไม่
      final base64String = qrCodeBase64.contains(',')
          ? qrCodeBase64.split(',').last
          : qrCodeBase64;

      final bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        width: 280,
        height: 280,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildQrCodeError();
        },
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
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(space.m),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: space.s),
              Text(
                'วิธีใช้งาน',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: space.m),
          _buildInstructionItem('1. แสดง QR Code นี้ต่อเจ้าหน้าที่'),
          _buildInstructionItem('2. สแกน QR Code เพื่อเช็คอิน'),
          _buildInstructionItem('3. ดึงลงเพื่อ Refresh QR Code'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
          const SizedBox(width: space.s),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2,
            size: 120,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: space.l),
          Text(
            'ไม่พบ QR Code',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: space.s),
          Text(
            'กรุณาลองใหม่อีกครั้ง',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 120,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: space.l),
            Text(
              'เกิดข้อผิดพลาด',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: space.s),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: space.l),
            ElevatedButton.icon(
              onPressed: _refreshQrCode,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: space.l,
                  vertical: space.m,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
