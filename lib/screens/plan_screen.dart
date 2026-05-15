import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/trip.dart';

const String geoapifyApiKey = '6094893db87b4f96bcc1651909807c41';

class WeatherDay {
  final String date;
  final double maxTemp;
  final double minTemp;
  final int rainProbability;
  final int weatherCode;

  WeatherDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    required this.weatherCode,
  });
}

class PlaceSuggestion {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
  final int? distance;

  PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.distance,
  });
}

class PlanScreen extends StatefulWidget {
  final Trip? trip;

  const PlanScreen({
    super.key,
    this.trip,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _isLoading = false;

  List<WeatherDay> _weatherDays = [];
  List<PlaceSuggestion> _places = [];

  @override
  void initState() {
    super.initState();
    _loadPlanData();
  }

  @override
  void didUpdateWidget(covariant PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.trip != widget.trip) {
      _loadPlanData();
    }
  }

  Future<void> _loadPlanData() async {
    setState(() {
      _isLoading = true;
      _weatherDays = [];
      _places = [];
    });

    await _loadWeather();
    await _loadPlaces();

    setState(() {
      _isLoading = false;
    });
  }

  String _formatApiDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _loadWeather() async {
    final trip = widget.trip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    final startDate = _formatApiDate(trip.startDate);
    final endDate = _formatApiDate(trip.endDate);

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${trip.latitude}'
      '&longitude=${trip.longitude}'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code'
      '&start_date=$startDate'
      '&end_date=$endDate'
      '&timezone=auto',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final daily = data['daily'];

        final dates = daily['time'] as List<dynamic>;
        final maxTemps = daily['temperature_2m_max'] as List<dynamic>;
        final minTemps = daily['temperature_2m_min'] as List<dynamic>;
        final rain = daily['precipitation_probability_max'] as List<dynamic>;
        final codes = daily['weather_code'] as List<dynamic>;

        _weatherDays = List.generate(dates.length, (index) {
          return WeatherDay(
            date: dates[index].toString(),
            maxTemp: (maxTemps[index] as num).toDouble(),
            minTemp: (minTemps[index] as num).toDouble(),
            rainProbability: (rain[index] as num?)?.toInt() ?? 0,
            weatherCode: (codes[index] as num).toInt(),
          );
        });
      }
    } catch (e) {
      _weatherDays = [];
    }
  }

  String _geoapifyCategory(String interest) {
    switch (interest) {
      case 'Museums':
        return 'entertainment.museum';
      case 'Food':
        return 'catering.restaurant';
      case 'Nature':
        return 'natural';
      case 'Shopping':
        return 'commercial.shopping_mall';
      case 'Nightlife':
        return 'entertainment.nightclub';
      default:
        return 'tourism.sights';
    }
  }

  IconData _interestIcon(String interest) {
    switch (interest) {
      case 'Museums':
        return Icons.museum;
      case 'Food':
        return Icons.restaurant;
      case 'Nature':
        return Icons.park;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Nightlife':
        return Icons.nightlife;
      default:
        return Icons.place;
    }
  }

  Future<void> _loadPlaces() async {
    final trip = widget.trip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    final List<PlaceSuggestion> allPlaces = [];

    for (final interest in trip.interests) {
      final category = _geoapifyCategory(interest);

      final url = Uri.parse(
        'https://api.geoapify.com/v2/places'
        '?categories=$category'
        '&filter=circle:${trip.longitude},${trip.latitude},8000'
        '&bias=proximity:${trip.longitude},${trip.latitude}'
        '&limit=8'
        '&apiKey=$geoapifyApiKey',
      );

      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final features = data['features'] as List<dynamic>? ?? [];

          final places = features.map((feature) {
            final props = feature['properties'];
            final geometry = feature['geometry'];
            final coordinates = geometry['coordinates'] as List<dynamic>;

            return PlaceSuggestion(
              name: props['name'] ?? 'Unknown place',
              address: props['formatted'] ?? '',
              latitude: (coordinates[1] as num).toDouble(),
              longitude: (coordinates[0] as num).toDouble(),
              category: interest,
              distance: props['distance'] is num
                  ? (props['distance'] as num).round()
                  : null,
            );
          }).toList();

          allPlaces.addAll(places);
        }
      } catch (e) {
        continue;
      }
    }

    _places = allPlaces;
  }

  List<PlaceSuggestion> _placesForDay(int dayIndex) {
    if (_places.isEmpty) return [];

    final start = dayIndex * 2;
    final result = <PlaceSuggestion>[];

    for (int i = 0; i < 2; i++) {
      final index = (start + i) % _places.length;
      result.add(_places[index]);
    }

    return result;
  }

  Future<void> _openInMaps(PlaceSuggestion place) async {
    final query = Uri.encodeComponent('${place.name} ${place.address}');
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  String _weatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code == 1 || code == 2 || code == 3) return '⛅';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code >= 95) return '⛈️';

    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    if (trip == null) {
      return const SafeArea(
        child: Center(
          child: Text(
            'Create a trip first to see your plan.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroCard(trip),

            const SizedBox(height: 30),

            const Text(
              'Your daily trip plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Places are selected based on your interests and grouped by day.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...List.generate(trip.days, (index) {
                final weather =
                    index < _weatherDays.length ? _weatherDays[index] : null;
                final places = _placesForDay(index);

                return _dayPlanCard(
                  dayNumber: index + 1,
                  weather: weather,
                  places: places,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(Trip trip) {
    final cityName = trip.city.split(',').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF312E81),
            Color(0xFF6D5DFF),
            Color(0xFF8B5CF6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D5DFF).withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip to $cityName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'AI Smart Itinerary',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _heroInfo(
                  icon: Icons.calendar_month,
                  title: 'Duration',
                  value: '${trip.days} Days',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _heroInfo(
                  icon: Icons.favorite,
                  title: 'Interests',
                  value: trip.interests.join(' • '),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  '\$${trip.budget.toStringAsFixed(0)} Budget',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayPlanCard({
    required int dayNumber,
    required WeatherDay? weather,
    required List<PlaceSuggestion> places,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: Color(0xFF4338CA),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $dayNumber',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (weather != null)
                      Text(
                        '${_weatherIcon(weather.weatherCode)} ${weather.maxTemp.round()}° / ${weather.minTemp.round()}° • Rain ${weather.rainProbability}%',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Smart day',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (places.isEmpty)
            const Text(
              'No places found for this day.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: places.asMap().entries.map((entry) {
                final index = entry.key;
                final place = entry.value;
                final timeLabel = index == 0 ? 'Morning visit' : 'Afternoon visit';

                return _placeMiniCard(place, timeLabel);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _placeMiniCard(PlaceSuggestion place, String timeLabel) {
    final distanceText = place.distance == null
        ? 'Recommended place'
        : '${(place.distance! / 1000).toStringAsFixed(1)} km from center';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _interestIcon(place.category),
              color: const Color(0xFF4338CA),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: Color(0xFF6D5DFF),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${place.category} • $distanceText',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  place.address,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(place),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text(
                      'Open in Maps',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4338CA),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}