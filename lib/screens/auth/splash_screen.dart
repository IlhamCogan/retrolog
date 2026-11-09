import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.two_wheeler, size: 90, color: Color(0xFFD97706)),
            SizedBox(height: 16),
            Text(
              'RETROLOG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your Classic Garage',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Color(0xFFD97706),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}