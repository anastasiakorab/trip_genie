import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

    Provider.of<ProfileProvider>(context, listen: false).setSaving(true);

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
        Provider.of<ProfileProvider>(context, listen: false).setSaving(false);
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
    final profileProvider = Provider.of<ProfileProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  28,
                ),
                child: Column(
                  children: [
                    _headerCard(isMobile: isMobile),
                    SizedBox(height: isMobile ? 18 : 24),
                    _formCard(
                      isDark: isDark,
                      isMobile: isMobile,
                      profileProvider: profileProvider,
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

  Widget _headerCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D5DFF).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 42 : 48,
            height: isMobile ? 42 : 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 26 : 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update your account information',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({
    required bool isDark,
    required bool isMobile,
    required ProfileProvider profileProvider,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isMobile ? 26 : 30),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _inputCard(
            controller: nameController,
            label: 'Name',
            icon: Icons.person_outline,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _inputCard(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _inputCard(
            controller: passwordController,
            label: 'New Password',
            icon: Icons.lock_outline,
            isDark: isDark,
            obscureText: profileProvider.hidePassword,
            suffixIcon: IconButton(
              icon: Icon(
                profileProvider.hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: profileProvider.togglePasswordVisibility,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: isMobile ? 54 : 56,
            child: ElevatedButton.icon(
              onPressed: profileProvider.isSaving ? null : _saveChanges,
              icon: profileProvider.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                profileProvider.isSaving ? 'Saving...' : 'Save Changes',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D5DFF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF6D5DFF).withValues(alpha: 0.55),
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
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
        fillColor: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.55)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF6D5DFF),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
