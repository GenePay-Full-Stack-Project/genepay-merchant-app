class ApiConfig {
  // Payment Service
  static const String paymentServiceBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://54.255.53.212',
  );
  static const String paymentApiPrefix = '/api/v1';

  // Biometric Service
  static const String biometricServiceBaseUrl = String.fromEnvironment(
    'BIOMETRIC_BASE_URL',
    defaultValue: 'http://54.255.53.212',
  );
  static const String biometricApiPrefix = '';

  // Full endpoints
  static String get paymentServiceUrl =>
      '$paymentServiceBaseUrl$paymentApiPrefix';
  static String get biometricServiceUrl => biometricServiceBaseUrl;
}
