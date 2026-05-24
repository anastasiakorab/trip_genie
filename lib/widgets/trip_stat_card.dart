import 'package:flutter/material.dart';

class TripStatCard
    extends StatelessWidget {

  final String title;
  final String value;
  final IconData icon;

  const TripStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
      BuildContext context) {

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          24,
        ),

        color: const Color(
          0xFF6D5DFF,
        ).withOpacity(.12),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            size: 30,
            color:
                const Color(
              0xFF6D5DFF,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          Text(title),
        ],
      ),
    );
  }
}