import 'dart:convert';
import 'package:http/http.dart' as http;

import 'google_places_service.dart';

class GoogleGeocodingService {
  static Future<String?> getPlaceNameFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$latitude,$longitude'
      '&key=$googleApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List<dynamic>? ?? [];

    if (results.isEmpty) {
      return null;
    }

    String? locality;
    String? postalTown;
    String? sublocality;
    String? neighborhood;
    String? adminLevel3;
    String? adminLevel2;
    String? adminLevel1;
    String? country;

    for (final result in results) {
      final components = result['address_components'] as List<dynamic>? ?? [];

      for (final component in components) {
        final types = component['types'] as List<dynamic>? ?? [];
        final name = component['long_name']?.toString();

        if (name == null || name.isEmpty) continue;

        if (types.contains('locality')) {
          locality ??= name;
        }

        if (types.contains('postal_town')) {
          postalTown ??= name;
        }

        if (types.contains('sublocality') ||
            types.contains('sublocality_level_1')) {
          sublocality ??= name;
        }

        if (types.contains('neighborhood')) {
          neighborhood ??= name;
        }

        if (types.contains('administrative_area_level_3')) {
          adminLevel3 ??= name;
        }

        if (types.contains('administrative_area_level_2')) {
          adminLevel2 ??= name;
        }

        if (types.contains('administrative_area_level_1')) {
          adminLevel1 ??= name;
        }

        if (types.contains('country')) {
          country ??= name;
        }
      }
    }

    final placeName =
        locality ??
        postalTown ??
        sublocality ??
        neighborhood ??
        adminLevel3 ??
        adminLevel2 ??
        adminLevel1;

    if (placeName == null || placeName.isEmpty) {
      return country;
    }

    if (country != null && country.isNotEmpty) {
      return '$placeName, $country';
    }

    return placeName;
  }
}