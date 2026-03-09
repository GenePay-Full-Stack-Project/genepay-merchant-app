class TransactionResponse {
  final int id;
  final String transactionId;
  final int? userId;
  final String userName;
  final int merchantId;
  final String merchantName;
  final double amount;
  final String currency;
  final String status;
  final String type;
  final String? description;
  final bool biometricVerified;
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionResponse({
    required this.id,
    required this.transactionId,
    this.userId,
    required this.userName,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.type,
    this.description,
    required this.biometricVerified,
    required this.createdAt,
    this.completedAt,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      id: json['id'] is int ? json['id'] : (json['id'] as num).toInt(),
      transactionId: json['transactionId'] ?? '',
      userId: json['userId'] != null
          ? (json['userId'] is int
                ? json['userId']
                : (json['userId'] as num).toInt())
          : null,
      userName: json['userName'] ?? 'Pending Identification',
      merchantId: json['merchantId'] is int
          ? json['merchantId']
          : (json['merchantId'] as num).toInt(),
      merchantName: json['merchantName'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'LKR',
      status: json['status'] ?? 'PENDING',
      type: json['type'] ?? 'PAYMENT',
      description: json['description'],
      biometricVerified: json['biometricVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  // Helper to get formatted amount with currency
  String get formattedAmount {
    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  // Helper to get status color
  String get statusColor {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return '4CAF50'; // Green
      case 'PENDING':
        return 'FFA726'; // Orange
      case 'FAILED':
        return 'EF5350'; // Red
      case 'REFUNDED':
        return '42A5F5'; // Blue
      default:
        return '9E9E9E'; // Grey
    }
  }
}
