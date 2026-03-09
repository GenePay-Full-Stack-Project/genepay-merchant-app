import 'package:flutter/material.dart';
import 'screens/splash_screen_clean.dart';
import 'screens/onbording/onboarding_screen.dart';
import 'screens/login/auth_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/registration_step1_screen.dart';
import 'screens/register/registration_step2_screen.dart';
import 'screens/register/registration_step3_screen.dart';
import 'screens/register/registration_success_screen.dart';
import 'screens/merchant_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bio Pay Merchant',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) {
          return const CleanSplashScreen();
        },
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/registration_step1': (context) => const RegistrationStep1Screen(),
        '/registration_step2': (context) => const RegistrationStep2Screen(),
        '/registration_step3': (context) => const RegistrationStep3Screen(),
        '/registration_success': (context) => const RegistrationSuccessScreen(),
        '/merchant_dashboard': (context) {
          return const MerchantHomeScreen();
        },
      },
    );
  }
}
