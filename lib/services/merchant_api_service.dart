import '../models/merchant_registration_request.dart';
import '../models/login_request.dart';
import '../models/send_verification_code_request.dart';
import '../models/verify_email_request.dart';
import '../models/update_merchant_request.dart';
import '../models/merchant_response.dart';
import '../models/login_response.dart';
import '../models/api_response.dart';
import '../models/verify_token_request.dart';
import '../models/token_verify_response.dart';
import '../models/refresh_token_request.dart';
import '../models/refresh_token_response.dart';
import 'api_service.dart';

class MerchantApiService {
  final ApiService _apiService;

  MerchantApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Initialize the service
  Future<void> initialize() async {
    await _apiService.initialize();
  }

  /// Send verification code to email before registration
  Future<ApiResponse<void>> sendVerificationCode(String email) async {
    try {
      final request = SendVerificationCodeRequest(email: email);
      return await _apiService.post<void>(
        '/merchants/send-verification-code',
        request.toJson(),
        (_) {},
      );
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }

  /// Verify email using verification code
  Future<ApiResponse<void>> verifyEmail(
    String email,
    String verificationCode,
  ) async {
    try {
      final request = VerifyEmailRequest(
        email: email,
        verificationCode: verificationCode,
      );
      return await _apiService.post<void>(
        '/merchants/verify-email',
        request.toJson(),
        (_) {},
      );
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }

  /// Register a new merchant (requires email to be verified first)
  Future<ApiResponse<MerchantResponse>> registerMerchant(
    MerchantRegistrationRequest request,
  ) async {
    try {
      return await _apiService.post<MerchantResponse>(
        '/merchants/register',
        request.toJson(),
        (json) => MerchantResponse.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }

  /// Login merchant
  Future<ApiResponse<LoginResponse>> loginMerchant(LoginRequest request) async {
    try {
      final response = await _apiService.post<LoginResponse>(
        '/merchants/login',
        request.toJson(),
        (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
      );

      // Store auth token and refresh token after successful login
      if (response.success && response.data != null) {
        await _apiService.setAuthToken(response.data!.token);
        await _apiService.setRefreshToken(response.data!.refreshToken);
      }

      return response;
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }

  /// Logout merchant (clear token)
  Future<void> logout() async {
    await _apiService.clearAuthToken();
  }

  /// Get merchant by ID
  Future<ApiResponse<MerchantResponse>> getMerchant(int merchantId) async {
    try {
      return await _apiService.get<MerchantResponse>(
        '/merchants/$merchantId',
        (json) => MerchantResponse.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _apiService.getToken() != null;
  }

  /// Get current auth token
  String? getAuthToken() {
    return _apiService.getToken();
  }

  /// Get current refresh token
  String? getRefreshToken() {
    return _apiService.getRefreshToken();
  }

  /// Update merchant profile
  Future<ApiResponse<MerchantResponse>> updateMerchant(
    int merchantId,
    UpdateMerchantRequest request,
  ) async {
    try {
      return await _apiService.put<MerchantResponse>(
        '/merchants/$merchantId',
        request.toJson(),
        (json) => MerchantResponse.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }

  /// Verify JWT token
  Future<ApiResponse<TokenVerifyResponse>> verifyToken(String token) async {
    try {
      final request = VerifyTokenRequest(token: token);
      final response = await _apiService.post<TokenVerifyResponse>(
        '/merchants/verify-token',
        request.toJson(),
        (json) {
          try {
            final result = TokenVerifyResponse.fromJson(
              json as Map<String, dynamic>,
            );
            return result;
          } catch (e) {
            rethrow;
          }
        },
      );
      return response;
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Refresh JWT token using refresh token
  Future<ApiResponse<RefreshTokenResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _apiService.post<RefreshTokenResponse>(
        '/merchants/refresh-token',
        request.toJson(),
        (json) => RefreshTokenResponse.fromJson(json as Map<String, dynamic>),
      );

      // Store new tokens after successful refresh
      if (response.success && response.data != null) {
        await _apiService.setAuthToken(response.data!.token);
        await _apiService.setRefreshToken(response.data!.refreshToken);
      }

      return response;
    } on ApiException catch (e) {
      return ApiResponse(success: false, error: e.message);
    }
  }
}
