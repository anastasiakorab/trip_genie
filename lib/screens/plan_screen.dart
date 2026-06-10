import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/plan_provider.dart';
import '../models/trip.dart';
import '../services/google_places_service.dart';
import '../services/open_meteo_service.dart';

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
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
  final double? rating;
  final String? imageUrl;
  final double estimatedCost;
  final String? priceLevel;
  final int? userRatingCount;
  final List<String> types;
  final String? ticketUrl;
  final String costSource;
  final String costGroup;
  final bool includeInDayTotal;

  PlaceSuggestion({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.estimatedCost,
    required this.costSource,
    required this.costGroup,
    required this.includeInDayTotal,
    this.priceLevel,
    this.userRatingCount,
    this.types = const [],
    this.ticketUrl,
    this.rating,
    this.imageUrl,
  });
}

class DayActivity {
  final String timeLabel;
  final PlaceSuggestion place;

  DayActivity({required this.timeLabel, required this.place});
}

class _CostEstimate {
  final double cost;
  final String source;
  final String group;
  final bool includeInDayTotal;
  final String? ticketUrl;

  const _CostEstimate({
    required this.cost,
    required this.source,
    required this.group,
    required this.includeInDayTotal,
    this.ticketUrl,
  });
}

class _TicketmasterEstimate {
  final double price;
  final String source;
  final String? url;

  const _TicketmasterEstimate({
    required this.price,
    required this.source,
    this.url,
  });
}

class PlanScreen extends StatefulWidget {
  final Trip? trip;

  const PlanScreen({super.key, this.trip});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final Set<String> _usedPlacesGlobally = {};
  String? _resolvedTripCityName;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlanData();
    });
  }

  @override
  void didUpdateWidget(covariant PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.trip != widget.trip) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPlanData();
      });
    }
  }

  Future<void> _loadPlanData() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    planProvider.setLoading(true);
    planProvider.setWeather([]);
    planProvider.setPlaces([]);

    _usedPlacesGlobally.clear();

    await _resolveTripCityName();
    await _loadWeather();
    await _loadGooglePlaces();

    if (!mounted) return;

    planProvider.setLoading(false);
  }

  Future<void> _resolveTripCityName() async {
    final trip = widget.trip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    final rawCity = trip.city.trim();

    if (!rawCity.toLowerCase().contains('current location')) {
      _resolvedTripCityName = rawCity.split(',').first.trim();
      return;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${trip.latitude},${trip.longitude}'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        if (results.isNotEmpty) {
          final components =
              results.first['address_components'] as List<dynamic>? ?? [];

          String? city;
          String? adminArea;

          for (final component in components) {
            final types = (component['types'] as List<dynamic>? ?? [])
                .map((type) => type.toString())
                .toList();

            final longName = component['long_name']?.toString();

            if (longName == null || longName.isEmpty) continue;

            if (types.contains('locality')) {
              city ??= longName;
            }

            if (types.contains('administrative_area_level_1')) {
              adminArea ??= longName;
            }
          }

          final resolvedName = city ?? adminArea;

          if (resolvedName != null && resolvedName.isNotEmpty) {
            _resolvedTripCityName = resolvedName;
            return;
          }
        }
      }
    } catch (e) {
      // If Google reverse geocoding fails, fallback below is used.
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        trip.latitude!,
        trip.longitude!,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city = place.locality;
        final subAdmin = place.subAdministrativeArea;
        final adminArea = place.administrativeArea;

        if (city != null && city.isNotEmpty) {
          _resolvedTripCityName = city;
        } else if (subAdmin != null && subAdmin.isNotEmpty) {
          _resolvedTripCityName = subAdmin;
        } else if (adminArea != null && adminArea.isNotEmpty) {
          _resolvedTripCityName = adminArea;
        }
      }
    } catch (e) {
      // Keep fallback name below.
    }

    _resolvedTripCityName ??= 'Current location';
  }

  String _displayCityName(Trip trip, List<PlaceSuggestion> places) {
    final rawCity = trip.city.trim();

    if (rawCity.toLowerCase().contains('current location')) {
      final addressParts = places
          .map((place) => place.address)
          .where((address) => address.isNotEmpty)
          .join(', ');

      if (addressParts.toLowerCase().contains('skopje')) {
        return 'Skopje';
      }

      if (_resolvedTripCityName != null &&
          _resolvedTripCityName!.isNotEmpty &&
          !_resolvedTripCityName!.toLowerCase().contains('current')) {
        return _resolvedTripCityName!;
      }

      return 'Detected city';
    }

    return rawCity.split(',').first.trim();
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  String _formatApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadWeather() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    final trip = widget.trip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    final startDate = _formatApiDate(trip.startDate);
    final endDate = _formatApiDate(trip.endDate);

    try {
      final data = await OpenMeteoService.getWeather(
        latitude: trip.latitude!,
        longitude: trip.longitude!,
        startDate: startDate,
        endDate: endDate,
      );

      if (data == null) {
        planProvider.setWeather([]);
        return;
      }

      final daily = data['daily'];

      final dates = daily['time'] as List<dynamic>;
      final maxTemps = daily['temperature_2m_max'] as List<dynamic>;
      final minTemps = daily['temperature_2m_min'] as List<dynamic>;
      final rain = daily['precipitation_probability_max'] as List<dynamic>;
      final codes = daily['weather_code'] as List<dynamic>;

      final weather = List.generate(dates.length, (index) {
        return WeatherDay(
          maxTemp: (maxTemps[index] as num).toDouble(),
          minTemp: (minTemps[index] as num).toDouble(),
          rainProbability: (rain[index] as num?)?.toInt() ?? 0,
          weatherCode: (codes[index] as num).toInt(),
        );
      });

      if (!mounted) return;

      planProvider.setWeather(weather);
    } catch (e) {
      planProvider.setWeather([]);
    }
  }

  List<String> _googlePlaceTypes(String interest) {
    switch (interest) {
      case 'Museums':
        return ['museum', 'tourist_attraction'];
      case 'Food':
        return ['restaurant', 'cafe'];
      case 'Nature':
        return ['park', 'tourist_attraction'];
      case 'Shopping':
        return ['shopping_mall', 'store'];
      case 'Nightlife':
        return ['bar', 'night_club'];
      case 'Concerts':
        return ['event_venue', 'performing_arts_theater'];
      case 'Sports':
        return ['stadium', 'gym'];
      case 'History':
        return ['historical_landmark', 'tourist_attraction'];
      case 'Art':
        return ['art_gallery', 'museum'];
      case 'Beaches':
        return ['tourist_attraction'];
      case 'Adventure':
        return ['amusement_park', 'tourist_attraction'];
      case 'Family':
        return ['zoo', 'amusement_park', 'aquarium'];
      default:
        return ['tourist_attraction'];
    }
  }

  String _fallbackSearchQuery(String interest, String cityName) {
    switch (interest) {
      case 'Museums':
        return 'museums and attractions near $cityName';

      case 'Food':
        return 'restaurants near $cityName';

      case 'Nature':
        return 'parks and nature attractions near $cityName';

      case 'Shopping':
        return 'shopping malls and markets near $cityName';

      case 'Nightlife':
        return 'bars and nightlife near $cityName';

      case 'Concerts':
        return 'concerts and live music venues near $cityName';

      case 'Sports':
        return 'sports activities and stadiums near $cityName';

      case 'History':
        return 'historical places and landmarks near $cityName';

      case 'Art':
        return 'art galleries and creative places near $cityName';

      case 'Beaches':
        return 'beaches near $cityName';

      case 'Adventure':
        return 'adventure activities near $cityName';

      case 'Family':
        return 'family friendly attractions near $cityName';

      default:
        return 'tourist attractions near $cityName';
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

      case 'Concerts':
        return Icons.music_note;

      case 'Sports':
        return Icons.sports_soccer;

      case 'History':
        return Icons.account_balance;

      case 'Art':
        return Icons.palette;

      case 'Beaches':
        return Icons.beach_access;

      case 'Adventure':
        return Icons.hiking;

      case 'Family':
        return Icons.family_restroom;

      default:
        return Icons.place;
    }
  }

  bool _containsAny(String value, List<String> keywords) {
    final text = value.toLowerCase();
    return keywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }

  bool _hasType(List<String> types, List<String> wantedTypes) {
    final lowerTypes = types.map((type) => type.toLowerCase()).toSet();
    return wantedTypes.any((type) => lowerTypes.contains(type.toLowerCase()));
  }

  double? _costFromGooglePriceLevel(String category, String? priceLevel) {
    if (priceLevel == null || priceLevel.isEmpty) return null;

    final isNightlife = category == 'Nightlife';

    switch (priceLevel) {
      case 'PRICE_LEVEL_FREE':
        return 0;
      case 'PRICE_LEVEL_INEXPENSIVE':
        return isNightlife ? 15 : 12;
      case 'PRICE_LEVEL_MODERATE':
        return isNightlife ? 30 : 25;
      case 'PRICE_LEVEL_EXPENSIVE':
        return isNightlife ? 55 : 45;
      case 'PRICE_LEVEL_VERY_EXPENSIVE':
        return isNightlife ? 85 : 70;
      default:
        return null;
    }
  }

  String _readablePriceLevel(String? priceLevel) {
    switch (priceLevel) {
      case 'PRICE_LEVEL_FREE':
        return 'Free';
      case 'PRICE_LEVEL_INEXPENSIVE':
        return 'Inexpensive';
      case 'PRICE_LEVEL_MODERATE':
        return 'Moderate';
      case 'PRICE_LEVEL_EXPENSIVE':
        return 'Expensive';
      case 'PRICE_LEVEL_VERY_EXPENSIVE':
        return 'Very expensive';
      default:
        return 'Not available';
    }
  }

  String _costGroupForCategory(String category) {
    switch (category) {
      case 'Food':
      case 'Nightlife':
        return 'Food & drinks';
      case 'Museums':
      case 'History':
      case 'Art':
      case 'Concerts':
      case 'Sports':
      case 'Adventure':
      case 'Family':
        return 'Tickets & attractions';
      case 'Nature':
      case 'Beaches':
        return 'Outdoor / free places';
      case 'Shopping':
        return 'Optional shopping allowance';
      default:
        return 'Other estimates';
    }
  }

  double _popularityBoost(double? rating, int? userRatingCount) {
    final reviews = userRatingCount ?? 0;
    final placeRating = rating ?? 0;

    if (placeRating >= 4.7 && reviews >= 5000) return 10;
    if (placeRating >= 4.5 && reviews >= 1500) return 7;
    if (placeRating >= 4.3 && reviews >= 500) return 4;
    if (placeRating > 0 && placeRating < 4.0) return -3;
    return 0;
  }

  double _budgetAdjustment(double dailyBudget) {
    if (dailyBudget < 80) return -4;
    if (dailyBudget >= 200) return 6;
    return 0;
  }

  double _clampCost(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  bool _looksLikePaidOutdoorPlace({
    required String name,
    required List<String> types,
  }) {
    return _containsAny(name, [
          'beach club',
          'private beach',
          'lido',
          'resort',
          'water park',
          'aquapark',
          'aqua park',
          'botanical garden',
          'national park',
          'theme park',
          'amusement park',
        ]) ||
        _hasType(types, ['amusement_park', 'water_park', 'national_park']);
  }

  double _estimateCulturalTicket({
    required String category,
    required String name,
    required double dailyBudget,
    required double? rating,
    required int? userRatingCount,
    required List<String> types,
  }) {
    double base;

    if (_containsAny(name, ['palace', 'castle', 'tower', 'cathedral'])) {
      base = 20;
    } else if (_hasType(types, ['museum'])) {
      base = 18;
    } else if (_hasType(types, ['art_gallery'])) {
      base = 14;
    } else if (_hasType(types, ['historical_landmark'])) {
      base = 15;
    } else {
      switch (category) {
        case 'Museums':
          base = 18;
          break;
        case 'Art':
          base = 14;
          break;
        case 'History':
          base = 15;
          break;
        default:
          base = 16;
      }
    }

    final estimate =
        base +
        _popularityBoost(rating, userRatingCount) +
        _budgetAdjustment(dailyBudget);

    return _clampCost(estimate, 6, 38).roundToDouble();
  }

  double _estimateActivityTicket({
    required String category,
    required String name,
    required double dailyBudget,
    required double? rating,
    required int? userRatingCount,
    required List<String> types,
  }) {
    double base;

    if (_containsAny(name, ['disney', 'theme park', 'amusement park']) ||
        _hasType(types, ['amusement_park'])) {
      base = 65;
    } else if (_containsAny(name, ['aquarium', 'zoo']) ||
        _hasType(types, ['aquarium', 'zoo'])) {
      base = 28;
    } else if (_containsAny(name, ['stadium', 'arena'])) {
      base = 25;
    } else if (_containsAny(name, [
      'tour',
      'climbing',
      'escape',
      'adventure',
    ])) {
      base = 35;
    } else {
      switch (category) {
        case 'Family':
          base = 25;
          break;
        case 'Sports':
          base = 25;
          break;
        case 'Adventure':
          base = 35;
          break;
        default:
          base = 25;
      }
    }

    final estimate =
        base +
        (_popularityBoost(rating, userRatingCount) / 2) +
        _budgetAdjustment(dailyBudget);

    return _clampCost(estimate, 8, 95).roundToDouble();
  }

  Future<_TicketmasterEstimate?> _ticketmasterEstimate({
    required String category,
    required String placeName,
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = dotenv.env['TICKETMASTER_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    final classification = category == 'Concerts' ? 'music' : 'sports';

    final uri = Uri.https('app.ticketmaster.com', '/discovery/v2/events.json', {
      'apikey': apiKey,
      'keyword': placeName,
      'latlong':
          '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}',
      'radius': '30',
      'unit': 'km',
      'size': '10',
      'classificationName': classification,
      'sort': 'relevance,desc',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final events =
          data['_embedded']?['events'] as List<dynamic>? ?? <dynamic>[];

      for (final event in events) {
        final priceRanges = event['priceRanges'] as List<dynamic>? ?? [];
        final eventUrl = event['url']?.toString();

        for (final range in priceRanges) {
          final currency = range['currency']?.toString();
          final minPrice = (range['min'] as num?)?.toDouble();

          if (minPrice != null && currency == 'EUR') {
            return _TicketmasterEstimate(
              price: minPrice,
              source:
                  'Ticketmaster event price range: from €${minPrice.round()}',
              url: eventUrl,
            );
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<_CostEstimate> _estimateCostForPlace({
    required String category,
    required String name,
    required double dailyBudget,
    required String? priceLevel,
    required double? rating,
    required int? userRatingCount,
    required List<String> types,
    required double latitude,
    required double longitude,
  }) async {
    final googlePrice = _costFromGooglePriceLevel(category, priceLevel);

    if ((category == 'Food' || category == 'Nightlife') &&
        googlePrice != null) {
      return _CostEstimate(
        cost: googlePrice,
        source: 'Google Places price level: ${_readablePriceLevel(priceLevel)}',
        group: 'Food & drinks',
        includeInDayTotal: true,
      );
    }

    switch (category) {
      case 'Food':
        return _CostEstimate(
          cost: dailyBudget < 80
              ? 15
              : dailyBudget < 200
              ? 30
              : 55,
          source: 'Estimated based on restaurant category and selected budget style',
          group: 'Food & drinks',
          includeInDayTotal: true,
        );

      case 'Nightlife':
        return _CostEstimate(
          cost: dailyBudget < 80
              ? 18
              : dailyBudget < 200
              ? 35
              : 70,
          source:
              'Estimated based on nightlife category and selected budget style',
          group: 'Food & drinks',
          includeInDayTotal: true,
        );

      case 'Nature':
      case 'Beaches':
        if (_looksLikePaidOutdoorPlace(name: name, types: types)) {
          final cost =
              _containsAny(name, ['water park', 'aquapark', 'amusement'])
              ? 35.0
              : 12.0;
          return _CostEstimate(
            cost: cost,
            source: 'Paid outdoor venue estimate based on place type/name',
            group: 'Tickets & attractions',
            includeInDayTotal: true,
          );
        }

        return _CostEstimate(
          cost: 0,
          source: category == 'Beaches'
              ? 'Free public beach / outdoor place estimate'
              : 'Free public park / outdoor place estimate',
          group: 'Outdoor / free places',
          includeInDayTotal: true,
        );

      case 'Shopping':
        return _CostEstimate(
          cost: dailyBudget < 80
              ? 20
              : dailyBudget < 200
              ? 45
              : 90,
          source:
              'Optional personal shopping allowance; not included in daily total',
          group: 'Optional shopping allowance',
          includeInDayTotal: false,
        );

      case 'Museums':
      case 'Art':
      case 'History':
        final cost = _estimateCulturalTicket(
          category: category,
          name: name,
          dailyBudget: dailyBudget,
          rating: rating,
          userRatingCount: userRatingCount,
          types: types,
        );

        return _CostEstimate(
          cost: cost,
          source:
              'Google Places rating/review popularity + attraction-type ticket estimate',
          group: 'Tickets & attractions',
          includeInDayTotal: true,
        );

      case 'Concerts':
      case 'Sports':
        final ticketmaster = await _ticketmasterEstimate(
          category: category,
          placeName: name,
          latitude: latitude,
          longitude: longitude,
        );

        if (ticketmaster != null) {
          return _CostEstimate(
            cost: ticketmaster.price,
            source: ticketmaster.source,
            group: 'Tickets & attractions',
            includeInDayTotal: true,
            ticketUrl: ticketmaster.url,
          );
        }

        final double fallbackCost = category == 'Concerts'
            ? (dailyBudget < 80
                  ? 30.0
                  : dailyBudget < 200
                  ? 55.0
                  : 110.0)
            : _estimateActivityTicket(
                category: category,
                name: name,
                dailyBudget: dailyBudget,
                rating: rating,
                userRatingCount: userRatingCount,
                types: types,
              );

        return _CostEstimate(
          cost: fallbackCost,
          source: category == 'Concerts'
              ? 'Ticketmaster not configured/no EUR price found; event ticket fallback estimate'
              : 'Ticketmaster not configured/no EUR price found; sports venue/activity estimate',
          group: 'Tickets & attractions',
          includeInDayTotal: true,
        );

      case 'Adventure':
      case 'Family':
        final cost = _estimateActivityTicket(
          category: category,
          name: name,
          dailyBudget: dailyBudget,
          rating: rating,
          userRatingCount: userRatingCount,
          types: types,
        );

        return _CostEstimate(
          cost: cost,
          source:
              'Place type + popularity estimate for paid attraction/activity',
          group: 'Tickets & attractions',
          includeInDayTotal: true,
        );

      default:
        return _CostEstimate(
          cost: dailyBudget < 80
              ? 10
              : dailyBudget < 200
              ? 25
              : 50,
          source: 'Category-based fallback estimate',
          group: 'Other estimates',
          includeInDayTotal: true,
        );
    }
  }

  Map<String, double> _dayCostBreakdown(List<DayActivity> activities) {
    final breakdown = <String, double>{};

    for (final activity in activities) {
      final group = activity.place.costGroup;
      breakdown[group] = (breakdown[group] ?? 0) + activity.place.estimatedCost;
    }

    return breakdown;
  }

  Future<void> _loadGooglePlaces() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    final trip = widget.trip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    final cityName = _displayCityName(
      trip,
      planProvider.places.cast<PlaceSuggestion>(),
    );
    final loadedPlaces = <PlaceSuggestion>[];
    final usedPlaceIds = <String>{};
    final usedPhotoNames = <String>{};

    Future<void> addPlaceFromJson(dynamic place, String interest) async {
      final id = place['id']?.toString();

      if (id == null || usedPlaceIds.contains(id)) {
        return;
      }

      final displayName = place['displayName'];
      final location = place['location'];

      final placeLat = (location?['latitude'] as num?)?.toDouble();
      final placeLng = (location?['longitude'] as num?)?.toDouble();

      if (placeLat == null || placeLng == null) {
        return;
      }

      final distance = _distanceKm(
        trip.latitude!,
        trip.longitude!,
        placeLat,
        placeLng,
      );

      // Keep only realistic nearby places.
      // This prevents Sofia/USA/Canada results when the user is in Skopje.
      if (distance > 80) {
        return;
      }

      usedPlaceIds.add(id);

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
      final placeName = displayName?['text']?.toString() ?? 'Place to visit';
      final priceLevel = place['priceLevel']?.toString();
      final rating = (place['rating'] as num?)?.toDouble();
      final userRatingCount = (place['userRatingCount'] as num?)?.toInt();
      final types = (place['types'] as List<dynamic>? ?? [])
          .map((type) => type.toString())
          .toList();
      final dailyBudget = trip.budget / trip.days;

      final costEstimate = await _estimateCostForPlace(
        category: interest,
        name: placeName,
        dailyBudget: dailyBudget,
        priceLevel: priceLevel,
        rating: rating,
        userRatingCount: userRatingCount,
        types: types,
        latitude: placeLat,
        longitude: placeLng,
      );

      loadedPlaces.add(
        PlaceSuggestion(
          id: id,
          name: placeName,
          address: place['formattedAddress'] ?? '',
          latitude: placeLat,
          longitude: placeLng,
          category: interest,
          estimatedCost: costEstimate.cost,
          costSource: costEstimate.source,
          costGroup: costEstimate.group,
          includeInDayTotal: costEstimate.includeInDayTotal,
          priceLevel: priceLevel,
          userRatingCount: userRatingCount,
          types: types,
          ticketUrl: costEstimate.ticketUrl,
          rating: rating,
          imageUrl: imageUrl,
        ),
      );
    }

    for (final interest in trip.interests) {
      final beforeInterestCount = loadedPlaces.length;

      // Main method: Nearby Search. This searches around the GPS coordinates,
      // so it works for current location and does not depend on city text.
      for (final type in _googlePlaceTypes(interest)) {
        final url = Uri.parse(
          'https://places.googleapis.com/v1/places:searchNearby',
        );

        final body = {
          'includedTypes': [type],
          'maxResultCount': 10,
          'languageCode': 'en',
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': trip.latitude,
                'longitude': trip.longitude,
              },
              'radius': 25000.0,
            },
          },
        };

        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': googleApiKey,
              'X-Goog-FieldMask':
                  'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.photos,places.priceLevel',
            },
            body: jsonEncode(body),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final places = data['places'] as List<dynamic>? ?? [];

            for (final place in places) {
              await addPlaceFromJson(place, interest);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Fallback: Text Search with location bias.
      // Used only if Nearby Search found nothing for this interest.
      if (loadedPlaces.length == beforeInterestCount) {
        final url = Uri.parse(
          'https://places.googleapis.com/v1/places:searchText',
        );

        final body = {
          'textQuery': _fallbackSearchQuery(interest, cityName),
          'maxResultCount': 10,
          'languageCode': 'en',
          'locationBias': {
            'circle': {
              'center': {
                'latitude': trip.latitude,
                'longitude': trip.longitude,
              },
              'radius': 25000.0,
            },
          },
        };

        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': googleApiKey,
              'X-Goog-FieldMask':
                  'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.photos,places.priceLevel',
            },
            body: jsonEncode(body),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final places = data['places'] as List<dynamic>? ?? [];

            for (final place in places) {
              await addPlaceFromJson(place, interest);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    if (!mounted) return;
    planProvider.setPlaces(loadedPlaces);
  }

  List<PlaceSuggestion> _placesByCategory(
    String category,
    List<PlaceSuggestion> places,
  ) {
    return places.where((place) => place.category == category).toList();
  }

  PlaceSuggestion? _pickPlace(
    String category,
    int index,
    Set<String> usedToday,
    List<PlaceSuggestion> places,
  ) {
    final categoryPlaces = _placesByCategory(category, places);

    if (categoryPlaces.isEmpty) return null;

    for (int i = 0; i < categoryPlaces.length; i++) {
      final place = categoryPlaces[(index + i) % categoryPlaces.length];

      if (!usedToday.contains(place.name) &&
          !_usedPlacesGlobally.contains(place.name)) {
        usedToday.add(place.name);
        _usedPlacesGlobally.add(place.name);

        return place;
      }
    }

    return null;
  }

  List<DayActivity> _activitiesForDay(
    int dayIndex,
    Trip trip,
    List<PlaceSuggestion> places,
  ) {
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
      final morningPlace = _pickPlace(
        morningCategory,
        dayIndex * 3,
        usedToday,
        places,
      );

      if (morningPlace != null) {
        activities.add(
          DayActivity(timeLabel: 'Morning visit', place: morningPlace),
        );
      }
    }

    if (hasFood) {
      final lunchPlace = _pickPlace('Food', dayIndex * 4, usedToday, places);

      if (lunchPlace != null) {
        activities.add(DayActivity(timeLabel: 'Lunch stop', place: lunchPlace));
      }
    }

    if (mainInterests.length > 1) {
      final afternoonCategory =
          mainInterests[(dayIndex + 1) % mainInterests.length];
      final afternoonPlace = _pickPlace(
        afternoonCategory,
        dayIndex * 5,
        usedToday,
        places,
      );

      if (afternoonPlace != null) {
        activities.add(
          DayActivity(timeLabel: 'Afternoon activity', place: afternoonPlace),
        );
      }
    } else if (mainInterests.length == 1) {
      final afternoonPlace = _pickPlace(
        mainInterests.first,
        dayIndex * 5 + 1,
        usedToday,
        places,
      );

      if (afternoonPlace != null &&
          activities.every(
            (activity) => activity.place.name != afternoonPlace.name,
          )) {
        activities.add(
          DayActivity(timeLabel: 'Afternoon activity', place: afternoonPlace),
        );
      }
    }

    if (hasNightlife) {
      final eveningPlace = _pickPlace(
        'Nightlife',
        dayIndex * 6,
        usedToday,
        places,
      );

      if (eveningPlace != null) {
        activities.add(
          DayActivity(timeLabel: 'Evening activity', place: eveningPlace),
        );
      }
    } else if (hasFood && activities.length < 3) {
      final dinnerPlace = _pickPlace(
        'Food',
        dayIndex * 7 + 2,
        usedToday,
        places,
      );

      if (dinnerPlace != null &&
          activities.every(
            (activity) => activity.place.name != dinnerPlace.name,
          )) {
        activities.add(
          DayActivity(timeLabel: 'Dinner idea', place: dinnerPlace),
        );
      }
    }

    if (activities.isEmpty && places.isNotEmpty) {
      final fallbackCount = trip.days <= 2 ? 4 : 3;

      for (
        int i = 0;
        i < places.length && activities.length < fallbackCount;
        i++
      ) {
        final place = places[(dayIndex * fallbackCount + i) % places.length];

        if (_usedPlacesGlobally.contains(place.name)) {
          continue;
        }

        _usedPlacesGlobally.add(place.name);

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

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveTripToFirestore() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    final trip = widget.trip;
    if (trip == null) return;

    final places = planProvider.places.cast<PlaceSuggestion>();

    planProvider.setSavingTrip(true);

    _usedPlacesGlobally.clear();

    final plannedDays = <Map<String, dynamic>>[];
    final previewPlaces = <Map<String, dynamic>>[];

    for (int dayIndex = 0; dayIndex < trip.days; dayIndex++) {
      final activities = _activitiesForDay(dayIndex, trip, places);

      final activityData = activities.map((activity) {
        return {
          'timeLabel': activity.timeLabel,

          'placeId': activity.place.id,
          'placeName': activity.place.name,
          'address': activity.place.address,
          'category': activity.place.category,
          'estimatedCost': activity.place.estimatedCost,
          'costSource': activity.place.costSource,
          'costGroup': activity.place.costGroup,
          'includeInDayTotal': activity.place.includeInDayTotal,
          'priceLevel': activity.place.priceLevel,
          'userRatingCount': activity.place.userRatingCount,
          'types': activity.place.types,
          'ticketUrl': activity.place.ticketUrl,

          'latitude': activity.place.latitude,
          'longitude': activity.place.longitude,

          'rating': activity.place.rating,
          'imageUrl': activity.place.imageUrl,
        };
      }).toList();

      plannedDays.add({'dayNumber': dayIndex + 1, 'activities': activityData});

      if (activities.isNotEmpty) {
        final preview = activities.first.place;

        previewPlaces.add({
          'placeName': preview.name,
          'imageUrl': preview.imageUrl,
        });
      }
    }

    await FirestoreService.saveTrip(
      trip,
      plannedDays: plannedDays,
      placesPreview: previewPlaces,
    );

    if (!mounted) return;
    planProvider.setSavingTrip(false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip saved successfully ❤️')));
  }

  Future<void> _toggleFavorite(PlaceSuggestion place) async {
    final trip = widget.trip;
    if (trip == null) return;

    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    favoritesProvider.toggleFavorite(place.id);

    final isFavorite = favoritesProvider.isFavorite(place.id);

    if (isFavorite) {
      await FirestoreService.saveFavoritePlace(
        placeId: place.id,
        name: place.name,
        address: place.address,
        city: trip.city,
        category: place.category,
        latitude: place.latitude,
        longitude: place.longitude,
        imageUrl: place.imageUrl,
        rating: place.rating,
      );
    } else {
      await FirestoreService.removeFavoritePlace(place.id);
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 430;
    final planProvider = Provider.of<PlanProvider>(context);
    final places = planProvider.places.cast<PlaceSuggestion>();
    final weatherDays = planProvider.weatherDays.cast<WeatherDay>();
    final trip = widget.trip;

    if (trip == null) {
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
            ),
          ),
          child: Center(
            child: Text(
              'Create a trip first to see your plan.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      );
    }

    final dailyBudget = trip.budget / trip.days;

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
          padding: EdgeInsets.fromLTRB(
            isMobile ? 14 : 20,
            16,
            isMobile ? 14 : 20,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroCard(trip, dailyBudget, places),

              const SizedBox(height: 30),

              Text(
                'Your daily trip plan',
                style: TextStyle(
                  fontSize: isMobile ? 21 : 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Each day is organized into morning, lunch, afternoon and evening activities.',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              if (planProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Builder(
                  builder: (context) {
                    _usedPlacesGlobally.clear();

                    return Column(
                      children: List.generate(trip.days, (index) {
                        final weather = index < weatherDays.length
                            ? weatherDays[index]
                            : null;

                        final activities = _activitiesForDay(
                          index,
                          trip,
                          places,
                        );

                        return _dayPlanCard(
                          dayNumber: index + 1,
                          weather: weather,
                          activities: activities,
                          dailyBudget: dailyBudget,
                        );
                      }),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard(
    Trip trip,
    double dailyBudget,
    List<PlaceSuggestion> places,
  ) {
    final cityName = _displayCityName(trip, places);
    final isMobile = MediaQuery.of(context).size.width < 430;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 26 : 34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF6D5DFF), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D5DFF).withValues(alpha: 0.35),
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
                width: isMobile ? 48 : 58,
                height: isMobile ? 48 : 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                ),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: isMobile ? 25 : 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip to $cityName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 23 : 30,
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

          SizedBox(height: isMobile ? 20 : 28),

          if (isMobile) ...[
            _heroInfo(
              icon: Icons.calendar_month,
              title: 'Duration',
              value: '${trip.days} Days',
            ),
            const SizedBox(height: 12),
            _heroInfo(
              icon: Icons.favorite,
              title: 'Interests',
              value: trip.interests.join(' • '),
            ),
          ] else
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
              color: _budgetColor(dailyBudget).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '€${trip.budget.toStringAsFixed(0)} Budget • €${dailyBudget.round()} planned per day',
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

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: Provider.of<PlanProvider>(context).isSavingTrip
                  ? null
                  : _saveTripToFirestore,
              icon: const Icon(Icons.bookmark_add),
              label: Text(
                Provider.of<PlanProvider>(context).isSavingTrip
                    ? 'Saving...'
                    : 'Save Trip',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6D5DFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 430;
    final dayTotal = activities.fold<double>(
      0,
      (sum, activity) => activity.place.includeInDayTotal
          ? sum + activity.place.estimatedCost
          : sum,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 40 : 46,
                height: isMobile ? 40 : 46,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
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
                      style: TextStyle(
                        fontSize: isMobile ? 17 : 19,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    if (weather != null)
                      Text(
                        '${_weatherIcon(weather.weatherCode)} ${weather.maxTemp.round()}° / ${weather.minTemp.round()}° • Rain ${weather.rainProbability}%',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimated daily cost: €${dayTotal.round()}',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 9 : 12,
                  vertical: isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: _budgetColor(dailyBudget).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _budgetStyle(dailyBudget),
                  style: TextStyle(
                    color: _budgetColor(dailyBudget),
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
          _costSummaryCard(
            breakdown: _dayCostBreakdown(activities),
            total: dayTotal,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Text(
              'No places found for this day.',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
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

  Widget _costSummaryCard({
    required Map<String, double> breakdown,
    required double total,
    required bool isDark,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 430;
    final entries = breakdown.entries.toList()
      ..sort((a, b) {
        if (a.value == b.value) return a.key.compareTo(b.key);
        return b.value.compareTo(a.value);
      });

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFDDD6FE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF8B5CF6),
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'Cost summary',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'No activities with cost data found for this day.',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            )
          else
            Column(
              children: entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '€${entry.value.round()}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily total',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '€${total.round()}',
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Daily total includes activities, attractions and food. Shopping is optional and not included.',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 10.5 : 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeMiniCard(PlaceSuggestion place, String timeLabel) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(place.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 430;
    final costLabel = place.category == 'Shopping'
        ? 'Optional shopping budget'
        : 'Estimated cost';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: isMobile ? 340 : 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
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
                      Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
                      Colors.black.withValues(alpha: isDark ? 0.82 : 0.72),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 16,
              right: 16,
              child: InkWell(
                onTap: () => _toggleFavorite(place),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.38),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFFF4D6D) : Colors.white,
                  ),
                ),
              ),
            ),

            Positioned(
              left: isMobile ? 14 : 18,
              right: isMobile ? 14 : 18,
              bottom: isMobile ? 14 : 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.22 : 0.18,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 19 : 22,
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

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '$costLabel: €${place.estimatedCost.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Source: ${place.costSource}',
                    maxLines: isMobile ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  if (place.priceLevel != null)
                    Text(
                      'Google price level: ${_readablePriceLevel(place.priceLevel!)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),

                  if (place.userRatingCount != null)
                    Text(
                      'Based on ${place.userRatingCount} reviews',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
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
                    label: Text(
                      isMobile ? 'Maps' : 'Open in Maps',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      backgroundColor: Colors.white.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 180,
      width: double.infinity,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF),
      child: Icon(
        _interestIcon(category),
        color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF4338CA),
        size: 46,
      ),
    );
  }
}
