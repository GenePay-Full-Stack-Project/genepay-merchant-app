import '../models/transaction_response.dart';
import 'api_service.dart';

/// Paginated transaction response model
class PaginatedTransactionResponse {
  final List<TransactionResponse> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;

  PaginatedTransactionResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
  });

  factory PaginatedTransactionResponse.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    return PaginatedTransactionResponse(
      content: contentList
          .map(
            (item) =>
                TransactionResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
    );
  }
}

/// Transaction statistics model
class TransactionStats {
  final int total;
  final int completed;
  final int pending;
  final int failed;
  final int refunded;
  final double totalAmount;

  TransactionStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.failed,
    required this.refunded,
    required this.totalAmount,
  });
}

class TransactionApiService {
  final ApiService _apiService;

  TransactionApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Initialize the service
  Future<void> initialize() async {
    await _apiService.initialize();
  }

  /// Get merchant transactions with pagination
  ///
  /// [merchantId] - The merchant's ID
  /// [page] - Page number (default: 0)
  /// [size] - Number of items per page (default: 20)
  Future<PaginatedTransactionResponse> getMerchantTransactions(
    int merchantId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/payments/merchant/$merchantId?page=$page&size=$size',
        (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        return PaginatedTransactionResponse.fromJson(response.data!);
      } else {
        throw ApiException(response.message ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      throw ApiException('Error fetching transactions: ${e.toString()}');
    }
  }

  /// Get transaction details by transaction ID
  ///
  /// [transactionId] - The transaction ID (e.g., "TXN-20250001")
  Future<TransactionResponse> getTransactionById(String transactionId) async {
    try {
      final response = await _apiService.get<TransactionResponse>(
        '/payments/$transactionId',
        (json) => TransactionResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw ApiException(
          response.message ?? 'Failed to fetch transaction details',
        );
      }
    } catch (e) {
      throw ApiException('Error fetching transaction: ${e.toString()}');
    }
  }

  /// Refund a transaction
  ///
  /// [transactionId] - The transaction ID to refund
  /// [reason] - Reason for the refund
  Future<TransactionResponse> refundTransaction(
    String transactionId,
    String reason,
  ) async {
    try {
      final response = await _apiService.post<TransactionResponse>(
        '/payments/$transactionId/refund?reason=${Uri.encodeComponent(reason)}',
        {},
        (json) => TransactionResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw ApiException(response.message ?? 'Failed to refund transaction');
      }
    } catch (e) {
      throw ApiException('Error refunding transaction: ${e.toString()}');
    }
  }

  /// Get total sales for merchant
  ///
  /// [merchantId] - The merchant's ID
  /// [fromDate] - Optional start date filter
  /// [toDate] - Optional end date filter
  Future<double> getTotalSales(
    int merchantId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final transactions = await getMerchantTransactions(merchantId, size: 100);

      double total = 0.0;
      for (var t in transactions.content) {
        if (t.status.toUpperCase() == 'COMPLETED') {
          // Apply date filters if provided
          if (fromDate != null && t.createdAt.isBefore(fromDate)) continue;
          if (toDate != null && t.createdAt.isAfter(toDate)) continue;

          total += t.amount;
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get today's sales for merchant
  Future<double> getTodaySales(int merchantId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getTotalSales(merchantId, fromDate: startOfDay, toDate: endOfDay);
  }

  /// Get transaction statistics for merchant
  Future<TransactionStats> getTransactionStats(int merchantId) async {
    try {
      final transactions = await getMerchantTransactions(merchantId, size: 100);

      int completed = 0;
      int pending = 0;
      int failed = 0;
      int refunded = 0;
      double totalAmount = 0.0;

      for (var t in transactions.content) {
        switch (t.status.toUpperCase()) {
          case 'COMPLETED':
            completed++;
            totalAmount += t.amount;
            break;
          case 'PENDING':
            pending++;
            break;
          case 'FAILED':
            failed++;
            break;
          case 'REFUNDED':
            refunded++;
            break;
        }
      }

      return TransactionStats(
        total: transactions.content.length,
        completed: completed,
        pending: pending,
        failed: failed,
        refunded: refunded,
        totalAmount: totalAmount,
      );
    } catch (e) {
      return TransactionStats(
        total: 0,
        completed: 0,
        pending: 0,
        failed: 0,
        refunded: 0,
        totalAmount: 0.0,
      );
    }
  }
}
