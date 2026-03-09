# Merchant API Service

This folder contains API service classes for communicating with the backend payment service.

## Architecture

The service layer uses a clean architecture pattern:
- **`ApiService`** - Generic HTTP client with authentication, error handling, and token management
- **`MerchantApiService`** - Business logic layer for merchant-specific operations

## Usage Example

### Initialize the service

```dart
import 'package:bio_pay_merchant/services/merchant_api_service.dart';

final merchantService = MerchantApiService();

// Initialize (loads stored auth token)
await merchantService.initialize();
```

### 1. Send Verification Code

Before registering, merchants must verify their email:

```dart
// Send verification code
final result = await merchantService.sendVerificationCode('merchant@example.com');
if (result.success) {
  print('Verification code sent!');
} else {
  print('Error: ${result.error}');
}
```

### 2. Verify Email

After receiving the code via email:

```dart
final verifyResult = await merchantService.verifyEmail(
  'merchant@example.com',
  '123456', // The code received via email
);
if (verifyResult.success) {
  print('Email verified! Can now proceed to registration.');
} else {
  print('Error: ${verifyResult.error}');
}
```

### 3. Register Merchant

After email is verified:

```dart
import 'package:bio_pay_merchant/models/merchant_registration_request.dart';

final request = MerchantRegistrationRequest(
  email: 'merchant@example.com',
  password: 'SecurePassword123!',
  businessName: 'My Coffee Shop',
  ownerName: 'John Doe',
  phoneNumber: '+94771234567',
  businessAddress: '123 Main St, Colombo',
  businessType: 'Retail',
);

final registerResult = await merchantService.registerMerchant(request);
if (registerResult.success && registerResult.data != null) {
  final merchant = registerResult.data!;
  print('Registered successfully! Merchant ID: ${merchant.id}');
} else {
  print('Error: ${registerResult.error}');
}
```

### 4. Login Merchant

```dart
import 'package:bio_pay_merchant/models/login_request.dart';

final loginRequest = LoginRequest(
  email: 'merchant@example.com',
  password: 'SecurePassword123!',
);

final loginResult = await merchantService.loginMerchant(loginRequest);
if (loginResult.success && loginResult.data != null) {
  final loginData = loginResult.data!;
  print('Login successful!');
  print('Token: ${loginData.token}');
  print('User: ${loginData.user.fullName}');
  
  // Token is automatically stored by the service
} else {
  print('Error: ${loginResult.error}');
}
```

### 5. Get Merchant Profile

```dart
// Auth token is automatically included from stored session
final merchantId = 1; // Your merchant ID
final profileResult = await merchantService.getMerchant(merchantId);

if (profileResult.success && profileResult.data != null) {
  final merchant = profileResult.data!;
  print('Business: ${merchant.businessName}');
  print('Status: ${merchant.status}');
} else {
  print('Error: ${profileResult.error}');
}
```

### 6. Check Authentication Status

```dart
if (merchantService.isAuthenticated()) {
  print('User is logged in');
  print('Token: ${merchantService.getAuthToken()}');
} else {
  print('User is not logged in');
}
```

### 7. Logout

```dart
await merchantService.logout();
print('Logged out successfully');
```

## Configuration

Update the `baseUrl` in `api_service.dart` to point to your backend:

```dart
static const String baseUrl = 'http://your-backend-url:8080';
```

For local development, use:
- Android Emulator: `http://10.0.2.2:8080`
- iOS Simulator: `http://localhost:8080`
- Physical Device: `http://YOUR_COMPUTER_IP:8080`

## Complete Registration Flow

```dart
Future<void> registerNewMerchant() async {
  final merchantService = MerchantApiService();
  await merchantService.initialize();
  
  final email = 'merchant@example.com';
  
  try {
    // Step 1: Send verification code
    final sendCodeResult = await merchantService.sendVerificationCode(email);
    if (!sendCodeResult.success) {
      throw Exception(sendCodeResult.error);
    }
    
    // Step 2: Wait for user to enter code from email
    final code = '123456'; // Get from user input
    
    final verifyResult = await merchantService.verifyEmail(email, code);
    if (!verifyResult.success) {
      throw Exception(verifyResult.error);
    }
    
    // Step 3: Register merchant
    final request = MerchantRegistrationRequest(
      email: email,
      password: 'SecurePassword123!',
      businessName: 'My Business',
      ownerName: 'John Doe',
      phoneNumber: '+94771234567',
    );
    
    final registerResult = await merchantService.registerMerchant(request);
    if (!registerResult.success) {
      throw Exception(registerResult.error);
    }
    
    print('Registration completed successfully!');
    
  } catch (e) {
    print('Registration failed: $e');
  }
}
```

## Features

### Automatic Token Management
- Tokens are automatically stored after login
- Tokens are automatically included in authenticated requests
- Tokens persist across app restarts using SharedPreferences

### Error Handling
- All API calls return `ApiResponse<T>` with success/error states
- Network errors are caught and returned as user-friendly messages
- API exceptions include status codes for debugging

### Type Safety
- Generic types ensure compile-time type safety
- All models have proper JSON serialization
- No manual JSON parsing required

## Dependencies

Make sure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

## Service Layer Architecture

```
┌─────────────────────────────┐
│   UI Layer (Screens)        │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  MerchantApiService         │
│  (Business Logic)           │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  ApiService                 │
│  (HTTP Client + Auth)       │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Backend API                │
└─────────────────────────────┘
```
