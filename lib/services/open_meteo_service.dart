

import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenMeteoService {
  static Future<List<dynamic>> searchCities(String query) async {
    if (query.trim().length < 2) return [];

    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeComponent(query)}'
      '&count=8'
      '&language=en'
      '&format=json',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    return data['results'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>?> getWeather({
    required double latitude,
    required double longitude,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code'
      '&start_date=$startDate'
      '&end_date=$endDate'
      '&timezone=auto',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) return null;

    return jsonDecode(response.body);
  }
}