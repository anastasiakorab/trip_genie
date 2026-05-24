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
            Colors.white.withOpacity(
          .08,
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            .1,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              .05,
            ),
            blurRadius: 14,
          ),
        ],
      ),

      child: child,
    );
  }
}