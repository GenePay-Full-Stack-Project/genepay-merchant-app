import 'package:flutter/material.dart';
import '../../models/transaction_response.dart';
import '../../services/transaction_api_service.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String transactionId;

  const PaymentSuccessScreen({super.key, required this.transactionId});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  static const Color _navy = const Color(0xFF1E1E8B);
  static const Color _accent = Color(0xFFFF5722);

  final TransactionApiService _transactionService = TransactionApiService();
  TransactionResponse? _transaction;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    try {
      await _transactionService.initialize();
      final transaction = await _transactionService.getTransactionById(
        widget.transactionId,
      );
      setState(() {
        _transaction = transaction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _navy),
              const SizedBox(height: 20),
              Text(
                'Loading transaction details...',
                style: TextStyle(color: _navy, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _transaction == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: _navy, size: 28),
            onPressed: () => Navigator.of(context).popUntil(
              (route) =>
                  route.settings.name == '/merchant_dashboard' || route.isFirst,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: _accent, size: 64),
                const SizedBox(height: 20),
                Text(
                  'Failed to load transaction details',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Unknown error',
                  style: TextStyle(color: _navy.withOpacity(0.6), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name == '/merchant_dashboard' ||
                        route.isFirst,
                  ),
                  child: const Text('Go Home', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: _navy, size: 28),
          onPressed: () {
            // Pop until we reach the merchant dashboard
            Navigator.of(context).popUntil(
              (route) =>
                  route.settings.name == '/merchant_dashboard' || route.isFirst,
            );
          },
        ),
        // title: Text(
        //   'Payment Confirmed',
        //   style: TextStyle(
        //     color: _navy,
        //     fontSize: 20,
        //     fontWeight: FontWeight.w700,
        //   ),
        // ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF18C34B),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4018C34B),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Transaction Successful!',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_transaction!.currency} ${_transaction!.amount.toStringAsFixed(2)} paid',
                  style: TextStyle(
                    color: _navy.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _navy.withOpacity(0.1), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction Details',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Success',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        label: 'Customer',
                        value: _transaction!.userName,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Amount',
                        value:
                            '${_transaction!.currency} ${_transaction!.amount.toStringAsFixed(2)}',
                        icon: Icons.attach_money_rounded,
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Transaction ID',
                        value: _transaction!.transactionId,
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Date & Time',
                        value:
                            '${_formatDate(_transaction!.completedAt ?? _transaction!.createdAt)} · ${_formatTime(_transaction!.completedAt ?? _transaction!.createdAt)}',
                        icon: Icons.access_time_rounded,
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Payment Method',
                        value: 'Biometric Payment',
                        icon: Icons.fingerprint,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _navy, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _navy.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: _navy,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 22,
                                ),
                                label: const Text(
                                  'Receipt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.home_rounded, size: 22),
                                label: const Text(
                                  'Home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).popUntil(
                                  (route) =>
                                      route.settings.name ==
                                          '/merchant_dashboard' ||
                                      route.isFirst,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _DetailRow({
    required String label,
    required String value,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? _navy.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? _navy.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? _navy : Colors.grey[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isHighlighted ? _navy : Colors.black87,
                    fontSize: isHighlighted ? 18 : 14,
                    fontWeight: isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
