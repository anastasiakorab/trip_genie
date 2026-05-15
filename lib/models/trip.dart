class Trip {
  final String city;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final List<String> interests;
  final double? latitude;
  final double? longitude;

  Trip({
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.budget,
    String? interest,
    List<String>? interests,
    this.latitude,
    this.longitude,
  }) : interests = interests ?? (interest != null ? [interest] : ['Museums']);

  int get days {
    return endDate.difference(startDate).inDays + 1;
  }

  String get interest {
    return interests.join(', ');
  }
}