import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BiometricService {
  final http.Client _client;

  BiometricService({http.Client? client}) : _client = client ?? http.Client();

  /// Enroll a customer's face
  /// Returns face_id that will be embedded in QR code
  Future<EnrollFaceResponse> enrollFace({
    required String imageBase64,
    required int merchantId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.biometricServiceUrl}/biometric/enroll',
      );

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': imageBase64,
          'merchant_id': merchantId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EnrollFaceResponse.fromJson(data);
      } else {
        // Handle error response
        String errorMessage = 'Face enrollment failed';
        try {
          final error = jsonDecode(response.body);
          if (error is Map<String, dynamic>) {
            // Check for FastAPI validation errors (422)
            if (error['detail'] is List) {
              final details = error['detail'] as List;
              errorMessage = details
                  .map((e) => e['msg'] ?? e.toString())
                  .join(', ');
            } else if (error['detail'] is String) {
              errorMessage = error['detail'];
            } else if (error['message'] is String) {
              errorMessage = error['message'];
            }
          }
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : errorMessage;
        }
        throw BiometricException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is BiometricException) rethrow;
      throw BiometricException('Network error: ${e.toString()}');
    }
  }

  /// Verify a customer's face during payment
  Future<VerifyFaceResponse> verifyFace({
    required String imageBase64,
    required int userId,
    bool requireLiveness = false,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.biometricServiceUrl}/biometric/verify',
      );

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': imageBase64,
          'user_id': userId,
          'require_liveness': requireLiveness,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return VerifyFaceResponse.fromJson(data);
      } else {
        // Handle error response
        String errorMessage = 'Face verification failed';
        try {
          final error = jsonDecode(response.body);
          if (error is Map<String, dynamic>) {
            // Check for FastAPI validation errors (422)
            if (error['detail'] is List) {
              final details = error['detail'] as List;
              errorMessage = details
                  .map((e) => e['msg'] ?? e.toString())
                  .join(', ');
            } else if (error['detail'] is String) {
              errorMessage = error['detail'];
            } else if (error['message'] is String) {
              errorMessage = error['message'];
            }
          }
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : errorMessage;
        }
        throw BiometricException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is BiometricException) rethrow;
      throw BiometricException('Network error: ${e.toString()}');
    }
  }

  /// Health check for biometric service
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('${ApiConfig.biometricServiceUrl}/health');
      final response = await _client.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Response models
class EnrollFaceResponse {
  final bool success;
  final String message;
  final String? faceId;
  final bool livenessPasssed;
  final double? livenessConfidence;
  final double? qualityScore;
  final String? imageUrl;

  EnrollFaceResponse({
    required this.success,
    required this.message,
    this.faceId,
    required this.livenessPasssed,
    this.livenessConfidence,
    this.qualityScore,
    this.imageUrl,
  });

  factory EnrollFaceResponse.fromJson(Map<String, dynamic> json) {
    return EnrollFaceResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Unknown error',
      faceId: json['face_id'] as String?,
      livenessPasssed: json['liveness_passed'] as bool? ?? false,
      livenessConfidence: (json['liveness_confidence'] as num?)?.toDouble(),
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
    );
  }
}

class VerifyFaceResponse {
  final bool success;
  final bool verified;
  final String message;
  final int userId;
  final double confidence;
  final bool livenessPasssed;
  final double? livenessConfidence;
  final double matchDistance;

  VerifyFaceResponse({
    required this.success,
    required this.verified,
    required this.message,
    required this.userId,
    required this.confidence,
    required this.livenessPasssed,
    this.livenessConfidence,
    required this.matchDistance,
  });

  factory VerifyFaceResponse.fromJson(Map<String, dynamic> json) {
    return VerifyFaceResponse(
      success: json['success'] as bool,
      verified: json['verified'] as bool,
      message: json['message'] as String,
      userId: json['user_id'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      livenessPasssed: json['liveness_passed'] as bool? ?? false,
      livenessConfidence: (json['liveness_confidence'] as num?)?.toDouble(),
      matchDistance: (json['match_distance'] as num).toDouble(),
    );
  }
}

class BiometricException implements Exception {
  final String message;
  final int? statusCode;

  BiometricException(this.message, {this.statusCode});

  @override
  String toString() =>
      'BiometricException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
