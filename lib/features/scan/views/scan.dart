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

    // Animation for button tap effect
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

  void _refreshQrCode() {
    if (_delegateId != null) {
      ReadContext(context).read<ScanBloc>().add(RefreshQrCode(_delegateId!));
    }
  }

  Future<void> _openScanner() async {
    _animationController.forward().then((_) => _animationController.reverse());

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      // ✅ นำทางไปหน้า other_profile โดยส่ง delegate_id ที่สแกนได้
      _navigateToOtherProfile(result);
    }
  }

  void _navigateToOtherProfile(String qrData) {
    // 🔍 Debug: แสดง QR data ที่สแกนได้
    print('📱 QR Data scanned: $qrData');
    print('📱 QR Data length: ${qrData.length}');
    print('📱 QR Data type: ${qrData.runtimeType}');

    try {
      int? delegateId;

      // ตัด whitespace
      qrData = qrData.trim();

      // 🔍 กรณีที่ 1: QR Code เป็น JSON object
      if (qrData.startsWith('{') && qrData.endsWith('}')) {
        print('📋 Parsing as JSON...');
        final jsonData = jsonDecode(qrData);
        print('📋 JSON Data: $jsonData');
        print('📋 JSON Keys: ${jsonData.keys.toList()}');

        // ลองหา key ต่างๆ ที่อาจเป็น delegate_id
        if (jsonData.containsKey('delegate_id')) {
          delegateId = int.tryParse(jsonData['delegate_id'].toString());
          print('📋 Found delegate_id: $delegateId');
        } else if (jsonData.containsKey('id')) {
          delegateId = int.tryParse(jsonData['id'].toString());
          print('📋 Found id: $delegateId');
        } else if (jsonData.containsKey('delegateId')) {
          delegateId = int.tryParse(jsonData['delegateId'].toString());
          print('📋 Found delegateId: $delegateId');
        } else {
          print('❌ No delegate_id field found in JSON');
          print('📋 Available keys: ${jsonData.keys.join(", ")}');
        }
      }
      // 🔍 กรณีที่ 2: QR Code เป็นตัวเลขโดยตรง
      else {
        print('🔢 Parsing as plain number...');
        delegateId = int.tryParse(qrData);
        print('🔢 Parsed result: $delegateId');
      }

      // ตรวจสอบว่าได้ delegate_id หรือไม่
      if (delegateId == null) {
        throw Exception('Cannot parse delegate_id from QR data: $qrData');
      }

      print('✅ Delegate ID parsed: $delegateId');

      // ✅ นำทางไปหน้า other_profile พร้อม delegate_id
      Modular.to.pushNamed(
        '/other_profile',
        arguments: {'delegate_id': delegateId},
      );

      print('🚀 Navigating to /other_profile with ID: $delegateId');
    } catch (e, stackTrace) {
      print('❌ Error parsing QR code: $e');
      print('📍 Stack trace: $stackTrace');
      // แสดง error message ที่ละเอียดกว่า
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Data: ${qrData.length > 50 ? qrData.substring(0, 50) + "..." : qrData}',
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
              const SizedBox(height: space.m),

              // Toggle Mode Button
              _buildToggleModeButton(),

              const SizedBox(height: space.xl),

              // ข้อความต้อนรับ
              if (_userName != null) ...[
                Text(
                  'สวัสดี, $_userName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: space.xs),
              ],

              // ข้อความแนะนำ
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
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // QR Code Image
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

                    // Delegate ID Badge
                    if (_delegateId != null) ...[
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
                  ],
                ),
              ),

              const SizedBox(height: space.xl),

              // ปุ่ม Refresh
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _refreshQrCode,
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: space.s),
                        Text(
                          'Refresh QR Code',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
          errorBuilder: (context, error, stackTrace) {
            return _buildQrCodeError();
          },
        ),
      );
    } catch (e) {
      print('Error decoding QR code: $e');
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

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(space.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primaryLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: space.m),
              Text(
                'วิธีใช้งาน',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: space.m),
          _buildInstructionItem(
            '1',
            'แสดง QR Code นี้ต่อเจ้าหน้าที่ ณ จุดลงทะเบียน',
          ),
          _buildInstructionItem(
            '2',
            'กดปุ่ม "สแกน QR Code คนอื่น" เพื่อดูโปรไฟล์และตารางของผู้เข้าร่วมคนอื่น',
          ),
          _buildInstructionItem('3', 'ดึงลงเพื่อ Refresh QR Code ถ้าจำเป็น'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: space.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: space.m),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
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
            const SizedBox(height: space.xl),
            ElevatedButton.icon(
              onPressed: _refreshQrCode,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: space.xl,
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
            const SizedBox(height: space.xl),
            ElevatedButton.icon(
              onPressed: _refreshQrCode,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: space.xl,
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
