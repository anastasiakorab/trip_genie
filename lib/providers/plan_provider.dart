import 'package:flutter/material.dart';

class PlanProvider extends ChangeNotifier {
  bool isLoading = false;

  List<dynamic> places = [];
  List<dynamic> weatherDays = [];

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setPlaces(List<dynamic> value) {
    places = value;
    notifyListeners();
  }

  void setWeather(List<dynamic> value) {
    weatherDays = value;
    notifyListeners();
  }

  void clear() {
    places.clear();
    weatherDays.clear();

    notifyListeners();
  }
  bool isSavingTrip = false;

void setSavingTrip(bool value) {
  isSavingTrip = value;
  notifyListeners();
}
}