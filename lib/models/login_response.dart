class LoginResponse {
  final String token;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserData user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
      user: UserData.fromJson(json['user']),
    );
  }
}

class UserData {
  final int id;
  final String email;
  final String fullName;

  UserData({required this.id, required this.email, required this.fullName});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] is int ? json['id'] : (json['id'] as num).toInt(),
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }
}
