import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/trip.dart';

class LocationSuggestion {
  final String title;
  final double latitude;
  final double longitude;

  LocationSuggestion({
    required this.title,
    required this.latitude,
    required this.longitude,
  });
}

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
  final _cityFocusNode = FocusNode();

  DateTime? _startDate;
  DateTime? _endDate;

  double? _selectedLatitude;
  double? _selectedLongitude;

  String _selectedInterest = 'Museums';

  List<LocationSuggestion> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  Timer? _debounce;

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
    _cityFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchLocations(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _locationSuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearchingLocation = true;
    });

    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeComponent(query)}'
      '&count=8'
      '&language=en'
      '&format=json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        final suggestions = results.map((place) {
          final name = place['name'] ?? '';
          final admin1 = place['admin1'] ?? '';
          final country = place['country'] ?? '';

          final title = [
            name,
            if (admin1.toString().isNotEmpty) admin1,
            if (country.toString().isNotEmpty) country,
          ].join(', ');

          return LocationSuggestion(
            title: title,
            latitude: (place['latitude'] as num).toDouble(),
            longitude: (place['longitude'] as num).toDouble(),
          );
        }).toList();

        setState(() {
          _locationSuggestions = suggestions;
        });
      }
    } catch (e) {
      setState(() {
        _locationSuggestions = [];
      });
    } finally {
      setState(() {
        _isSearchingLocation = false;
      });
    }
  }

  void _onCityChanged(String value) {
    _selectedLatitude = null;
    _selectedLongitude = null;

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocations(value);
    });
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
        _endDate == null ||
        _selectedLatitude == null ||
        _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose destination, dates and budget'),
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
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
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
            _locationSearchCard(),
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

  Widget _locationSearchCard() {
    return Column(
      children: [
        _inputCard(
          child: TextField(
            controller: _cityController,
            focusNode: _cityFocusNode,
            onChanged: _onCityChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: const Icon(
                Icons.location_city,
                color: Color(0xFF6D5DFF),
              ),
              labelText: 'Destination city',
              hintText: 'Where are you going?',
              suffixIcon: _isSearchingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (_locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _locationSuggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = _locationSuggestions[index];

                return ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF6D5DFF),
                  ),
                  title: Text(
                    location.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text('Destination'),
                  onTap: () {
                    setState(() {
                      _cityController.text = location.title;
                      _selectedLatitude = location.latitude;
                      _selectedLongitude = location.longitude;
                      _locationSuggestions = [];
                    });

                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
        ],
      ],
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