import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/transaction_response.dart';
import '../../services/transaction_api_service.dart';
import 'transaction_details_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final Color _navy = const Color(0xFF1E1E8B);
  final Color _muted = const Color(0xFF6F6F96);

  final TransactionApiService _transactionService = TransactionApiService();

  List<TransactionResponse> _transactions = [];
  List<TransactionResponse> _filteredTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _merchantId;

  String _filter = 'All';
  List<bool> _visible = [];
  bool _showExport = false;
  double _totalReceived = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMerchantIdAndTransactions();
  }

  Future<void> _loadMerchantIdAndTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final merchantId = prefs.getInt('merchant_id');

      if (merchantId == null) {
        setState(() {
          _errorMessage = 'Merchant ID not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      setState(() => _merchantId = merchantId);
      await _loadTransactions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading merchant data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    if (_merchantId == null) return;

    setState(() => _isLoading = true);

    try {
      await _transactionService.initialize();
      final response = await _transactionService.getMerchantTransactions(
        _merchantId!,
        size: 100,
      );

      setState(() {
        _transactions = response.content;
        _applyFilter();
        _calculateTotal();
        _isLoading = false;
      });

      _runStagger();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading transactions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_filter == 'All') {
      _filteredTransactions = _transactions;
    } else if (_filter == 'Successful') {
      _filteredTransactions = _transactions
          .where((t) => t.status.toUpperCase() == 'COMPLETED')
          .toList();
    } else {
      _filteredTransactions = _transactions
          .where((t) => t.status.toUpperCase() != 'COMPLETED')
          .toList();
    }
    _visible = List<bool>.filled(_filteredTransactions.length, false);
  }

  void _calculateTotal() {
    _totalReceived = _transactions
        .where((t) => t.status.toUpperCase() == 'COMPLETED')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void _runStagger() async {
    for (var i = 0; i < _filteredTransactions.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _visible[i] = true);
    }
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showExport = true);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today · ${_formatTime(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · ${_formatTime(date)}';
    } else {
      return '${date.month}/${date.day} · ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'PENDING':
        return const Color(0xFFFFA726);
      case 'FAILED':
        return const Color(0xFFEF5350);
      case 'REFUNDED':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _navy,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _navy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTransactions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _navy,
              gradient: LinearGradient(
                colors: [_navy, _navy.withOpacity(0.92)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Top app bar area with back button and title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Transaction History',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Total + search placed on the blue/navy area (above white panel)
          Positioned(
            top: 116,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Received: LKR ${(_totalReceived * 0.97).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // Search functionality disabled for now
                            // Can implement search later if needed
                          },
                          child: const Text(
                            'Search',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          // Date range picker disabled for now
                          // Can add filtering by date range later
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // White rounded panel (lowered so total/search sit above it)
          Positioned.fill(
            top: 200,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
              ),
              child: Padding(
                // slightly reduce top padding so chips sit closer to panel top
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    // chips (All / Successful / Pending)
                    Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Successful'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Pending'),
                      ],
                    ),
                    // Transactions list with staggered fade/slide
                    Expanded(
                      child: _filteredTransactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 80,
                                    color: _muted.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No transactions found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Transactions will appear here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _muted.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredTransactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final t = _filteredTransactions[i];
                                final visible = i < _visible.length
                                    ? _visible[i]
                                    : true;

                                return AnimatedOpacity(
                                  duration: const Duration(milliseconds: 380),
                                  opacity: visible ? 1.0 : 0.0,
                                  curve: Curves.easeOut,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TransactionDetailsScreen(
                                                transactionId: t.transactionId,
                                              ),
                                        ),
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 420,
                                      ),
                                      transform: Matrix4.translationValues(
                                        0,
                                        visible ? 0 : 12,
                                        0,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: _navy.withOpacity(0.08),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Transaction Icon
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: Color(
                                                0xFF1E1E8B,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                10.0,
                                              ),
                                              child: Image.asset(
                                                t.status.toUpperCase() ==
                                                        'COMPLETED'
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        t.userName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 16,
                                                          color:
                                                              t.userId == null
                                                              ? Colors.grey
                                                              : _navy,
                                                          fontStyle:
                                                              t.userId == null
                                                              ? FontStyle.italic
                                                              : FontStyle
                                                                    .normal,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '+LKR ${(t.amount * 0.97).toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: _getStatusColor(
                                                          t.status,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color: _muted
                                                              .withOpacity(0.8),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          _formatDate(
                                                            t.createdAt,
                                                          ),
                                                          style: TextStyle(
                                                            color: _muted,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                          t.status,
                                                        ).withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        _formatStatus(t.status),
                                                        style: TextStyle(
                                                          color:
                                                              _getStatusColor(
                                                                t.status,
                                                              ),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
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
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Export button docked (fade/scale-in)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 420),
              opacity: _showExport ? 1 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 420),
                scale: _showExport ? 1 : 0.94,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.download,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Export Reports',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final active = _filter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = label;
          _applyFilter();
        });
        _runStagger();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _navy : _navy.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _navy.withOpacity(0.12)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
