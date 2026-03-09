class ApiConfig {
  // Payment Service
  static const String paymentServiceBaseUrl = 'https://api.facewallet-payment.corszero.com';
  static const String paymentApiPrefix = '/api/v1';

  // Biometric Service
  static const String biometricServiceBaseUrl = 'https://api.facewallet-biometric.corszero.com';
  static const String biometricApiPrefix = '';

  // Full endpoints
  static String get paymentServiceUrl =>
      '$paymentServiceBaseUrl$paymentApiPrefix';
  static String get biometricServiceUrl => biometricServiceBaseUrl;
}
