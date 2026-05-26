import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../providers/create_trip_provider.dart';
import '../services/google_geocoding_service.dart';
import '../services/location_service.dart';
import '../services/open_meteo_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  const CreateTripScreen({super.key, required this.onTripCreated});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _cityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _cityFocusNode = FocusNode();

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
    final tripProvider = Provider.of<CreateTripProvider>(
      context,
      listen: false,
    );

    if (query.trim().length < 2) {
      tripProvider.clearLocationSuggestions();
      return;
    }

    tripProvider.setSearchingLocation(true);

    try {
      final results = await OpenMeteoService.searchCities(query);

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

      if (!mounted) return;

      tripProvider.setLocationSuggestions(suggestions);
    } catch (e) {
      if (!mounted) return;
      tripProvider.clearLocationSuggestions();
    } finally {
      if (mounted) {
        tripProvider.setSearchingLocation(false);
      }
    }
  }

  void _onCityChanged(String value) {
    final tripProvider = Provider.of<CreateTripProvider>(
      context,
      listen: false,
    );

    tripProvider.clearSelectedCoordinates();

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocations(value);
    });
  }

  Future<void> _useCurrentLocation() async {
    final tripProvider = Provider.of<CreateTripProvider>(
      context,
      listen: false,
    );

    tripProvider.setGettingCurrentLocation(true);

    try {
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied or unavailable'),
          ),
        );

        return;
      }

      String locationName =
          await GoogleGeocodingService.getPlaceNameFromCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          ) ??
          'Current location';

      if (locationName == 'Current location') {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;

            locationName = place.locality?.isNotEmpty == true
                ? place.locality!
                : place.subLocality?.isNotEmpty == true
                ? place.subLocality!
                : place.subAdministrativeArea?.isNotEmpty == true
                ? place.subAdministrativeArea!
                : place.administrativeArea?.isNotEmpty == true
                ? place.administrativeArea!
                : 'Current location';
          }
        } catch (_) {}
      }

      if (!mounted) return;

      _cityController.text = locationName.trim();

      tripProvider.setSelectedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tripProvider.setShowLocationMap(true);
      });

      tripProvider.clearLocationSuggestions();

      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Using your current location: $locationName')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your current location')),
      );
    } finally {
      if (mounted) {
        tripProvider.setGettingCurrentLocation(false);
      }
    }
  }

  Future<void> _pickStartDate() async {
    final tripProvider = Provider.of<CreateTripProvider>(
      context,
      listen: false,
    );

    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: tripProvider.startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      tripProvider.setStartDate(picked);
    }
  }

  Future<void> _pickEndDate() async {
    final tripProvider = Provider.of<CreateTripProvider>(
      context,
      listen: false,
    );

    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: tripProvider.endDate ?? tripProvider.startDate ?? now,
      firstDate: tripProvider.startDate ?? now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      tripProvider.setEndDate(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day}.${date.month}.${date.year}';
  }

  void _generateTrip() {
    final tripProvider = Provider.of<CreateTripProvider>(
      context,
      listen: false,
    );

    if (_cityController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty ||
        tripProvider.startDate == null ||
        tripProvider.endDate == null ||
        tripProvider.selectedLatitude == null ||
        tripProvider.selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose destination, dates and budget'),
        ),
      );
      return;
    }

    final trip = Trip(
      city: _cityController.text.trim(),
      startDate: tripProvider.startDate!,
      endDate: tripProvider.endDate!,
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      interests: tripProvider.selectedInterests.toList(),
      latitude: tripProvider.selectedLatitude,
      longitude: tripProvider.selectedLongitude,
    );

    widget.onTripCreated(trip);
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<CreateTripProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final duration =
        tripProvider.startDate != null && tripProvider.endDate != null
        ? tripProvider.endDate!.difference(tripProvider.startDate!).inDays + 1
        : null;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    const Color(0xFF312E81),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEDE9FE),
                    const Color(0xFFFDF2F8),
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
                    colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x336D5DFF),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.explore_rounded, color: Colors.white, size: 42),
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _locationSearchCard(tripProvider),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: tripProvider.gettingCurrentLocation
                      ? null
                      : _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    tripProvider.gettingCurrentLocation
                        ? 'Detecting location...'
                        : 'Use my current location',
                  ),
                ),
              ),

              if (tripProvider.showLocationMap &&
                  tripProvider.selectedLatitude != null &&
                  tripProvider.selectedLongitude != null) ...[
                const SizedBox(height: 14),
                _currentLocationMapCard(tripProvider),
              ],

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _dateCard(
                      title: 'Departure',
                      value: _formatDate(tripProvider.startDate),
                      icon: Icons.flight_takeoff,
                      onTap: _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _dateCard(
                      title: 'Return',
                      value: _formatDate(tripProvider.endDate),
                      icon: Icons.flight_land,
                      onTap: _pickEndDate,
                    ),
                  ),
                ],
              ),
              if (duration != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '$duration day trip',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _inputCard(
                child: TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: const Icon(
                      Icons.attach_money_rounded,
                      color: Color(0xFF6D5DFF),
                    ),
                    labelText: 'Trip budget',
                    hintText: 'Example: 1200',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'What do you enjoy?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _interests.map((interest) {
                  final selected = tripProvider.selectedInterests.contains(
                    interest,
                  );

                  return ChoiceChip(
                    label: Text(
                      interest,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF111827)),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      tripProvider.toggleInterest(interest);
                    },
                    selectedColor: const Color(0xFF6D5DFF),
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 35),
              Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _generateTrip,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Generate AI Trip',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationSearchCard(CreateTripProvider tripProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _inputCard(
          child: TextField(
            controller: _cityController,
            focusNode: _cityFocusNode,
            onChanged: _onCityChanged,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: const Icon(Icons.location_city, color: Color(0xFF6D5DFF)),
              labelText: 'Destination city',
              hintText: 'Where are you going?',
              labelStyle: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              ),
              suffixIcon: tripProvider.isSearchingLocation
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
        if (tripProvider.locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: .96)
                  : Colors.white.withValues(alpha: .95),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tripProvider.locationSuggestions.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              itemBuilder: (context, index) {
                final location = tripProvider.locationSuggestions[index];

                return ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF6D5DFF),
                  ),
                  title: Text(
                    location.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  subtitle: Text(
                    'Destination',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    _cityController.text = location.title;

                    tripProvider.setSelectedLocation(
                      latitude: location.latitude,
                      longitude: location.longitude,
                    );

                    tripProvider.clearLocationSuggestions();

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

  Widget _currentLocationMapCard(CreateTripProvider tripProvider) {
    final latitude = tripProvider.selectedLatitude;
    final longitude = tripProvider.selectedLongitude;

    if (latitude == null || longitude == null) {
      return const SizedBox.shrink();
    }

    final position = LatLng(latitude, longitude);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(
              markerId: const MarkerId('current_location'),
              position: position,
              infoWindow: const InfoWindow(title: 'Your current location'),
            ),
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }

  Widget _inputCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: .92)
            : Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .08)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: .92)
              : Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6D5DFF)),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
