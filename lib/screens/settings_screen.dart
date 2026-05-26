import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'edit_profile_screen.dart';
import 'web_camera_screen.dart';
import 'favorites_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/profile_provider.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function() onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkModeEnabled = false;

  Uint8List? profileImageBytes;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final imageBase64 = doc.data()?['profileImageBase64'];

    if (imageBase64 != null && imageBase64.toString().isNotEmpty) {

      if (!mounted) return;
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).setProfileImage(base64Decode(imageBase64));
    }
  }

  Future<void> _pickImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                subtitle: const Text('Open webcam in Chrome'),
                onTap: () {
                  Navigator.pop(context, 'camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context, 'gallery');
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    Uint8List? bytes;

    if (source == 'camera') {
      bytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => const WebCameraScreen()),
      );

      if (!mounted) return;
    } else {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 45,
        maxWidth: 300,
        maxHeight: 300,
      );
      
      if (!mounted) return;


      if (picked == null) return;
      bytes = await picked.readAsBytes();
    }

    if (bytes == null) return;

    final base64Image = base64Encode(bytes);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'profileImageBase64': base64Image,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Provider.of<ProfileProvider>(context, listen: false).setProfileImage(bytes);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    final isDark = appState.themeMode == ThemeMode.dark;

    darkModeEnabled = isDark;

    final user = FirebaseAuth.instance.currentUser;

    final name = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'TripGenie User';

    final email = user?.email ?? '';

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    const Color(0xFF312E81),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEDE9FE),
                    const Color(0xFFFDF2F8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              _settingsHeader(),
              const SizedBox(height: 24),

              _profileCard(
                name: name,
                email: email,
                profileProvider: profileProvider,
              ),

              const SizedBox(height: 22),
              _settingsCard(),
              const SizedBox(height: 22),
              _logoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: darkModeEnabled
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings ⚙️',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: darkModeEnabled
                        ? Colors.white
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your TripGenie experience',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: darkModeEnabled
                        ? Colors.white70
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.tune_rounded,
            color: darkModeEnabled ? Colors.white70 : const Color(0xFF6D5DFF),
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _profileCard({
    required String name,
    required String email,
    required ProfileProvider profileProvider,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: profileProvider.isUploadingImage ? null : _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  child: ClipOval(
                    child: profileProvider.isUploadingImage
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : profileProvider.profileImageBytes != null
                        ? Image.memory(
                            profileProvider.profileImageBytes!,
                            fit: BoxFit.cover,
                            width: 96,
                            height: 96,
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 48,
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D5DFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) {});
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final profileProvider =
    Provider.of<ProfileProvider>(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: darkModeEnabled
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          _switchTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Trip reminders and travel updates',
            value: profileProvider.notificationsEnabled,
            onChanged: (value) {
              profileProvider.toggleNotifications(value);
            },
          ),
          _divider(),
          _switchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Switch to a darker TripGenie look',
            value: darkModeEnabled,
            onChanged: (value) {
              appState.toggleDarkMode(value);
            },
          ),
          _divider(),
          _infoTile(
            icon: Icons.favorite_border,
            title: 'Favorite Places',
            subtitle: 'Places saved from your trip plans',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: FavoritesScreen()),
                ),
              );
            },
          ),
          _divider(),
          _infoTile(
            icon: Icons.map_outlined,
            title: 'Saved Trips',
            subtitle: 'Your saved travel plans',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _SavedTripsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF6D5DFF),
      secondary: _tileIcon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: darkModeEnabled ? Colors.white : const Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: darkModeEnabled ? Colors.white70 : const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      leading: _tileIcon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: darkModeEnabled ? Colors.white : const Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: darkModeEnabled ? Colors.white70 : const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: darkModeEnabled ? Colors.white70 : Colors.grey,
      ),
    );
  }

  Widget _tileIcon(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: darkModeEnabled
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: darkModeEnabled ? Colors.white : const Color(0xFF6D5DFF),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Divider(
        height: 1,
        color: darkModeEnabled
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: widget.onLogout,
        icon: const Icon(Icons.logout),
        label: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _SavedTripsScreen extends StatelessWidget {
  const _SavedTripsScreen();

  Stream<QuerySnapshot<Map<String, dynamic>>> _savedTripsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedTrips')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}.${date.month}.${date.year}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E1B4B),
                      const Color(0xFF312E81),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFEDE9FE),
                      const Color(0xFFFDF2F8),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _savedTripsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No saved trips yet.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                );
              }

              final trips = snapshot.data!.docs;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _savedTripsHeader(context),
                    const SizedBox(height: 22),

                    ...trips.map((doc) {
                      final data = doc.data();

                      final city = data['city'] ?? 'Unknown city';
                      final budget = data['budget'] ?? 0;
                      final startDate = _formatDate(data['startDate']);
                      final endDate = _formatDate(data['endDate']);
                      final interests =
                          (data['interests'] as List?)?.join(' • ') ?? '';

                      final previewPlaces =
                          (data['placesPreview'] as List?) ?? [];

                      final previewNames = previewPlaces
                          .map((p) => p['placeName'] ?? '')
                          .where((name) => name.toString().isNotEmpty)
                          .take(3)
                          .join(' • ');

                      return InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _SavedTripDetailsScreen(tripData: data),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6D5DFF),
                                          Color(0xFFEC4899),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.flight_takeoff,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          city.toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$startDate → $endDate',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF64748B),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$$budget',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),

                              if (interests.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  interests,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],

                              if (previewPlaces.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 70,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: previewPlaces.length > 3
                                        ? 3
                                        : previewPlaces.length,
                                    itemBuilder: (_, index) {
                                      final place = previewPlaces[index];

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Stack(
                                            children: [
                                              SizedBox(
                                                width: 90,
                                                height: 70,
                                                child: place['imageUrl'] != null
                                                    ? Image.network(
                                                        place['imageUrl'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, _, _) {
                                                              return Container(
                                                                color:
                                                                    const Color(
                                                                      0xFF6D5DFF,
                                                                    ),
                                                                child: const Icon(
                                                                  Icons.place,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              );
                                                            },
                                                      )
                                                    : Container(
                                                        color: const Color(
                                                          0xFF6D5DFF,
                                                        ),
                                                        child: const Icon(
                                                          Icons.place,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  color: Colors.black54,
                                                  child: Text(
                                                    place['placeName'] ?? '',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (previewNames.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    previewNames,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],

                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 18,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tap to view full plan',
                                    style: TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _savedTripsHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Saved Trips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedTripDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const _SavedTripDetailsScreen({required this.tripData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final city = tripData['city'] ?? 'Saved Trip';
    final plannedDays = (tripData['plannedDays'] as List?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E1B4B),
                      const Color(0xFF312E81),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFEDE9FE),
                      const Color(0xFFFDF2F8),
                    ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        city.toString(),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (plannedDays.isEmpty)
                  Text(
                    'This saved trip has no saved places yet.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...plannedDays.map<Widget>((day) {
                    final activities = (day['activities'] as List?) ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day ${day['dayNumber']}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...activities.map<Widget>((activity) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: activity['imageUrl'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        activity['imageUrl'],
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.place,
                                      color: Color(0xFF8B5CF6),
                                    ),
                              title: Text(
                                (activity['placeName'] ?? 'Place').toString(),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                (activity['timeLabel'] ?? '').toString(),
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
