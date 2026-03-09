class MerchantRegistrationRequest {
  final String email;
  final String password;
  final String businessName;
  final String? ownerName;
  final String? phoneNumber;
  final String? businessAddress;
  final String? businessType;

  MerchantRegistrationRequest({
    required this.email,
    required this.password,
    required this.businessName,
    this.ownerName,
    this.phoneNumber,
    this.businessAddress,
    this.businessType,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'businessName': businessName,
      if (ownerName != null) 'ownerName': ownerName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (businessAddress != null) 'businessAddress': businessAddress,
      if (businessType != null) 'businessType': businessType,
    };
  }
}
