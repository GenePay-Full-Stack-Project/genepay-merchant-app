import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? imageAsset;
  final List<String> coloredWords;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onButtonPressed,
    this.imageAsset,
    this.coloredWords = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: _buildTitleSpans(title),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          // Image / illustration
          if (imageAsset != null)
            SizedBox(
              height: 260,
              child: Image.asset(
                imageAsset!,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.wallet_giftcard,
                    size: 96,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.wallet_giftcard,
                    size: 96,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          _buildSubtitleRichText(subtitle, coloredWords),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (buttonText == 'Continue') const SizedBox(width: 8),
                  if (buttonText == 'Continue')
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<TextSpan> _buildTitleSpans(String title) {
    if (title == 'Welcome to GenePay') {
      return [
        const TextSpan(
          text: 'Welcome to ',
          style: TextStyle(
            color: Color(0xFF1E1E8B),
            fontWeight: FontWeight.bold,
          ),
        ),
        const TextSpan(
          text: 'GenePay',
          style: TextStyle(
            color: Color(0xFFFF5722),
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } else if (title == 'Safe and Secure') {
      return [
        const TextSpan(
          text: 'Safe and ',
          style: TextStyle(
            color: Color(0xFF1E1E8B),
            fontWeight: FontWeight.bold,
          ),
        ),
        const TextSpan(
          text: 'Secure',
          style: TextStyle(
            color: Color(0xFFFF5722),
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } else if (title == 'Ready to Pay?') {
      return [
        const TextSpan(
          text: 'Ready to ',
          style: TextStyle(
            color: Color(0xFF1E1E8B),
            fontWeight: FontWeight.bold,
          ),
        ),
        const TextSpan(
          text: 'Pay?',
          style: TextStyle(
            color: Color(0xFFFF5722),
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }
    return [
      TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFF1E1E8B),
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  Widget _buildSubtitleRichText(String subtitle, List<String> coloredWords) {
    List<TextSpan> spans = [];
    String remaining = subtitle;

    for (String word in coloredWords) {
      final parts = remaining.split(word);
      if (parts.length > 1) {
        // Add the text before the colored word
        spans.add(
          TextSpan(
            text: parts[0],
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2C2C2C),

              fontWeight: FontWeight.w500,
            ),
          ),
        );
        // Add the colored word
        spans.add(
          TextSpan(
            text: word,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFF5722),

              fontWeight: FontWeight.w500,
            ),
          ),
        );
        remaining = parts.sublist(1).join(word);
      }
    }

    // Add any remaining text
    if (remaining.isNotEmpty) {
      spans.add(
        TextSpan(
          text: remaining,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // If no colored words were found, just show the subtitle normally
    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans, style: const TextStyle(height: 1.5)),
    );
  }
}
