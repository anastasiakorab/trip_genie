import 'package:flutter/material.dart';

class CreateTripProvider extends ChangeNotifier {
  DateTime? startDate;
  DateTime? endDate;

  double? selectedLatitude;
  double? selectedLongitude;

  bool gettingCurrentLocation = false;
  bool isSearchingLocation = false;

  List<dynamic> locationSuggestions = [];

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

  void setLocationSuggestions(List<dynamic> suggestions) {
    locationSuggestions = suggestions;
    notifyListeners();
  }

  void clearLocationSuggestions() {
    locationSuggestions.clear();
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
    budget = 500;
    locationSuggestions.clear();

    selectedInterests
      ..clear()
      ..add('Museums');

    notifyListeners();
  }
  bool showLocationMap = false;

void setShowLocationMap(bool value) {
  showLocationMap = value;
  notifyListeners();
}
double budget = 500;

void setBudget(double value) {
  budget = value;
  notifyListeners();
}
}