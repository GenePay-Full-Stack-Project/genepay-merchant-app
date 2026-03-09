import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/merchant_response.dart';
import '../models/transaction_response.dart';
import '../models/card_response.dart';
import '../models/add_card_request.dart';

class ApiService {
  static String get baseUrl => ApiConfig.paymentServiceBaseUrl;
  static String get apiPrefix => ApiConfig.paymentApiPrefix;

  final http.Client _client;
  String? _authToken;
  String? _refreshToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Initialize service and load stored token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  // Set authentication token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Set refresh token
  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  // Get refresh token
  String? getRefreshToken() {
    return _refreshToken;
  }

  // Clear authentication token
  Future<void> clearAuthToken() async {
    _authToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  // Get authentication headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Object? json) fromJson,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _headers,
      );

      return _handleResponse<T>(response, fromJson);
    } on ApiException {
      // If we already created a meaningful ApiException, rethrow it unchanged
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Object? json) fromJson,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );

      return _handleResponse<T>(response, fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Object? json) fromJson,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );

      return _handleResponse<T>(response, fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(Object? json) fromJson,
  ) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _headers,
      );

      return _handleResponse<T>(response, fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Object? json) fromJson,
  ) {
    try {
      // Try to decode JSON. If the body isn't JSON, fall back to using the
      // raw body as the message so server error details aren't lost.
      Map<String, dynamic> responseBody = {};
      try {
        if (response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            responseBody = decoded;
          } else {
            // If the decoded JSON isn't a map, keep the raw body under "data"
            responseBody = {'data': decoded};
          }
        }
      } catch (e) {
        // Non-JSON response body; include it as the message for easier debugging
        responseBody = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>.fromJson(responseBody, fromJson);
      } else {
        // Log details for easier debugging in development
        // ignore: avoid_print
        print(
          'API ERROR ${response.statusCode} ${response.request?.url} - body: ${response.body}',
        );

        final errorMessage =
            responseBody['message'] ?? 'Unknown error occurred';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse response: ${e.toString()}');
    }
  }

  // Get stored token
  String? getToken() {
    return _authToken;
  }

  // Get merchant details by ID
  Future<MerchantResponse> getMerchantById(int merchantId) async {
    try {
      final response = await get<MerchantResponse>('/merchants/$merchantId', (
        json,
      ) {
        try {
          final merchant = MerchantResponse.fromJson(
            json as Map<String, dynamic>,
          );
          return merchant;
        } catch (e) {
          rethrow;
        }
      });

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw ApiException(
          response.message ?? 'Failed to fetch merchant details',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get merchant transactions with pagination
  Future<List<TransactionResponse>> getMerchantTransactions(
    int merchantId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/payments/merchant/$merchantId?page=$page&size=$size',
        (json) {
          return json as Map<String, dynamic>;
        },
      );

      if (response.success && response.data != null) {
        final content = response.data!['content'] as List<dynamic>?;

        if (content != null) {
          try {
            final transactions = content.map((json) {
              try {
                return TransactionResponse.fromJson(
                  json as Map<String, dynamic>,
                );
              } catch (e) {
                rethrow;
              }
            }).toList();
            return transactions;
          } catch (e) {
            rethrow;
          }
        }
        return [];
      } else {
        throw ApiException(response.message ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get today's sales for merchant
  Future<double> getTodaySales(int merchantId) async {
    try {
      final transactions = await getMerchantTransactions(merchantId, size: 100);
      final today = DateTime.now();

      double total = 0.0;
      for (var t in transactions) {
        if (t.status.toUpperCase() == 'COMPLETED' &&
            t.createdAt.year == today.year &&
            t.createdAt.month == today.month &&
            t.createdAt.day == today.day) {
          total += t.amount;
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // ========== MERCHANT CARD MANAGEMENT ==========

  // Add a new card for merchant
  Future<CardResponse> addMerchantCard(
    int merchantId,
    AddCardRequest request,
  ) async {
    final response = await post<CardResponse>(
      '/cards/merchant/$merchantId',
      request.toJson(),
      (json) => CardResponse.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(response.message ?? 'Failed to add card');
    }
  }

  // Get all cards for merchant
  Future<List<CardResponse>> getMerchantCards(int merchantId) async {
    final response = await get<List<dynamic>>(
      '/cards/merchant/$merchantId',
      (json) => json as List<dynamic>,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((json) => CardResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(response.message ?? 'Failed to fetch cards');
    }
  }

  // Get default card for merchant
  Future<CardResponse> getMerchantDefaultCard(int merchantId) async {
    final response = await get<CardResponse>(
      '/cards/merchant/$merchantId/default',
      (json) => CardResponse.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(response.message ?? 'Failed to fetch default card');
    }
  }

  // Set default card for merchant
  Future<CardResponse> setMerchantDefaultCard(
    int merchantId,
    int cardId,
  ) async {
    final response = await put<CardResponse>(
      '/cards/merchant/$merchantId/$cardId/set-default',
      {},
      (json) => CardResponse.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw ApiException(response.message ?? 'Failed to set default card');
    }
  }

  // Remove card from merchant account
  Future<void> removeMerchantCard(int merchantId, int cardId) async {
    final response = await delete<void>(
      '/cards/merchant/$merchantId/$cardId',
      (json) => null,
    );

    if (!response.success) {
      throw ApiException(response.message ?? 'Failed to remove card');
    }
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
