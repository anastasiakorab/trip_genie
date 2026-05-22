import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorText;
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() {
      errorText = null;
      _isLoading = true;
    });

    final error = await AuthService.signUp(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      errorText = error;
    });

    // ако signup е успешен затвори го screen-от
    if (error == null) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Container(
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logo(),

                  const SizedBox(height: 24),

                  Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign up and start building your smart travel plans.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _input(
                    controller: nameController,
                    label: 'Full name',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 18),

                  _input(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 18),

                  _input(
                    controller: passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D5DFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _isLoading
                            ? 'Creating account...'
                            : 'Sign Up',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Already have an account? Log in',
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
      ),
    ),
  );
}

  Widget _logo() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6D5DFF),
            Color(0xFFEC4899),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 32,
      ),
    );
  }

 Widget _input({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscure = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return TextField(
    controller: controller,
    obscureText: obscure,
    cursorColor: const Color(0xFF6D5DFF),

    style: TextStyle(
      color: isDark ? Colors.white : Colors.black,
    ),

    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6D5DFF),
      ),

      hintText: label,

      hintStyle: TextStyle(
        color: isDark
            ? Colors.white54
            : Colors.grey,
      ),

      filled: true,

      fillColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(.08)
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