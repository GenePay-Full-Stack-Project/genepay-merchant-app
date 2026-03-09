# Integration Guide: Connect UI Screens to Merchant API

This guide shows how to integrate the `MerchantApiService` with your existing registration screens.

## Overview

You have 4 registration screens that need to be connected:
1. `registration_step1_screen.dart` - Collect merchant info & send verification code
2. `registration_step2_screen.dart` - Verify email with code
3. `registration_step3_screen.dart` - Set password & complete registration
4. `registration_success_screen.dart` - Show success message

## Step-by-Step Integration

### 1. Add State Management

First, install a state management package (optional but recommended):

```yaml
# pubspec.yaml
dependencies:
  provider: ^6.1.0  # or use riverpod, bloc, etc.
```

### 2. Create Registration State Controller

Create `lib/controllers/merchant_registration_controller.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/merchant_api_service.dart';
import '../models/merchant_registration_request.dart';

class MerchantRegistrationController extends ChangeNotifier {
  final MerchantApiService _apiService = MerchantApiService();
  
  // Form data
  String? email;
  String? fullName;
  String? nic;
  String? phoneNumber;
  String? businessName;
  String? businessType;
  String? businessAddress;
  String? password;
  
  bool isLoading = false;
  String? errorMessage;
  
  Future<bool> sendVerificationCode(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final result = await _apiService.sendVerificationCode(email);
    
    isLoading = false;
    if (result.success) {
      this.email = email;
      notifyListeners();
      return true;
    } else {
      errorMessage = result.error;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> verifyEmail(String code) async {
    if (email == null) return false;
    
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final result = await _apiService.verifyEmail(email!, code);
    
    isLoading = false;
    if (result.success) {
      notifyListeners();
      return true;
    } else {
      errorMessage = result.error;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> registerMerchant() async {
    if (email == null || password == null || businessName == null) {
      errorMessage = "Missing required fields";
      notifyListeners();
      return false;
    }
    
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final request = MerchantRegistrationRequest(
      email: email!,
      password: password!,
      businessName: businessName!,
      ownerName: fullName,
      phoneNumber: phoneNumber,
      businessAddress: businessAddress,
      businessType: businessType,
    );
    
    final result = await _apiService.registerMerchant(request);
    
    isLoading = false;
    if (result.success && result.data != null) {
      notifyListeners();
      return true;
    } else {
      errorMessage = result.error;
      notifyListeners();
      return false;
    }
  }
}
```

### 3. Update Registration Step 1 Screen

Modify `registration_step1_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/merchant_registration_controller.dart';

class RegistrationStep1Screen extends StatefulWidget {
  const RegistrationStep1Screen({super.key});

  @override
  State<RegistrationStep1Screen> createState() => _RegistrationStep1ScreenState();
}

class _RegistrationStep1ScreenState extends State<RegistrationStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleNext() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<MerchantRegistrationController>();
      
      // Save form data
      controller.fullName = _nameController.text;
      controller.email = _emailController.text;
      controller.nic = _nicController.text;
      controller.phoneNumber = _phoneController.text;
      controller.businessName = _nameController.text; // or use a separate field
      
      // Send verification code
      final success = await controller.sendVerificationCode(_emailController.text);
      
      if (success && mounted) {
        Navigator.pushNamed(context, '/registration-step2');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Failed to send verification code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantRegistrationController>(
      builder: (context, controller, child) {
        return Scaffold(
          // ... your existing UI code ...
          body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: /* your form widgets */,
              ),
        );
      },
    );
  }
}
```

### 4. Update Registration Step 2 Screen (Email Verification)

Modify `registration_step2_screen.dart`:

```dart
class RegistrationStep2Screen extends StatefulWidget {
  const RegistrationStep2Screen({super.key});

  @override
  State<RegistrationStep2Screen> createState() => _RegistrationStep2ScreenState();
}

class _RegistrationStep2ScreenState extends State<RegistrationStep2Screen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6, 
    (_) => TextEditingController(),
  );

  void _handleVerify() async {
    final code = _codeControllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits')),
      );
      return;
    }

    final controller = context.read<MerchantRegistrationController>();
    final success = await controller.verifyEmail(code);

    if (success && mounted) {
      Navigator.pushNamed(context, '/registration-step3');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Invalid verification code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleResend() async {
    final controller = context.read<MerchantRegistrationController>();
    if (controller.email != null) {
      final success = await controller.sendVerificationCode(controller.email!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantRegistrationController>(
      builder: (context, controller, child) {
        return Scaffold(
          // ... your UI with verification code input ...
          // Add onPressed: _handleVerify to your verify button
          // Add onPressed: _handleResend to your resend button
        );
      },
    );
  }
}
```

### 5. Update Registration Step 3 Screen (Password)

Modify `registration_step3_screen.dart`:

```dart
class _RegistrationStep3ScreenState extends State<RegistrationStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<MerchantRegistrationController>();
      controller.password = _passwordController.text;

      final success = await controller.registerMerchant();

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/registration-success');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantRegistrationController>(
      builder: (context, controller, child) {
        return Scaffold(
          // ... your password form UI ...
          // Add onPressed: _handleSubmit to your submit button
        );
      },
    );
  }
}
```

### 6. Setup Provider in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/merchant_registration_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MerchantRegistrationController()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 7. Configure API Base URL

Update the base URL in `merchant_api_service.dart` based on your environment:

```dart
// For local development
static const String baseUrl = 'http://10.0.2.2:8080/api/merchants'; // Android emulator
// static const String baseUrl = 'http://localhost:8080/api/merchants'; // iOS simulator
// static const String baseUrl = 'http://192.168.1.100:8080/api/merchants'; // Physical device
```

## Testing the Flow

1. Start your backend server
2. Run the Flutter app: `flutter run`
3. Navigate to registration
4. Fill in the form and submit
5. Check your email for verification code
6. Enter the code
7. Set password and complete registration

## Error Handling

The controller handles common errors:
- Network errors
- Email already registered
- Invalid verification code
- Missing required fields

Display these errors in your UI using the `errorMessage` property.

## Next Steps

1. Add proper form validation
2. Add loading indicators
3. Implement token storage for login
4. Add biometric enrollment after registration
5. Implement auto-navigation after successful registration
