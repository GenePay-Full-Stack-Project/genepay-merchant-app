import 'package:flutter/material.dart';

import 'face_payment/set_amount_screen.dart';
import 'transaction/transaction_history_screen.dart';
import 'package:bio_pay_merchant/screens/analytics_screen.dart';
import 'transaction/transaction_details_screen.dart';
import 'profile/profile_screen.dart';
import 'payment_methods/payment_methods_screen.dart';
import '../services/api_service.dart';
import '../models/merchant_response.dart';
import '../models/transaction_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen>
    with RouteAware {
  final Color _navy = const Color(0xFF1E1E8B);
  final Color _panel = const Color(0xFF1B1B7A);
  final Color _accent = const Color(0xFFFF5722);
  final Color _mutedText = const Color(0xFF6F6F96);

  final ApiService _apiService = ApiService();
  MerchantResponse? _merchant;
  List<TransactionResponse> _recentTransactions = [];
  double _todaySales = 0.0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes to refresh data when coming back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        route.didPush().then((_) {
          // Screen was just pushed
        });
      }
    });
  }

  Future<void> _loadMerchantData() async {
    if (!mounted) return; // Check if widget is still mounted

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.initialize();

      // Get merchant ID from shared preferences
      final prefs = await SharedPreferences.getInstance();

      // Reload to ensure we have the latest data
      await prefs.reload();

      final merchantId = prefs.getInt('merchant_id');

      if (merchantId == null) {
        throw Exception('Merchant ID not found. Please log in again.');
      }

      final merchant = await _apiService.getMerchantById(merchantId);

      final transactions = await _apiService.getMerchantTransactions(
        merchantId,
        size: 20, // Fetch more to ensure we have enough after filtering
      );

      // Filter to show only COMPLETED transactions
      final completedTransactions = transactions
          .where((t) => t.status.toUpperCase() == 'COMPLETED')
          .take(3)
          .toList();

      final todaySales = await _apiService.getTodaySales(merchantId);

      if (!mounted) return; // Check again before calling setState

      setState(() {
        _merchant = merchant;
        _recentTransactions = completedTransactions;
        _todaySales = todaySales;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Check again before calling setState

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
        body: Center(child: CircularProgressIndicator(color: _navy)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: _accent),
              const SizedBox(height: 16),
              Text(
                'Error loading data in Home',
                style: TextStyle(
                  fontSize: 18,
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _mutedText),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMerchantData,
                style: ElevatedButton.styleFrom(backgroundColor: _navy),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadMerchantData,
        color: _navy,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            // TOP HEADER WITH PROFILE
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _merchant?.businessName ?? 'Loading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MR-${_merchant?.id.toString().padLeft(4, '0') ?? '----'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // CONTENT SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // TODAY'S SALES CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _navy.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Sales",
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LKR ${(_todaySales * 0.97).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _navy.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.money, color: _navy, size: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 10,
                        //     vertical: 6,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: const Color(0xFF4CAF50).withOpacity(0.12),
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   child: Text(
                        //     '+15% vs yesterday',
                        //     style: TextStyle(
                        //       color: const Color(0xFF4CAF50),
                        //       fontSize: 13,
                        //       fontWeight: FontWeight.w700,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SetAmountScreen(),
                              ),
                            );
                            // Refresh data when returning from payment flow
                            _loadMerchantData();
                          },
                          child: _ActionButton(
                            label: 'Start Payment',
                            icon: Icons.touch_app,
                            filled: true,
                            accent: _accent,
                            navy: _navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TransactionHistoryScreen(),
                              ),
                            );
                          },
                          child: _ActionButton(
                            label: 'Transaction History',
                            icon: Icons.receipt_long,
                            filled: false,
                            accent: _accent,
                            navy: _navy,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // QUICK ACTIONS HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _navy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          color: _navy,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // QUICK ACTIONS GRID
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentMethodsScreen(),
                            ),
                          ),
                          child: _FeatureCard(
                            icon: Icons.credit_card,
                            label: 'Payment Cards',
                            panel: _panel,
                            accent: _accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionHistoryScreen(),
                            ),
                          ),
                          child: _FeatureCard(
                            icon: Icons.history,
                            label: 'Transactions',
                            panel: _panel,
                            accent: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AnalyticsScreen(),
                            ),
                          ),
                          child: _FeatureCard(
                            icon: Icons.show_chart,
                            label: 'Analytics',
                            panel: _panel,
                            accent: _accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: _FeatureCard(
                            icon: Icons.person_rounded,
                            label: 'Profile Settings',
                            panel: _panel,
                            accent: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // RECENT TRANSACTIONS HEADER
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TRANSACTIONS CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _navy.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _recentTransactions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 56,
                                    color: _mutedText.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No recent transactions',
                                    style: TextStyle(
                                      color: _mutedText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completed transactions will appear here',
                                    style: TextStyle(
                                      color: _mutedText.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: _recentTransactions.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final transaction = entry.value;
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TransactionDetailsScreen(
                                              transactionId:
                                                  transaction.transactionId,
                                            ),
                                      ),
                                    ),
                                    child: _TransactionItem(
                                      name: transaction.userName,
                                      time: _formatTimeAgo(
                                        transaction.createdAt,
                                      ),
                                      amount: transaction.amount,
                                      status: transaction.status,
                                      navy: _navy,
                                    ),
                                  ),
                                  if (index < _recentTransactions.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday · ${_formatTime(dateTime)}';
      } else {
        return '${difference.inDays} days ago';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final Color accent;
  final Color navy;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.accent,
    required this.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: filled ? accent : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: filled ? Colors.transparent : navy.withOpacity(0.12),
          width: 1.4,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: filled ? Colors.white : navy, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color panel;
  final Color accent;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.panel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 44),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String name;
  final String time;
  final double amount;
  final String status;
  final Color navy;

  const _TransactionItem({
    required this.name,
    required this.time,
    required this.amount,
    required this.status,
    required this.navy,
  });

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF4CAF50); // Green
      case 'PENDING':
        return const Color(0xFFFFA726); // Orange
      case 'FAILED':
        return const Color(0xFFEF5350); // Red
      case 'REFUNDED':
        return const Color(0xFF42A5F5); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  String _formatStatus() {
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: navy.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          // Transaction Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF1E1E8B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                status.toUpperCase() == 'COMPLETED'
                    ? 'assets/images/cart.png'
                    : 'assets/images/pending.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+LKR ${(amount * 0.97).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatStatus(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
