class VerifyEmailRequest {
  final String email;
  final String verificationCode;

  VerifyEmailRequest({required this.email, required this.verificationCode});

  Map<String, dynamic> toJson() {
    return {'email': email, 'verificationCode': verificationCode};
  }
}
