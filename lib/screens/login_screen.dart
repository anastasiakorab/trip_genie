import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_genie/providers/auth_form_provider.dart';

import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _login() async {
    final authProvider = Provider.of<AuthFormProvider>(context, listen: false);

    authProvider.startLoading();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      authProvider.stopLoading('Please fill all fields.');
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!emailRegex.hasMatch(email)) {
      authProvider.stopLoading('Please enter valid email.');
      return;
    }

    if (password.length < 6) {
      authProvider.stopLoading('Password must be at least 6 characters.');
      return;
    }

    final error = await AuthService.login(email: email, password: password);

    if (!mounted) return;

    authProvider.stopLoading(error);
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email first.')),
      );
      return;
    }

    final error = await AuthService.resetPassword(email: email);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Password reset email sent.')),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthFormProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    const Color(0xFF312E81),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEDE9FE),
                    const Color(0xFFFDF2F8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 18 : 24,
                  isMobile ? 18 : 24,
                  isMobile ? 18 : 24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        (isMobile ? 36 : 48),
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 460),
                      padding: EdgeInsets.all(isMobile ? 22 : 30),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(isMobile ? 28 : 34),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _logo(isMobile),
                          SizedBox(height: isMobile ? 18 : 24),
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: isMobile ? 30 : 34,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Log in to continue planning your trips.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 14 : 15,
                            ),
                          ),
                          SizedBox(height: isMobile ? 24 : 30),
                          _input(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            action: TextInputAction.next,
                            isMobile: isMobile,
                          ),
                          SizedBox(height: isMobile ? 14 : 18),
                          _input(
                            controller: passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscure: authProvider.hidePassword,
                            action: TextInputAction.done,
                            isMobile: isMobile,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _forgotPassword,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Color(0xFF6D5DFF),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (authProvider.errorText != null) ...[
                            Text(
                              authProvider.errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          SizedBox(height: isMobile ? 20 : 25),
                          SizedBox(
                            width: double.infinity,
                            height: isMobile ? 54 : 58,
                            child: ElevatedButton(
                              onPressed:
                                  authProvider.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D5DFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                authProvider.isLoading
                                    ? 'Logging in...'
                                    : 'Log In',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Center(
                            child: TextButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SignupScreen(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                "Don't have an account? Sign up",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF6D5DFF),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _logo(bool isMobile) {
    return Container(
      width: isMobile ? 56 : 62,
      height: isMobile ? 56 : 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(
        Icons.flight_takeoff_rounded,
        color: Colors.white,
        size: isMobile ? 29 : 32,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? action,
    required bool isMobile,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthFormProvider>(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: action,
      cursorColor: const Color(0xFF6D5DFF),
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF6D5DFF)),
        suffixIcon: label == 'Password'
            ? IconButton(
                onPressed: authProvider.togglePasswordVisibility,
                icon: Icon(
                  authProvider.hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6D5DFF),
                ),
              )
            : null,
        hintText: label,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: isMobile ? 18 : 22,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: .08)
                : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF6D5DFF),
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
