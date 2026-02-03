import 'package:flutter/material.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  void _next() {
    if (_page < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  OnboardingPage(
                    title: 'Welcome to FaceWallet',
                    subtitle: 'Pay with just your face\nfast, simple, secure.',
                    buttonText: 'Continue',
                    onButtonPressed: _next,
                    imageAsset: 'assets/images/onboarding_welcome.png',
                  ),
                  OnboardingPage(
                    title: 'Safe and Secure',
                    subtitle: 'Your face data is encrypted\nand never shared.',
                    buttonText: 'Continue',
                    onButtonPressed: _next,
                    imageAsset: 'assets/images/onboarding_secure.png',
                    coloredWords: ['encrypted'],
                  ),
                  OnboardingPage(
                    title: 'Ready to Pay?',
                    subtitle: 'Set up your face now and\nstart making payments.',
                    buttonText: 'Ready!',
                    onButtonPressed: _next,
                    imageAsset: 'assets/images/onboarding_ready.png',
                    coloredWords: ['Set up'],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _page == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == index ? Colors.deepOrange : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
