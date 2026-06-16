import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';

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
      if (mounted) setState(() => _fade = true);
    });
  }

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
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showToast('Invalid credentials or unexpected response.');
      }
    } catch (e) {
      _showToast('Login failed: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.red500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.72, -0.88), // ~14% 6%
            radius: 1.5,
            colors: [
              isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
              colors.bg,
            ],
            stops: const [0.0, 0.56],
          ),
        ),
        child: Stack(
          children: [
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
                      borderRadius: BorderRadius.circular(12),
                      color: colors.panel,
                      border: Border.all(
                        color: colors.line,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/SIO Logo/3.png",
                          height: 70,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          "Stock Inventory Operation",
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Sign in to continue",
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // --- EMAIL ---
                        _inputLabel("Email Address", colors),
                        _inputField(
                          controller: _email,
                          hint: "you@example.com",
                          colors: colors,
                        ),
                        const SizedBox(height: 18),

                        // --- PASSWORD ---
                        _inputLabel("Password", colors),
                        _inputPass(colors),
                        const SizedBox(height: 10),

                        // --- REMEMBER CHECKBOX ---
                        Row(
                          children: [
                            Checkbox(
                              value: _remember,
                              onChanged: (v) =>
                                  setState(() => _remember = v!),
                              activeColor: colors.accent,
                              checkColor: colors.accentForeground,
                              side: BorderSide(color: colors.line),
                            ),
                            Text(
                              "Remember me",
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // --- LOGIN BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _onLogin,
                            child: _loading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: colors.accentForeground,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Sign In"),
                          ),
                        ),
                        const SizedBox(height: 22),

                        Text(
                          "© 2026 SIO - Stock Invetory Operation System",
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 12.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: colors.text,
                ),
                onPressed: () {
                  MyApp.of(context).toggleTheme();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String text, AppColors colors) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          color: colors.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required AppColors colors,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: colors.text),
      decoration: _inputDecoration(hint, colors),
    );
  }

  Widget _inputPass(AppColors colors) {
    return TextField(
      controller: _password,
      obscureText: !_showPassword,
      style: TextStyle(color: colors.text),
      decoration: _inputDecoration("••••••••", colors).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            color: colors.muted,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, AppColors colors) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.muted),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.line, width: 1.5),
      ),
    );
  }
}
