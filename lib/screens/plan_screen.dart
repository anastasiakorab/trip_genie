import 'package:flutter/material.dart';
import '../models/trip.dart';

class PlanScreen extends StatelessWidget {
  final Trip? trip;

  const PlanScreen({
    super.key,
    required this.trip,
  });

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  List<String> _activitiesByInterest(String interest) {
    if (interest == 'Food') {
      return ['Local breakfast spot', 'Traditional restaurant', 'Food market'];
    }

    if (interest == 'Nature') {
      return ['City park walk', 'Viewpoint', 'Lake or garden visit'];
    }

    if (interest == 'Shopping') {
      return ['Shopping district', 'Local market', 'Souvenir store'];
    }

    if (interest == 'Nightlife') {
      return ['Evening walk', 'Rooftop bar', 'Live music place'];
    }

    return ['Museum visit', 'Historic landmark', 'Art gallery'];
  }

  @override
  Widget build(BuildContext context) {
    if (trip == null) {
      return const SafeArea(
        child: Center(
          child: Text(
            'No trip created yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    final activities = _activitiesByInterest(trip!.interest);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroCard(),
            const SizedBox(height: 26),
            const Text(
              'Trip Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _summaryCard(),
            const SizedBox(height: 28),
            const Text(
              'Your Itinerary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(trip!.days, (index) {
              return _dayCard(index + 1, activities);
            }),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EA5E9),
            Color(0xFF6D5DFF),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.map_outlined,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: 20),
          Text(
            '${trip!.city} Adventure',
            style: const TextStyle(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_formatDate(trip!.startDate)} - ${_formatDate(trip!.endDate)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${trip!.days} days • ${trip!.interest} • \$${trip!.budget.toStringAsFixed(0)} budget',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _summaryItem(Icons.location_on, 'City', trip!.city)),
              const SizedBox(width: 12),
              Expanded(child: _summaryItem(Icons.calendar_month, 'Days', '${trip!.days}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryItem(Icons.interests, 'Interest', trip!.interest)),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
                  Icons.attach_money,
                  'Budget',
                  '\$${trip!.budget.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6D5DFF)),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(int dayNumber, List<String> activities) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE0E7FF),
                child: Text(
                  '$dayNumber',
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Day $dayNumber',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _activityItem(1, activities[0]),
          const SizedBox(height: 10),
          _activityItem(2, activities[1]),
          const SizedBox(height: 10),
          _activityItem(3, activities[2]),
        ],
      ),
    );
  }

  Widget _activityItem(int number, String title) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            '0$number',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF6D5DFF),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.place_outlined,
            color: Color(0xFF6D5DFF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}