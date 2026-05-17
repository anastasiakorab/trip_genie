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

  final Set<String> _selectedInterests = {'Museums'};

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
      interests: _selectedInterests.toList(),
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
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFEDE9FE),
            Color(0xFFFDF2F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6D5DFF),
                    Color(0xFFEC4899),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x336D5DFF),
                    blurRadius: 24,
                    offset: Offset(0,10),
                  )
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 42,
                  ),

                  SizedBox(height: 18),

                  Text(
                    'Design your next escape ✈️',
                    style: TextStyle(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Choose where you want to go and let AI organize the details.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height:30),

            _locationSearchCard(),

            const SizedBox(height:18),

            Row(
              children: [
                Expanded(
                  child: _dateCard(
                    title: 'Departure',
                    value: _formatDate(_startDate),
                    icon: Icons.flight_takeoff,
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(width:14),
                Expanded(
                  child: _dateCard(
                    title: 'Return',
                    value: _formatDate(_endDate),
                    icon: Icons.flight_land,
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),

            if(duration!=null)...[
              const SizedBox(height:18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 14,
                    )
                  ]
                ),
                child: Row(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF4338CA),
                      ),
                    ),

                    const SizedBox(width:14),

                    Text(
                      '$duration day trip',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              )
            ],

            const SizedBox(height:18),

            _inputCard(
              child: TextField(
                controller:_budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.attach_money_rounded,
                    color: Color(0xFF6D5DFF),
                  ),
                  labelText: 'Trip budget',
                  hintText: 'Example: 1200',
                ),
              ),
            ),

            const SizedBox(height:30),

            const Text(
              'What do you enjoy?',
              style: TextStyle(
                fontSize:22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height:10),

            Wrap(
              spacing:12,
              runSpacing:12,
              children:_interests.map((interest){

                final selected =
                    _selectedInterests.contains(interest);

                return ChoiceChip(
                  padding: const EdgeInsets.symmetric(
                    horizontal:12,
                    vertical:10,
                  ),
                  label: Text(interest),
                  selected:selected,
                  onSelected:(_){

                    setState(() {

                      if(selected){

                        if(_selectedInterests.length>1){
                          _selectedInterests.remove(interest);
                        }

                      }else{
                        _selectedInterests.add(interest);
                      }
                    });

                  },

                  selectedColor: const Color(0xFF6D5DFF),
                  backgroundColor: Colors.white,

                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF475569),

                    fontWeight: FontWeight.w800,
                  ),
                );

              }).toList(),
            ),

            const SizedBox(height:35),

            Container(
              width: double.infinity,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6D5DFF),
                    Color(0xFFEC4899),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x336D5DFF),
                    blurRadius:18,
                    offset: Offset(0,10),
                  )
                ]
              ),
              child: ElevatedButton.icon(
                onPressed:_generateTrip,

                icon: const Icon(Icons.auto_awesome),

                label: const Text(
                  'Generate AI Trip',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize:16,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                ),
              ),
              
            )
           )
          ],
        ),
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
              color: Colors.white.withOpacity(.95),
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
      horizontal:18,
      vertical:8,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.92),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.04),
          blurRadius:12,
          offset: const Offset(0,6),
        )
      ],
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
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    ),
  );
}
}