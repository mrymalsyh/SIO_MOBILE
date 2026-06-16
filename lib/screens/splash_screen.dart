import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.bg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/SIO Logo/3.png',
                height: 80,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 32),

              Text(
                'Stock Inventory Operation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 20,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.accent,
              ),

              const SizedBox(height: 12),

              Text(
                'Loading...',
                style: TextStyle(color: colors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
