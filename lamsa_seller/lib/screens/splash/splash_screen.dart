import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo/logo_transparent_1024.png',
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 16),
              const Text(
                'لمسة للتجار',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2432),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}