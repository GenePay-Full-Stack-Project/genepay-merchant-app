import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/biometric_service.dart';
import '../qr/face_enrollment_qr_screen.dart';

class EnrollCustomerFaceScreen extends StatefulWidget {
  const EnrollCustomerFaceScreen({super.key});

  @override
  State<EnrollCustomerFaceScreen> createState() =>
      _EnrollCustomerFaceScreenState();
}

class _EnrollCustomerFaceScreenState extends State<EnrollCustomerFaceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _permissionGranted = false;

  final BiometricService _biometricService = BiometricService();

  static const Color _navy = Color(0xFF1E1E8B);
  static const Color _accent = Color(0xFFFF5722);
  static const Color _green = Color(0xFF18C34B);

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInitCamera();
  }

  Future<void> _requestPermissionAndInitCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      await _initCamera();
    } else {
      setState(() => _permissionGranted = false);
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use front camera for customer face capture
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _captureAndEnroll() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Capture image
      final image = await _cameraController!.takePicture();

      // Convert image to base64
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Show processing dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Processing face enrollment...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Call biometric service to enroll face
      // Get merchant ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final merchantId = prefs.getInt('merchant_id');

      if (merchantId == null) {
        throw BiometricException('Merchant ID not found. Please login again.');
      }

      final response = await _biometricService.enrollFace(
        imageBase64: base64Image,
        merchantId: merchantId,
      );

      // Close processing dialog
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.success) {
        // Validate that we have a face_id
        if (response.faceId == null || response.faceId!.isEmpty) {
          throw BiometricException(
            'Face enrollment succeeded but no face ID was returned',
          );
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Face Enrolled Successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Quality: ${(response.qualityScore ?? 0).toStringAsFixed(1)}% | '
                        'Liveness: ${response.livenessPasssed ? "Passed" : "Not checked"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: _green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to QR screen with face_id
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FaceEnrollmentQrScreen(
              faceId: response.faceId!,
              merchantId: merchantId,
            ),
          ),
        );
      } else {
        throw BiometricException(response.message);
      }
    } on BiometricException catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) {
        // Close processing dialog if still open
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enrollment Failed: ${e.message}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _captureAndEnroll(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        // Close processing dialog if still open
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to capture face: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Enroll Customer Face',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _navy,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _navy, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, _navy.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Face Enrollment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Position customer\'s face in the oval guide',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Camera Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _navy.withOpacity(0.2), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _buildCameraPreview(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _green.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: _green, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Ready to capture',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Capture Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, const Color(0xFFFF7A50)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isCapturing ? null : _captureAndEnroll,
                child: _isCapturing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Capture Face',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_permissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: _navy, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant camera access to enroll customers',
              textAlign: TextAlign.center,
              style: TextStyle(color: _navy.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermissionAndInitCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _navy),
            const SizedBox(height: 16),
            const Text(
              'Initializing camera...',
              style: TextStyle(
                color: _navy,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),

        // Face Guide Overlay
        Center(
          child: Container(
            width: 280,
            height: 380,
            decoration: BoxDecoration(
              border: Border.all(color: _green, width: 3),
              borderRadius: BorderRadius.circular(200),
            ),
            child: CustomPaint(painter: _FaceGuidePainter(color: _green)),
          ),
        ),

        // Corner Brackets
        Positioned.fill(
          child: Center(
            child: SizedBox(
              width: 280,
              height: 380,
              child: Stack(
                children: [
                  // Top-left
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBracket(color: _green),
                  ),
                  // Top-right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 1.5708,
                      child: _CornerBracket(color: _green),
                    ),
                  ),
                  // Bottom-left
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Transform.rotate(
                      angle: -1.5708,
                      child: _CornerBracket(color: _green),
                    ),
                  ),
                  // Bottom-right
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 3.14159,
                      child: _CornerBracket(color: _green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  final Color color;

  _FaceGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw horizontal center line
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
      paint,
    );

    // Draw vertical center line
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBracket extends StatelessWidget {
  final Color color;

  const _CornerBracket({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _BracketPainter(color: color)),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;

  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
