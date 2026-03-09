class TokenVerifyResponse {
  final bool valid;
  final String? email;
  final int? userId;
  final String? userType;
  final int? expiresAt;

  TokenVerifyResponse({
    required this.valid,
    this.email,
    this.userId,
    this.userType,
    this.expiresAt,
  });

  factory TokenVerifyResponse.fromJson(Map<String, dynamic> json) {
    return TokenVerifyResponse(
      valid: json['valid'] ?? false,
      email: json['email'],
      userId: json['userId'] != null
          ? (json['userId'] is int
                ? json['userId']
                : (json['userId'] as num).toInt())
          : null,
      userType: json['userType'],
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] is int
                ? json['expiresAt']
                : (json['expiresAt'] as num).toInt())
          : null,
    );
  }
}
