import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onCreateTripPressed;

  const HomeScreen({
    super.key,
    required this.onCreateTripPressed,
  });

  @override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final destinations = [
    _Destination.asset(
      city: 'Ohrid',
      country: 'Macedonia',
      label: 'Church of St. John at Kaneo',
      imagePath: 'assets/images/kaneo.jpg',
    ),
    _Destination.asset(
      city: 'Skopje',
      country: 'Macedonia',
      label: 'Stone Bridge & Macedonia Square',
      imagePath: 'assets/images/skopje_alexander.jpg',
    ),
    _Destination.network(
      city: 'Paris',
      country: 'France',
      label: 'Eiffel Tower',
      imageUrl:
          'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=1200&q=80',
    ),
    _Destination.network(
      city: 'Barcelona',
      country: 'Spain',
      label: 'Sagrada Família',
      imageUrl:
          'https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&w=1200&q=80',
    ),
    _Destination.network(
      city: 'New York',
      country: 'USA',
      label: 'Manhattan Skyline',
      imageUrl:
          'https://images.unsplash.com/photo-1534430480872-3498386e7856?auto=format&fit=crop&w=1200&q=80',
    ),
    _Destination.network(
      city: 'Tokyo',
      country: 'Japan',
      label: 'City Lights',
      imageUrl:
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',
    ),
    _Destination.network(
      city: 'Rome',
      country: 'Italy',
      label: 'Colosseum',
      imageUrl:
          'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',
    ),
    _Destination.network(
      city: 'Dubai',
      country: 'UAE',
      label: 'Modern Skyline',
      imageUrl:
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1200&q=80',
    ),
    _Destination.network(
      city: 'London',
      country: 'United Kingdom',
      label: 'Big Ben & London Eye',
      imageUrl:
          'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=1200&q=80',
    ),
    _Destination.network(
      city: 'Singapore',
      country: 'Singapore',
      label: 'Marina Bay Sands',
      imageUrl:
          'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(isDark),
            const SizedBox(height: 24),
            _hero(),
            const SizedBox(height: 28),
            _sectionTitle(isDark),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: destinations.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 310,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                return _destinationCard(destinations[index]);
              },
            ),
            const SizedBox(height: 28),
            _whyTripGenie(),
            const SizedBox(height: 22),
            _footerSection(isDark),
          ],
        ),
      ),
    ),
  );
}
Widget _header(bool isDark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      color: isDark
          ? const Color(0xFF1E293B).withOpacity(0.92)
          : Colors.white.withOpacity(0.88),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
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
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.flight_takeoff_rounded,
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
                'TripGenie ✈️',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Your smart travel companion',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const Icon(
          Icons.auto_awesome,
          color: Color(0xFF6D5DFF),
          size: 30,
        ),
      ],
    ),
  );
}

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF312E81),
            Color(0xFF6D5DFF),
            Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D5DFF).withOpacity(0.34),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.travel_explore,
                  color: Colors.white,
                  size: 54,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Build your perfect\ntrip in seconds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pick a destination, choose your interests, and get a personalized itinerary with places, weather and budget-friendly planning.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 245,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: onCreateTripPressed,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text(
                      'Start Planning',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6D5DFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 4,
            child: Container(
              height: 280,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.public,
                    color: Colors.white,
                    size: 92,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'AI itinerary builder',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real places • Live weather • Saved trips',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(bool isDark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark
          ? const Color(0xFF1E293B).withOpacity(0.92)
          : Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular destinations',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a city inspiration or create your own custom trip.',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

  Widget _destinationCard(_Destination destination) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: destination.isAsset
                ? Image.asset(
                    destination.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _imageFallback(destination.city);
                    },
                  )
                : Image.network(
                    destination.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _imageFallback(destination.city);
                    },
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.06),
                    Colors.black.withOpacity(0.82),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFC4B5FD),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      destination.country,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whyTripGenie() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF312E81),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why TripGenie stands out ✨',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Everything you need for a smarter trip is organized in one clean planner.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.map_rounded,
                  title: 'Real',
                  subtitle: 'Places',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard(
                  icon: Icons.auto_awesome,
                  title: 'AI',
                  subtitle: 'Planning',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard(
                  icon: Icons.cloud_rounded,
                  title: 'Live',
                  subtitle: 'Weather',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerSection(bool isDark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: isDark
          ? const Color(0xFF1E293B).withOpacity(0.92)
          : Colors.white.withOpacity(0.90),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
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
          child: const Icon(Icons.route_rounded, color: Colors.white),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to create your next route?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Turn your destination into a complete day-by-day travel plan.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onCreateTripPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Create Trip',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D5DFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22),
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

  Widget _imageFallback(String title) {
    return Container(
      color: const Color(0xFFE0E7FF),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4338CA),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class _Destination {
  final String city;
  final String country;
  final String label;
  final String imageUrl;
  final String imagePath;
  final bool isAsset;

  const _Destination.network({
    required this.city,
    required this.country,
    required this.label,
    required this.imageUrl,
  })  : imagePath = '',
        isAsset = false;

  const _Destination.asset({
    required this.city,
    required this.country,
    required this.label,
    required this.imagePath,
  })  : imageUrl = '',
        isAsset = true;
}