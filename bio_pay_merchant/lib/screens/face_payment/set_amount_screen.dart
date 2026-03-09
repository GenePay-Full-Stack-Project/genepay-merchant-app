import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/payment_api_service.dart';
import 'face_capture_screen.dart';

class SetAmountScreen extends StatefulWidget {
  const SetAmountScreen({super.key});

  @override
  State<SetAmountScreen> createState() => _SetAmountScreenState();
}

class _SetAmountScreenState extends State<SetAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final Color _navy = const Color(0xFF1E1E8B);
  final Color _accent = const Color(0xFFFF5722);
  final PaymentApiService _paymentService = PaymentApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _continueToFaceCapture() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get merchant ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final merchantId = prefs.getInt('merchant_id');

      if (merchantId == null) {
        throw Exception('Merchant ID not found. Please login again.');
      }

      // Call initiate payment API
      final response = await _paymentService.initiatePayment(
        merchantId: merchantId,
        amount: double.parse(amount),
        currency: 'LKR',
        description: 'Face payment transaction',
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        // Navigate to face capture screen with transaction ID
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FaceCaptureScreen(
              amount: amount,
              transactionId: response.data!.transactionId,
            ),
          ),
        );

        // If payment was successful, pop back to home
        // The result will be true if payment succeeded
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response.error ?? 'Failed to initiate payment');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          'Set Payment Amount',
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Premium Amount Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: Image.asset(
                  'assets/images/secure-payment.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 40),

              // Amount Input Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _navy.withOpacity(0.1), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: _navy,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: _navy.withOpacity(0.2),
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                    prefixIcon: Align(
                      alignment: Alignment.center,
                      widthFactor: 1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Text(
                          'Rs',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Quick Amount Buttons
              Text(
                'Quick Select',
                style: TextStyle(
                  color: _navy.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _QuickAmountButton(
                    amount: '100',
                    navy: _navy,
                    onTap: () => setState(() => _amountController.text = '100'),
                  ),
                  _QuickAmountButton(
                    amount: '500',
                    navy: _navy,
                    onTap: () => setState(() => _amountController.text = '500'),
                  ),
                  _QuickAmountButton(
                    amount: '1000',
                    navy: _navy,
                    onTap: () =>
                        setState(() => _amountController.text = '1000'),
                  ),
                  _QuickAmountButton(
                    amount: '1500',
                    navy: _navy,
                    onTap: () =>
                        setState(() => _amountController.text = '1500'),
                  ),
                  _QuickAmountButton(
                    amount: '5000',
                    navy: _navy,
                    onTap: () =>
                        setState(() => _amountController.text = '5000'),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Continue Button
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isLoading ? null : _continueToFaceCapture,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Continue to Face Scan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final String amount;
  final Color navy;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    required this.navy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: navy.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: navy.withOpacity(0.2), width: 1.5),
        ),
        child: Text(
          'Rs $amount',
          style: TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
