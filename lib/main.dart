

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'models/trip.dart';

import 'screens/home_screen.dart';
import 'screens/create_trip_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

import 'services/auth_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> setupNotifications() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await messaging.getToken();

  debugPrint("FCM TOKEN: $token");

  final user = FirebaseAuth.instance.currentUser;

  if (user != null && token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  debugPrint('Push received (foreground)');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
});
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupNotifications();

  runApp(const TripGenieApp());
}

class TripGenieApp extends StatelessWidget {
  const TripGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TripGenie',
          themeMode: currentTheme,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6D5DFF),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8FAFC),
              elevation: 0,
              centerTitle: true,
              foregroundColor: Color(0xFF0F172A),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6D5DFF),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              elevation: 0,
              centerTitle: true,
              foregroundColor: Colors.white,
            ),
          ),
          home: StreamBuilder<User?>(
            stream: AuthService.authState,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                return const MainNavigationScreen();
              }

              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static int _lastSelectedIndex = 0;
  static Trip? _lastSelectedTrip;

  late int _selectedIndex = _lastSelectedIndex;
  Trip? _selectedTrip = _lastSelectedTrip;

  void _goToCreate() {
    setState(() {
      _selectedIndex = 1;
      _lastSelectedIndex = 1;
    });
  }

  Future<void> _saveTrip(Trip trip) async {
    setState(() {
      _selectedTrip = trip;
      _lastSelectedTrip = trip;
      _selectedIndex = 2;
      _lastSelectedIndex = 2;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _lastSelectedIndex = index;
    });
  }

  Future<void> _logout() async {
    _lastSelectedIndex = 0;
    _lastSelectedTrip = null;

    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(onCreateTripPressed: _goToCreate),
          CreateTripScreen(onTripCreated: _saveTrip),
          PlanScreen(trip: _selectedTrip),
          const FavoritesScreen(),
          SettingsScreen(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        indicatorColor:
            isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF),
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