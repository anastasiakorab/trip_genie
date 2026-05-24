import 'package:flutter/material.dart';

class GradientActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const GradientActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}