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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

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
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(isDark, isMobile),
              SizedBox(height: isMobile ? 18 : 24),
              _hero(isMobile),
              SizedBox(height: isMobile ? 22 : 28),
              _sectionTitle(isDark, isMobile),
              SizedBox(height: isMobile ? 14 : 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: destinations.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isMobile ? 210 : 310,
                  mainAxisSpacing: isMobile ? 12 : 18,
                  crossAxisSpacing: isMobile ? 12 : 18,
                  childAspectRatio: isMobile ? 0.92 : 1.05,
                ),
                itemBuilder: (context, index) {
                  return _destinationCard(destinations[index], isMobile);
                },
              ),
              SizedBox(height: isMobile ? 22 : 28),
              _whyTripGenie(isMobile),
              SizedBox(height: isMobile ? 18 : 22),
              _footerSection(isDark, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.88),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 48 : 58,
            height: isMobile ? 48 : 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            ),
            child: Icon(
              Icons.flight_takeoff_rounded,
              color: Colors.white,
              size: isMobile ? 26 : 30,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TripGenie ✈️',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 34,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your smart travel companion',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            const Icon(
              Icons.auto_awesome,
              color: Color(0xFF6D5DFF),
              size: 30,
            ),
        ],
      ),
    );
  }

  Widget _hero(bool isMobile) {
    final leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.travel_explore,
          color: Colors.white,
          size: isMobile ? 42 : 54,
        ),
        SizedBox(height: isMobile ? 16 : 22),
        Text(
          'Build your perfect trip in seconds',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 31 : 44,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Text(
          'Pick a destination, choose your interests, and get a personalized itinerary with places, weather and budget-friendly planning.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isMobile ? 14 : 16,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isMobile ? 20 : 28),
        SizedBox(
          width: isMobile ? double.infinity : 245,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onCreateTripPressed,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'Start Planning',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
    );

    final rightContent = Container(
      width: double.infinity,
      height: isMobile ? 170 : 280,
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public,
            color: Colors.white,
            size: isMobile ? 54 : 92,
          ),
          SizedBox(height: isMobile ? 12 : 18),
          Text(
            'AI itinerary builder',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'Real places • Live weather • Saved trips',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 28 : 36),
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF6D5DFF), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D5DFF).withValues(alpha: 0.34),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftContent,
                const SizedBox(height: 22),
                rightContent,
              ],
            )
          : Row(
              children: [
                Expanded(flex: 6, child: leftContent),
                const SizedBox(width: 28),
                Expanded(flex: 4, child: rightContent),
              ],
            ),
    );
  }

  Widget _sectionTitle(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular destinations',
            style: TextStyle(
              fontSize: isMobile ? 23 : 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a city inspiration or create your own custom trip.',
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _destinationCard(_Destination destination, bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
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
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: isMobile ? 14 : 18,
            right: isMobile ? 14 : 18,
            bottom: isMobile ? 14 : 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 12 : 13,
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
                    Expanded(
                      child: Text(
                        destination.country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
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

  Widget _whyTripGenie(bool isMobile) {
    final cards = [
      _statCard(icon: Icons.map_rounded, title: 'Real', subtitle: 'Places'),
      _statCard(icon: Icons.auto_awesome, title: 'AI', subtitle: 'Planning'),
      _statCard(icon: Icons.cloud_rounded, title: 'Live', subtitle: 'Weather'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 26 : 30),
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why TripGenie stands out ✨',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 23 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Everything you need for a smarter trip is organized in one clean planner.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 13 : 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          if (isMobile)
            Column(
              children: cards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card,
                    ),
                  )
                  .toList(),
            )
          else
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
                const SizedBox(width: 14),
                Expanded(child: cards[2]),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerSection(bool isDark, bool isMobile) {
    final icon = Container(
      width: isMobile ? 50 : 58,
      height: isMobile ? 50 : 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5DFF), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      ),
      child: const Icon(Icons.route_rounded, color: Colors.white),
    );

    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to create your next route?',
          style: TextStyle(
            fontSize: isMobile ? 20 : 22,
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
    );

    final button = SizedBox(
      width: isMobile ? double.infinity : null,
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
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 26),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(isMobile ? 26 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 16),
                textContent,
                const SizedBox(height: 18),
                button,
              ],
            )
          : Row(
              children: [
                icon,
                const SizedBox(width: 18),
                Expanded(child: textContent),
                const SizedBox(width: 18),
                button,
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
