import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // <-- make sure this path is correct

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _remember = false;
  bool _loading = false;
  bool _fade = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _fade = true);
    });
  }

  /// 🔹 LOGIN FUNCTION (calls Laravel API)
  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final api = ApiService();
      final res = await api.login(
        context,
        _email.text.trim(),
        _password.text.trim(),
      );

      if (res != null && res.statusCode == 200 && res.data['token'] != null) {
        // ✅ Success → go to Home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showToast('Invalid credentials or unexpected response.');
      }
    } catch (e) {
      _showToast('Login failed: $e');
    }

    setState(() => _loading = false);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          // --- Accent glow top-left ---
          Positioned(
            top: -150,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.fromRGBO(60, 130, 246, 0.18),
                    Colors.transparent,
                  ],
                  radius: 1.0,
                ),
              ),
            ),
          ),

          // --- Accent glow bottom-right ---
          Positioned(
            bottom: -180,
            right: -100,
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.fromRGBO(90, 80, 240, 0.20),
                    Colors.transparent,
                  ],
                  radius: 1.0,
                ),
              ),
            ),
          ),

          // --- LOGIN CARD ---
          Center(
            child: AnimatedOpacity(
              opacity: _fade ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: Transform.translate(
                offset: Offset(0, _fade ? 0 : 18),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/SIO Logo/3.png",
                            height: 70,
                            opacity: const AlwaysStoppedAnimation(0.95),
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            "Medical Supply System",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Sign in to continue",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // --- EMAIL ---
                          _inputLabel("Email Address"),
                          _inputGlassField(
                            controller: _email,
                            hint: "you@example.com",
                          ),
                          const SizedBox(height: 18),

                          // --- PASSWORD ---
                          _inputLabel("Password"),
                          _inputGlassPass(),
                          const SizedBox(height: 10),

                          // --- REMEMBER CHECKBOX ---
                          Row(
                            children: [
                              Checkbox(
                                value: _remember,
                                onChanged: (v) =>
                                    setState(() => _remember = v!),
                                activeColor: Colors.blueAccent,
                              ),
                              const Text(
                                "Remember me",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // --- LOGIN BUTTON ---
                          GestureDetector(
                            onTap: _loading ? null : _onLogin,
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF4F46E5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Sign In",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          Text(
                            "© 2026 SIO - Stock Invetory Operation System",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: TextStyle(
        color: Colors.grey[300],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _inputGlassField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: _glassDecoration(hint),
    );
  }

  Widget _inputGlassPass() {
    return TextField(
      controller: _password,
      obscureText: !_showPassword,
      style: const TextStyle(color: Colors.white),
      decoration: _glassDecoration("••••••••").copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  InputDecoration _glassDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.4),
      ),
    );
  }
}
