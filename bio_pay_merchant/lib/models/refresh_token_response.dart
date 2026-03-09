class RefreshTokenResponse {
  final String token;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  RefreshTokenResponse({
    required this.token,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'],
    );
  }
}
