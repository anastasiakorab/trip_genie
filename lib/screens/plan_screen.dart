import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/trip.dart';

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
  bool _isLoadingWeather = false;
  List<WeatherDay> _weatherDays = [];

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void didUpdateWidget(covariant PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.trip != widget.trip) {
      _loadWeather();
    }
  }

  String _formatApiDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatDisplayDate(String apiDate) {
    final parts = apiDate.split('-');

    if (parts.length != 3) return apiDate;

    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  Future<void> _loadWeather() async {
    final trip = widget.trip;

    if (trip == null || trip.latitude == null || trip.longitude == null) {
      return;
    }

    setState(() {
      _isLoadingWeather = true;
      _weatherDays = [];
    });

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

        final weather = List.generate(dates.length, (index) {
          return WeatherDay(
            date: dates[index].toString(),
            maxTemp: (maxTemps[index] as num).toDouble(),
            minTemp: (minTemps[index] as num).toDouble(),
            rainProbability: (rain[index] as num?)?.toInt() ?? 0,
            weatherCode: (codes[index] as num).toInt(),
          );
        });

        setState(() {
          _weatherDays = weather;
        });
      }
    } catch (e) {
      setState(() {
        _weatherDays = [];
      });
    } finally {
      setState(() {
        _isLoadingWeather = false;
      });
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
            Text(
              trip.city,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${trip.days} days • ${trip.interest} • \$${trip.budget.toStringAsFixed(0)} budget',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 22),

            _summaryCard(trip),

            const SizedBox(height: 26),

            const Text(
              'Weather forecast',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 14),

            if (_isLoadingWeather)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_weatherDays.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Weather forecast is not available for these dates yet.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Column(
                children: _weatherDays.map((day) {
                  return _weatherCard(day);
                }).toList(),
              ),

            const SizedBox(height: 28),

            const Text(
              'Daily plan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 14),

            ...List.generate(trip.days, (index) {
              return _dayPlanCard(index + 1, trip.interest);
            }),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              Icons.calendar_month,
              'Days',
              '${trip.days}',
            ),
          ),
          Expanded(
            child: _summaryItem(
              Icons.favorite,
              'Interest',
              trip.interest,
            ),
          ),
          Expanded(
            child: _summaryItem(
              Icons.attach_money,
              'Budget',
              '\$${trip.budget.toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6D5DFF),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _weatherCard(WeatherDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(
            _weatherIcon(day.weatherCode),
            style: const TextStyle(fontSize: 34),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDisplayDate(day.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rain chance: ${day.rainProbability}%',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${day.maxTemp.round()}° / ${day.minTemp.round()}°',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayPlanCard(int dayNumber, String interest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore places related to $interest and enjoy your trip.',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
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