import 'package:flutter/material.dart';

import 'models/trip.dart';

import 'screens/home_screen.dart';
import 'screens/create_trip_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';

import 'screens/login_screen.dart';

import 'services/fake_auth_service.dart';

void main() {
  runApp(const TripGenieApp());
}

class TripGenieApp extends StatefulWidget {
  const TripGenieApp({super.key});

  @override
  State<TripGenieApp> createState() => _TripGenieAppState();
}

class _TripGenieAppState extends State<TripGenieApp> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TripGenie',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D5DFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          centerTitle: true,
          foregroundColor: Color(0xFF0F172A),
        ),
      ),

      home: FakeAuthService.isLoggedIn
          ? MainNavigationScreen(onLogout: _refresh)
          : LoginScreen(
              onLoginSuccess: _refresh,
            ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  Trip? _selectedTrip;

  void _goToCreate() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _saveTrip(Trip trip) {
    setState(() {
      _selectedTrip = trip;
      _selectedIndex = 2;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    FakeAuthService.logout();

    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onCreateTripPressed: _goToCreate,
      ),

      CreateTripScreen(
        onTripCreated: _saveTrip,
      ),

      PlanScreen(
        trip: _selectedTrip,
      ),

      const FavoritesScreen(),

      SettingsScreen(
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,

        onDestinationSelected: _onItemTapped,

        backgroundColor: Colors.white,

        indicatorColor: const Color(0xFFE0E7FF),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt),
            label: 'Create',
          ),

          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Plan',
          ),

          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}