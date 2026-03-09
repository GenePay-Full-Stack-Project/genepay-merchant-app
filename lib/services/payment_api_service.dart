import '../models/api_response.dart';
import 'api_service.dart';

/// Request model for initiating payment
class PaymentInitiateRequest {
  final int merchantId;
  final double amount;
  final String currency;
  final String? description;

  PaymentInitiateRequest({
    required this.merchantId,
    required this.amount,
    this.currency = 'LKR',
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'merchantId': merchantId,
    'amount': amount,
    'currency': currency,
    if (description != null) 'description': description,
  };
}

/// Response model for payment initiation
class PaymentInitiateResponse {
  final String transactionId;
  final String sessionId;
  final String status;
  final String message;

  PaymentInitiateResponse({
    required this.transactionId,
    required this.sessionId,
    required this.status,
    required this.message,
  });

  factory PaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiateResponse(
      transactionId: json['transactionId'] as String,
      sessionId: json['sessionId'] as String,
      status: json['status'] as String,
      message: json['message'] as String,
    );
  }
}

/// Request model for verifying payment
class PaymentVerifyRequest {
  final String transactionId;
  final String faceData; // Base64 encoded image

  PaymentVerifyRequest({required this.transactionId, required this.faceData});

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'faceData': faceData,
  };
}

/// Response model for payment verification
class PaymentVerifyResponse {
  final String transactionId;
  final String status;
  final bool verified;
  final String message;
  final double amount;
  final String merchantName;

  PaymentVerifyResponse({
    required this.transactionId,
    required this.status,
    required this.verified,
    required this.message,
    required this.amount,
    required this.merchantName,
  });

  factory PaymentVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerifyResponse(
      transactionId: json['transactionId'] as String,
      status: json['status'] as String,
      verified: json['verified'] as bool,
      message: json['message'] as String,
      amount: (json['amount'] as num).toDouble(),
      merchantName: json['merchantName'] as String,
    );
  }
}

/// Service for payment-related API calls
class PaymentApiService {
  final ApiService _apiService;

  PaymentApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Initialize the service
  Future<void> initialize() async {
    await _apiService.initialize();
  }

  /// Initiate a payment transaction
  ///
  /// Creates a pending transaction that requires biometric verification
  Future<ApiResponse<PaymentInitiateResponse>> initiatePayment({
    required int merchantId,
    required double amount,
    String currency = 'LKR',
    String? description,
  }) async {
    try {
      final request = PaymentInitiateRequest(
        merchantId: merchantId,
        amount: amount,
        currency: currency,
        description: description,
      );

      return await _apiService.post<PaymentInitiateResponse>(
        '/payments/initiate',
        request.toJson(),
        (json) =>
            PaymentInitiateResponse.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }

  /// Verify payment with biometric data and complete transaction
  ///
  /// Identifies user by face scan and processes the payment
  Future<ApiResponse<PaymentVerifyResponse>> verifyAndCharge({
    required String transactionId,
    required String faceData, // Base64 encoded image
  }) async {
    try {
      final request = PaymentVerifyRequest(
        transactionId: transactionId,
        faceData: faceData,
      );

      return await _apiService.post<PaymentVerifyResponse>(
        '/payments/verify',
        request.toJson(),
        (json) => PaymentVerifyResponse.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }
}
