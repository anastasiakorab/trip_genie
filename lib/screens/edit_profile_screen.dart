import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isSaving = false;
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    nameController.text = user?.displayName ?? '';
    emailController.text = user?.email ?? '';
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();
    final newPassword = passwordController.text.trim();

    setState(() => isSaving = true);

    try {
      if (newName.isNotEmpty) {
        await user.updateDisplayName(newName);
      }

      if (newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      if (newPassword.isNotEmpty) {
        if (newPassword.length < 6) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'Password must be at least 6 characters.',
          );
        }

        await user.updatePassword(newPassword);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'requires-recent-login'
                ? 'Please log out and log in again before changing email/password.'
                : e.message ?? 'Profile update failed.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
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
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6D5DFF),
                        Color(0xFFEC4899),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _inputCard(
                  controller: nameController,
                  label: 'Name',
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _inputCard(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _inputCard(
                  controller: passwordController,
                  label: 'New Password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  obscureText: hidePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _saveChanges,
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D5DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
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
  }

  Widget _inputCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF111827),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}