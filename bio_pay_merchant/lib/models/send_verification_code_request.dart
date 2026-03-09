class SendVerificationCodeRequest {
  final String email;

  SendVerificationCodeRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
