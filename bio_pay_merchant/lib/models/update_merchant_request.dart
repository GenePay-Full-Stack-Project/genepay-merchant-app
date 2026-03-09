class UpdateMerchantRequest {
  final String? email;
  final String? password;
  final String? businessName;
  final String? ownerName;
  final String? phoneNumber;
  final String? businessAddress;
  final String? businessType;

  UpdateMerchantRequest({
    this.email,
    this.password,
    this.businessName,
    this.ownerName,
    this.phoneNumber,
    this.businessAddress,
    this.businessType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (businessName != null) data['businessName'] = businessName;
    if (ownerName != null) data['ownerName'] = ownerName;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (businessAddress != null) data['businessAddress'] = businessAddress;
    if (businessType != null) data['businessType'] = businessType;

    return data;
  }
}
