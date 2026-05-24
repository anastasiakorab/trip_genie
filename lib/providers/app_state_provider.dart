import 'package:flutter/material.dart';
import '../models/trip.dart';

class AppStateProvider extends ChangeNotifier {
  int selectedIndex = 0;
  Trip? selectedTrip;
  ThemeMode themeMode = ThemeMode.light;

  void changeTab(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void goToCreateTrip() {
    selectedIndex = 1;
    notifyListeners();
  }

  void createTrip(Trip trip) {
    selectedTrip = trip;
    selectedIndex = 2;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    themeMode =
        value ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();
  }

  void resetOnLogout() {
    selectedIndex = 0;
    selectedTrip = null;

    notifyListeners();
  }
}