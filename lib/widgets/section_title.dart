import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
        Brightness.dark;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.w900,
            color: isDark
                ? Colors.white
                : Colors.black,
          ),
        ),

        if (subtitle != null)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 4,
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}