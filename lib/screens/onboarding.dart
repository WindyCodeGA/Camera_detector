import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Onboard())),
    );
  }
}

class Onboard extends StatelessWidget {
  const Onboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/image01.png', width: 200, height: 200),
        Spacer(),
        SizedBox(height: 18),
        Text(
          "HELLO WELCOME TO CAMERA DETECTOR",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 18),
        Text(
          "This is a camera detector app",
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }
}
