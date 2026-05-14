import 'package:flutter/material.dart';
import '../models/trip.dart';

class CreateTripScreen extends StatefulWidget {
  final Function(Trip trip) onTripCreated;

  const CreateTripScreen({
    super.key,
    required this.onTripCreated,
  });

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {

  final _cityController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String _selectedInterest = 'Museums';

  final List<String> _interests = [
    'Museums',
    'Food',
    'Nature',
    'Shopping',
    'Nightlife',
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;

        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day}.${date.month}.${date.year}';
  }

  void _generateTrip() {

    if (_cityController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );

      return;
    }

    final trip = Trip(
      city: _cityController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      interest: _selectedInterest,
    );

    widget.onTripCreated(trip);
  }

  @override
  Widget build(BuildContext context) {

    final duration = _startDate != null && _endDate != null
        ? _endDate!.difference(_startDate!).inDays + 1
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Create Trip',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tell us where and when you want to travel.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 28),

            _inputCard(
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.location_city,
                    color: Color(0xFF6D5DFF),
                  ),
                  labelText: 'Destination city',
                  hintText: 'Example: Paris',
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [

                Expanded(
                  child: _dateCard(
                    title: 'Start date',
                    value: _formatDate(_startDate),
                    icon: Icons.play_arrow_rounded,
                    onTap: _pickStartDate,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _dateCard(
                    title: 'End date',
                    value: _formatDate(_endDate),
                    icon: Icons.stop_rounded,
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),

            if (duration != null) ...[
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [

                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF2563EB),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      'Trip duration: $duration days',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            _inputCard(
              child: TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.attach_money,
                    color: Color(0xFF6D5DFF),
                  ),
                  labelText: 'Budget',
                  hintText: 'Example: 1200',
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Travel interest',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _interests.map((interest) {

                final selected = _selectedInterest == interest;

                return ChoiceChip(
                  label: Text(interest),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedInterest = interest;
                    });
                  },

                  selectedColor: const Color(0xFFE0E7FF),
                  backgroundColor: Colors.white,

                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF4338CA)
                        : const Color(0xFF475569),

                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _generateTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D5DFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Generate Trip Plan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _dateCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Icon(
              icon,
              color: const Color(0xFF6D5DFF),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}