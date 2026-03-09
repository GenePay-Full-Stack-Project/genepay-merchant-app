class CardResponse {
  final int id;
  final String cardLast4;
  final String? cardBrand;
  final String expiryMonth;
  final String expiryYear;
  final bool isDefault;
  final bool isActive;
  final String? nickname;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  CardResponse({
    required this.id,
    required this.cardLast4,
    this.cardBrand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
    required this.isActive,
    this.nickname,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory CardResponse.fromJson(Map<String, dynamic> json) {
    return CardResponse(
      id: json['id'] as int,
      cardLast4: json['cardLast4'] as String,
      cardBrand: json['cardBrand'] as String?,
      expiryMonth: json['expiryMonth'] as String,
      expiryYear: json['expiryYear'] as String,
      isDefault: json['isDefault'] as bool,
      isActive: json['isActive'] as bool,
      nickname: json['nickname'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'isActive': isActive,
      'nickname': nickname,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  String get maskedCardNumber => '**** **** **** $cardLast4';

  String get expiryDate => '$expiryMonth/$expiryYear';
}
