import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:trip_genie/providers/auth_form_provider.dart';
import 'package:trip_genie/providers/web_camera_provider.dart';

import 'firebase_options.dart';

import 'providers/app_state_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/create_trip_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/plan_provider.dart';

import 'screens/home_screen.dart';
import 'screens/create_trip_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> setupNotifications() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  final token = await messaging.getToken();
  debugPrint("FCM TOKEN: $token");

  final user = FirebaseAuth.instance.currentUser;

  if (user != null && token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Push received');
    debugPrint(message.notification?.title);
    debugPrint(message.notification?.body);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: ".env",
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await setupNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CreateTripProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => AuthFormProvider()),
        ChangeNotifierProvider(create: (_) => WebCameraProvider()),
      ],
      child: const TripGenieApp(),
    ),
  );
}

class TripGenieApp extends StatelessWidget {
  const TripGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TripGenie',
      themeMode: appState.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D5DFF),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D5DFF),
          brightness: Brightness.dark,
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
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  Future<void> _logout(BuildContext context, AppStateProvider appState) async {
    appState.resetOnLogout();
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = appState.themeMode == ThemeMode.dark;

    return Scaffold(
      body: IndexedStack(
        index: appState.selectedIndex,
        children: [
          HomeScreen(onCreateTripPressed: appState.goToCreateTrip),
          CreateTripScreen(onTripCreated: appState.createTrip),
          PlanScreen(trip: appState.selectedTrip),
          const FavoritesScreen(),
          SettingsScreen(onLogout: () => _logout(context, appState)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.selectedIndex,
        onDestinationSelected: appState.changeTab,
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        indicatorColor: isDark
            ? const Color(0xFF312E81)
            : const Color(0xFFE0E7FF),
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
