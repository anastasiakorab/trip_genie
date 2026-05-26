import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
            Colors.white.withValues(alpha: 0.08),

        borderRadius:
            BorderRadius.circular(
          24,
        ),

        border: Border.all(
          color:
              Colors.white.withValues(alpha: 0.12),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
          ),
        ],
      ),

      child: child,
    );
  }
}