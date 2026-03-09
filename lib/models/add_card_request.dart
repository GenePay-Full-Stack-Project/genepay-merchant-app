class AddCardRequest {
  final String cardNumber;
  final String cvv;
  final String expiry;
  final String? nickname;

  AddCardRequest({
    required this.cardNumber,
    required this.cvv,
    required this.expiry,
    this.nickname,
  });

  Map<String, dynamic> toJson() {
    return {
      'cardNumber': cardNumber,
      'cvv': cvv,
      'expiry': expiry,
      if (nickname != null) 'nickname': nickname,
    };
  }
}
