import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/trip.dart';
import '../services/google_places_service.dart';

class WeatherDay {
  final double maxTemp;
  final double minTemp;
  final int rainProbability;
  final int weatherCode;

  WeatherDay({
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
  final double? rating;
  final String? imageUrl;

  PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.rating,
    this.imageUrl,
  });
}

class DayActivity {
  final String timeLabel;
  final PlaceSuggestion place;

  DayActivity({
    required this.timeLabel,
    required this.place,
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
  final Set<String> _usedPlacesGlobally = {};

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
    _usedPlacesGlobally.clear();
    await _loadWeather();
    await _loadGooglePlaces();

    setState(() {
      _isLoading = false;
    });
  }

  String _formatApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  String _googleSearchQuery(String interest, String city) {
    switch (interest) {
      case 'Museums':
        return 'best museums in $city';
      case 'Food':
        return 'best restaurants in $city';
      case 'Nature':
        return 'best parks and gardens in $city';
      case 'Shopping':
        return 'best shopping places in $city';
      case 'Nightlife':
        return 'best bars and nightlife in $city';
      default:
        return 'best places to visit in $city';
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

  Future<void> _loadGooglePlaces() async {
    final trip = widget.trip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    final cityName = trip.city.split(',').first;
    final loadedPlaces = <PlaceSuggestion>[];
    final usedPlaceIds = <String>{};
    final usedPhotoNames = <String>{};

    for (final interest in trip.interests) {
      final query = _googleSearchQuery(interest, cityName);

      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText',
      );

      final body = {
        'textQuery': query,
        'maxResultCount': 20,
        'languageCode': 'en',
        'locationBias': {
          'circle': {
            'center': {
              'latitude': trip.latitude,
              'longitude': trip.longitude,
            },
            'radius': 12000.0,
          }
        }
      };

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': googleApiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.photos',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final places = data['places'] as List<dynamic>? ?? [];

          for (final place in places) {
            final id = place['id']?.toString();

            if (id == null || usedPlaceIds.contains(id)) {
              continue;
            }

            usedPlaceIds.add(id);

            final displayName = place['displayName'];
            final location = place['location'];
            final photos = place['photos'] as List<dynamic>? ?? [];

            String? imageUrl;

            for (final photo in photos) {
                final photoName = photo['name'];

                if (photoName != null && !usedPhotoNames.contains(photoName)) {
                usedPhotoNames.add(photoName);

                imageUrl =
                'https://places.googleapis.com/v1/$photoName/media?maxWidthPx=900&key=$googleApiKey';

            break;
      }
  }

            loadedPlaces.add(
              PlaceSuggestion(
                name: displayName?['text'] ?? 'Place to visit',
                address: place['formattedAddress'] ?? '',
                latitude: (location?['latitude'] as num?)?.toDouble() ?? 0,
                longitude: (location?['longitude'] as num?)?.toDouble() ?? 0,
                category: interest,
                rating: (place['rating'] as num?)?.toDouble(),
                imageUrl: imageUrl,
              ),
            );
          }
        }
      } catch (e) {
        continue;
      }
    }

    _places = loadedPlaces;
  }

  List<PlaceSuggestion> _placesByCategory(String category) {
    return _places.where((place) => place.category == category).toList();
  }

  PlaceSuggestion? _pickPlace(
  String category,
  int index,
  Set<String> usedToday,
) {
  final places = _placesByCategory(category);

  if (places.isEmpty) return null;

  for (int i = 0; i < places.length; i++) {
    final place = places[(index + i) % places.length];

   if (!usedToday.contains(place.name) &&
    !_usedPlacesGlobally.contains(place.name)) {

  usedToday.add(place.name);
  _usedPlacesGlobally.add(place.name);

  return place;
}
  }

  return null;
}

  List<DayActivity> _activitiesForDay(int dayIndex, Trip trip) {
    final activities = <DayActivity>[];
    final usedToday = <String>{};

    final selected = trip.interests;
    final hasFood = selected.contains('Food');
    final hasNightlife = selected.contains('Nightlife');

    final mainInterests = selected
        .where((interest) => interest != 'Food' && interest != 'Nightlife')
        .toList();

    if (mainInterests.isEmpty && !hasFood && !hasNightlife) {
      mainInterests.add('Museums');
    }

    if (mainInterests.isNotEmpty) {
      final morningCategory = mainInterests[dayIndex % mainInterests.length];
      final morningPlace = _pickPlace(morningCategory, dayIndex * 3, usedToday);

      if (morningPlace != null) {
        activities.add(
          DayActivity(
            timeLabel: 'Morning visit',
            place: morningPlace,
          ),
        );
      }
    }

    if (hasFood) {
      final lunchPlace = _pickPlace('Food', dayIndex * 4, usedToday);

      if (lunchPlace != null) {
        activities.add(
          DayActivity(
            timeLabel: 'Lunch stop',
            place: lunchPlace,
          ),
        );
      }
    }

    if (mainInterests.length > 1) {
      final afternoonCategory =
          mainInterests[(dayIndex + 1) % mainInterests.length];
      final afternoonPlace = _pickPlace(afternoonCategory, dayIndex * 5, usedToday);

      if (afternoonPlace != null) {
        activities.add(
          DayActivity(
            timeLabel: 'Afternoon activity',
            place: afternoonPlace,
          ),
        );
      }
    } else if (mainInterests.length == 1) {
      final afternoonPlace = _pickPlace(mainInterests.first, dayIndex * 5 + 1, usedToday);

      if (afternoonPlace != null &&
          activities.every(
            (activity) => activity.place.name != afternoonPlace.name,
          )) {
        activities.add(
          DayActivity(
            timeLabel: 'Afternoon activity',
            place: afternoonPlace,
          ),
        );
      }
    }

    if (hasNightlife) {
      final eveningPlace = _pickPlace('Nightlife', dayIndex * 6, usedToday);

      if (eveningPlace != null) {
        activities.add(
          DayActivity(
            timeLabel: 'Evening activity',
            place: eveningPlace,
          ),
        );
      }
    } else if (hasFood && activities.length < 3) {
      final dinnerPlace = _pickPlace('Food', dayIndex * 7 + 2, usedToday);

      if (dinnerPlace != null &&
          activities.every(
            (activity) => activity.place.name != dinnerPlace.name,
          )) {
        activities.add(
          DayActivity(
            timeLabel: 'Dinner idea',
            place: dinnerPlace,
          ),
        );
      }
    }

    if (activities.isEmpty && _places.isNotEmpty) {
      final fallbackCount = trip.days <= 2 ? 4 : 3;

      for (int i = 0; i < fallbackCount; i++) {
        final place = _places[(dayIndex * fallbackCount + i) % _places.length];

        activities.add(
          DayActivity(
            timeLabel: _timeLabelForIndex(i, place.category),
            place: place,
          ),
        );
      }
    }

    return activities.take(4).toList();
  }

  String _timeLabelForIndex(int index, String category) {
    if (category == 'Food' && index <= 1) return 'Lunch stop';
    if (category == 'Nightlife') return 'Evening activity';

    switch (index) {
      case 0:
        return 'Morning visit';
      case 1:
        return 'Lunch stop';
      case 2:
        return 'Afternoon activity';
      default:
        return 'Evening idea';
    }
  }

  Future<void> _openInMaps(PlaceSuggestion place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${place.latitude},${place.longitude}',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  String _budgetStyle(double dailyBudget) {
    if (dailyBudget < 80) {
      return 'Budget-friendly';
    } else if (dailyBudget < 200) {
      return 'Balanced';
    } else {
      return 'Premium';
    }
  }

  Color _budgetColor(double dailyBudget) {
    if (dailyBudget < 80) {
      return const Color(0xFF16A34A);
    } else if (dailyBudget < 200) {
      return const Color(0xFF2563EB);
    } else {
      return const Color(0xFF9333EA);
    }
  }

  String _estimatedDayCost(double dailyBudget) {
    final min = (dailyBudget * 0.8).round();
    final max = (dailyBudget * 1.2).round();

    return '\$$min - \$$max';
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

    final dailyBudget = trip.budget / trip.days;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroCard(trip, dailyBudget),
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
              'Each day is organized into morning, lunch, afternoon and evening activities.',
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

                final activities = _activitiesForDay(index, trip);

                return _dayPlanCard(
                  dayNumber: index + 1,
                  weather: weather,
                  activities: activities,
                  dailyBudget: dailyBudget,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(Trip trip, double dailyBudget) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _budgetColor(dailyBudget).withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_budgetStyle(dailyBudget)} budget travel style',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '\$${trip.budget.toStringAsFixed(0)} Budget • ${_estimatedDayCost(dailyBudget)} / day',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
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
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
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
    required List<DayActivity> activities,
    required double dailyBudget,
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
                    const SizedBox(height: 4),
                    Text(
                      'Estimated daily cost: ${_estimatedDayCost(dailyBudget)}',
                      style: const TextStyle(
                        color: Color(0xFF6D5DFF),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _budgetColor(dailyBudget).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _budgetStyle(dailyBudget),
                  style: TextStyle(
                    color: _budgetColor(dailyBudget),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Text(
              'No places found for this day.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: activities.map((activity) {
                return _placeMiniCard(activity.place, activity.timeLabel);
              }).toList(),
            ),
        ],
      ),
    );
  }

 Widget _placeMiniCard(PlaceSuggestion place, String timeLabel) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    height: 260,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Positioned.fill(
            child: place.imageUrl != null
                ? Image.network(
                    place.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _imageFallback(place.category);
                    },
                  )
                : _imageFallback(place.category),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.72),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    timeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(
                      _interestIcon(place.category),
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      place.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (place.rating != null) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 20,
                      ),
                      Text(
                        place.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  place.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () => _openInMaps(place),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'Open in Maps',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.65),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _imageFallback(String category) {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFE0E7FF),
      child: Icon(
        _interestIcon(category),
        color: const Color(0xFF4338CA),
        size: 46,
      ),
    );
  }
}