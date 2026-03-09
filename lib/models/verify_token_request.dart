class VerifyTokenRequest {
  final String token;

  VerifyTokenRequest({required this.token});

  Map<String, dynamic> toJson() {
    return {'token': token};
  }
}
