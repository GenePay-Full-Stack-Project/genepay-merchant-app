import 'package:flutter/material.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/merchant_api_service.dart';

class CleanSplashScreen extends StatefulWidget {
  const CleanSplashScreen({super.key});

  @override
  State<CleanSplashScreen> createState() => _CleanSplashScreenState();
}

class _CleanSplashScreenState extends State<CleanSplashScreen> {
  final MerchantApiService _apiService = MerchantApiService();

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Initialize API service
      await _apiService.initialize();

      // Wait for splash screen display (2 seconds)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        return;
      }

      // Check if this is the first run
      final isFirstRun = await IsFirstRun.isFirstRun();

      if (isFirstRun) {
        // First time app launch - show onboarding
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }

      // Not first run - check if user is authenticated
      final token = _apiService.getAuthToken();

      if (token == null || token.isEmpty) {
        // No token - navigate to auth screen
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }

      // Token exists - verify it
      final verifyResponse = await _apiService.verifyToken(token);

      if (verifyResponse.success && verifyResponse.data?.valid == true) {
        // Token is valid - save merchant ID and navigate to dashboard
        if (verifyResponse.data?.userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('merchant_id', verifyResponse.data!.userId!);
          // Ensure the write is flushed to disk
          await prefs.reload();
        }

        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, '/merchant_dashboard');
      } else {
        // Token is invalid - try to refresh
        final refreshToken = _apiService.getRefreshToken();

        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshResponse = await _apiService.refreshToken(refreshToken);

          if (refreshResponse.success && refreshResponse.data != null) {
            // Successfully refreshed - verify new token to get merchant ID
            final newToken = _apiService.getAuthToken();
            if (newToken != null) {
              final newVerifyResponse = await _apiService.verifyToken(newToken);

              if (newVerifyResponse.success &&
                  newVerifyResponse.data?.userId != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(
                  'merchant_id',
                  newVerifyResponse.data!.userId!,
                );
                // Ensure the write is flushed to disk
                await prefs.reload();
              }
            }

            if (!mounted) {
              return;
            }
            Navigator.pushReplacementNamed(context, '/merchant_dashboard');
            return;
          }
        }

        // Unable to refresh or no refresh token - navigate to auth screen
        await _apiService.logout();
        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      // Navigate to auth screen on error
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 260,
                child: Image.asset(
                  'assets/images/image 2.png',
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 96,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'GenePay',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E8B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your face is your wallet',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C2C2C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
