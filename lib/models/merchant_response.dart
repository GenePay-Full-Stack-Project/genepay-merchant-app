class MerchantResponse {
  final int id;
  final String email;
  final String businessName;
  final String? ownerName;
  final String? phoneNumber;
  final String? businessAddress;
  final String? businessType;
  final String status;
  final String? onboardingStatus;
  final bool? cardLinked;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? cardLinkedAt;

  MerchantResponse({
    required this.id,
    required this.email,
    required this.businessName,
    this.ownerName,
    this.phoneNumber,
    this.businessAddress,
    this.businessType,
    required this.status,
    this.onboardingStatus,
    this.cardLinked,
    this.createdAt,
    this.lastLoginAt,
    this.cardLinkedAt,
  });

  factory MerchantResponse.fromJson(Map<String, dynamic> json) {
    return MerchantResponse(
      id: json['id'] is int ? json['id'] : (json['id'] as num).toInt(),
      email: json['email'] ?? '',
      businessName: json['businessName'] ?? '',
      ownerName: json['ownerName'],
      phoneNumber: json['phoneNumber'],
      businessAddress: json['businessAddress'],
      businessType: json['businessType'],
      status: json['status'] ?? '',
      onboardingStatus: json['onboardingStatus'],
      cardLinked: json['cardLinked'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      cardLinkedAt: json['cardLinkedAt'] != null
          ? DateTime.parse(json['cardLinkedAt'])
          : null,
    );
  }
}
