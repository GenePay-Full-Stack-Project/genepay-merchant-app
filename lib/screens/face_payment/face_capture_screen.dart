import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/payment_api_service.dart';
import 'payment_success_screen.dart';
import '../face_enrollment/enroll_customer_face_screen.dart';

class FaceCaptureScreen extends StatefulWidget {
  final String amount;
  final String transactionId;

  const FaceCaptureScreen({
    super.key,
    required this.amount,
    required this.transactionId,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  static const Color _navy = Color(0xFF1E1E8B);
  static const Color _accent = Color(0xFFFF5722);

  File? _capturedImage;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  final bool _isProcessing = false;
  final bool _processedSuccess = false;
  final PaymentApiService _paymentService = PaymentApiService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showErrorDialog(
          'Camera permission',
          'Camera permission is required to capture a face. Please enable it in system settings.',
        );
        return;
      }

      _cameras = await availableCameras();
      CameraDescription? frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () =>
            _cameras.isNotEmpty ? _cameras.first : throw 'No cameras found',
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } on PlatformException catch (e) {
      _showErrorDialog('Camera init failed', e.message ?? e.toString());
    } catch (e) {
      _showErrorDialog('Camera init failed', e.toString());
    }
  }

  // Combined capture and process payment method
  Future<void> _captureAndProcessPayment() async {
    try {
      // Step 1: Capture face
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _showErrorDialog('Camera not ready', 'Camera is not initialized yet.');
        return;
      }

      final XFile xfile = await _cameraController!.takePicture();
      final capturedImage = File(xfile.path);

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _navy),
                const SizedBox(height: 20),
                Text(
                  'Verifying face & processing payment...',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      // Step 2: Convert image to base64 and call API
      final imageBytes = await capturedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await _paymentService.verifyAndCharge(
        transactionId: widget.transactionId,
        faceData: base64Image,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.success && response.data != null) {
        final paymentData = response.data!;

        if (paymentData.verified && paymentData.status == 'COMPLETED') {
          // Navigate to success screen
          final result = await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PaymentSuccessScreen(transactionId: widget.transactionId),
            ),
          );

          // If user went home from success screen, pop this screen too
          if (result == true && mounted) {
            Navigator.pop(context, true);
          }
        } else {
          _showErrorDialog(
            'Verification Failed',
            paymentData.message.isNotEmpty
                ? paymentData.message
                : 'Face verification failed. Please try again.',
          );
        }
      } else {
        final errorMsg = response.error ?? 'Payment processing failed';

        if (errorMsg.toLowerCase().contains('not enrolled') ||
            errorMsg.toLowerCase().contains('no matching user')) {
          _showErrorDialog(
            'Face Not Enrolled',
            'This customer has not completed face enrollment.\\n\\nPlease ask the customer to:\\n1. Open their BioPay app\\n2. Navigate to "Enroll Face"\\n3. Scan the QR code you will generate\\n\\nOr use "Enroll Customer" from the home screen to register them now.',
          );
        } else {
          _showErrorDialog('Payment Failed', errorMsg);
        }
      }
    } on CameraException catch (e) {
      if (!mounted) return;
      _showErrorDialog('Capture failed', e.description ?? e.code);
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog if open
      }
      _showErrorDialog('Error', 'An error occurred: ${e.toString()}');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_rounded, color: _accent, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  color: _navy.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _navy.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(
                          context,
                        ).pop(); // Close face capture screen
                        // Navigate to Enroll Customer screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EnrollCustomerFaceScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Enroll Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _navy, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Customer Face',
          style: TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Info Card explaining the process
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _navy.withOpacity(0.1), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _navy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.info_outline, color: _navy, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Face Verification Payment',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer must be enrolled first',
                            style: TextStyle(
                              color: _navy.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Amount Display Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navy, _navy.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    const Text(
                      'Amount: ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'LKR ${widget.amount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // PREMIUM CAMERA / CAPTURE BOX
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navy.withOpacity(0.1), _navy.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _navy.withOpacity(0.2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 380,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // preview or captured image
                        if (_capturedImage != null)
                          Image.file(_capturedImage!, fit: BoxFit.cover)
                        else if (_isCameraInitialized &&
                            _cameraController != null)
                          CameraPreview(_cameraController!)
                        else
                          Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: _navy),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Initializing camera...',
                                    style: TextStyle(
                                      color: _navy.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Premium frame overlay
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _navy.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Success checkmark when processed
                        if (_processedSuccess)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF18C34B),
                                    Color(0xFF0F9A38),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),

                        // Premium face guide overlay with modern design
                        if (_capturedImage == null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 220,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(140),
                                    border: Border.all(
                                      color: _navy.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Top-left corner
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(140),
                                                ),
                                            border: Border(
                                              left: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                              top: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Top-right corner
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topRight: Radius.circular(
                                                    140,
                                                  ),
                                                ),
                                            border: Border(
                                              right: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                              top: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Bottom-left corner
                                      Positioned(
                                        left: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    140,
                                                  ),
                                                ),
                                            border: Border(
                                              left: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                              bottom: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Bottom-right corner
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomRight: Radius.circular(
                                                    140,
                                                  ),
                                                ),
                                            border: Border(
                                              right: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                              bottom: BorderSide(
                                                color: _navy,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Status Text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _processedSuccess
                      ? Colors.green.withOpacity(0.1)
                      : _isProcessing
                      ? _navy.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: _processedSuccess || _isProcessing
                      ? Border.all(
                          color: _processedSuccess ? Colors.green : _navy,
                          width: 1.5,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_processedSuccess)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 20,
                      )
                    else if (_isProcessing)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: _navy,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Icon(
                        Icons.face_rounded,
                        color: _navy.withOpacity(0.6),
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _processedSuccess
                          ? 'Face captured successfully!'
                          : (_isProcessing
                                ? 'Processing face...'
                                : 'Position face in the oval'),
                      style: TextStyle(
                        color: _processedSuccess ? Colors.green : _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // VERIFY & PROCESS PAYMENT BUTTON - Captures and processes in one action
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF18C34B), Color(0xFF0F9A38)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  label: const Text(
                    'Verify & Process Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: _captureAndProcessPayment,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
