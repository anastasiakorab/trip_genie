class Trip {
  final String city;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String interest;

  Trip({
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.interest,
  });

  int get days {
    return endDate.difference(startDate).inDays + 1;
  }
}