import 'package:flutter/material.dart';

class CreateTripProvider extends ChangeNotifier {
  DateTime? startDate;
  DateTime? endDate;

  double? selectedLatitude;
  double? selectedLongitude;

  bool gettingCurrentLocation = false;
  bool isSearchingLocation = false;

  final Set<String> selectedInterests = {'Museums'};

  void setStartDate(DateTime date) {
    startDate = date;

    if (endDate != null && endDate!.isBefore(date)) {
      endDate = date;
    }

    notifyListeners();
  }

  void setEndDate(DateTime date) {
    endDate = date;
    notifyListeners();
  }

  void setSelectedLocation({
    required double latitude,
    required double longitude,
  }) {
    selectedLatitude = latitude;
    selectedLongitude = longitude;
    notifyListeners();
  }

  void clearSelectedCoordinates() {
    selectedLatitude = null;
    selectedLongitude = null;
    notifyListeners();
  }

  void setGettingCurrentLocation(bool value) {
    gettingCurrentLocation = value;
    notifyListeners();
  }

  void setSearchingLocation(bool value) {
    isSearchingLocation = value;
    notifyListeners();
  }

  void toggleInterest(String interest) {
    if (selectedInterests.contains(interest)) {
      if (selectedInterests.length > 1) {
        selectedInterests.remove(interest);
      }
    } else {
      selectedInterests.add(interest);
    }

    notifyListeners();
  }

  void resetCreateTrip() {
    startDate = null;
    endDate = null;
    selectedLatitude = null;
    selectedLongitude = null;
    gettingCurrentLocation = false;
    isSearchingLocation = false;
    selectedInterests
      ..clear()
      ..add('Museums');

    notifyListeners();
  }
  List<dynamic> locationSuggestions = [];

void setLocationSuggestions(
  List<dynamic> suggestions,
) {
  locationSuggestions = suggestions;
  notifyListeners();
}
}
