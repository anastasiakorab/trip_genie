import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TicketmasterService {
  static final String apiKey =
      dotenv.env['TICKETMASTER_API_KEY'] ?? '';

  static Future<double?> getEventPrice({
    required String keyword,
    required String city,
  }) async {
    try {
      final url = Uri.parse(
        'https://app.ticketmaster.com/discovery/v2/events.json'
        '?keyword=${Uri.encodeComponent(keyword)}'
        '&city=${Uri.encodeComponent(city)}'
        '&apikey=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      final events =
          data['_embedded']?['events'] as List<dynamic>?;

      if (events == null || events.isEmpty) {
        return null;
      }

      final firstEvent = events.first;

      final priceRanges =
          firstEvent['priceRanges'] as List<dynamic>?;

      if (priceRanges == null || priceRanges.isEmpty) {
        return null;
      }

      final minPrice =
          (priceRanges.first['min'] as num?)?.toDouble();

      return minPrice;
    } catch (_) {
      return null;
    }
  }
}