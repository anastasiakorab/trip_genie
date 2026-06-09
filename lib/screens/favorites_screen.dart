import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firestore_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _openInMaps(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupByCity(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in docs) {
      final data = doc.data();
      final city = (data['city'] ?? 'Other').toString().trim();
      final cityName = city.isEmpty ? 'Other' : city;

      grouped.putIfAbsent(cityName, () => []);
      grouped[cityName]!.add(doc);
    }

    return grouped;
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  bool _isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 390;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = _isMobile(context);

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
            isMobile ? 14 : 22,
            isMobile ? 16 : 22,
            isMobile ? 14 : 22,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              SizedBox(height: isMobile ? 18 : 24),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.favoritePlacesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyState(context);
                  }

                  final groupedPlaces = _groupByCity(snapshot.data!.docs);

                  return Column(
                    children: groupedPlaces.entries.map((entry) {
                      return _cityDropdown(
                        context: context,
                        city: entry.key,
                        places: entry.value,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final isMobile = _isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 26 : 34),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6D5DFF),
            Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D5DFF).withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            color: Colors.white,
            size: isMobile ? 34 : 44,
          ),
          SizedBox(width: isMobile ? 12 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorite Places',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 25 : 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Places saved from your AI trip plans.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityDropdown({
    required BuildContext context,
    required String city,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> places,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = _isMobile(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 18,
            vertical: isMobile ? 5 : 8,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            isMobile ? 10 : 14,
            0,
            isMobile ? 10 : 14,
            isMobile ? 12 : 16,
          ),
          leading: Container(
            width: isMobile ? 38 : 42,
            height: isMobile ? 38 : 42,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF6D5DFF),
            ),
          ),
          title: Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 18 : 21,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          subtitle: Text(
            '${places.length} saved places',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 12 : 14,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          iconColor: const Color(0xFF6D5DFF),
          collapsedIconColor: const Color(0xFF6D5DFF),
          children: places.map((doc) {
            final data = doc.data();

            return _favoriteCard(
              context: context,
              placeId: data['placeId'] ?? doc.id,
              name: data['name'] ?? 'Favorite place',
              address: data['address'] ?? '',
              category: data['category'] ?? 'Place',
              imageUrl: data['imageUrl'],
              rating: (data['rating'] as num?)?.toDouble(),
              latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
              longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _favoriteCard({
    required BuildContext context,
    required String placeId,
    required String name,
    required String address,
    required String category,
    required String? imageUrl,
    required double? rating,
    required double latitude,
    required double longitude,
  }) {
    final isMobile = _isMobile(context);
    final isSmall = _isSmallMobile(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: isSmall ? 230 : isMobile ? 242 : 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _fallback(category);
                      },
                    )
                  : _fallback(category),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.80),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: InkWell(
                onTap: () async {
                  await FirestoreService.removeFavoritePlace(placeId);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from favorites')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: isMobile ? 42 : 46,
                  height: isMobile ? 42 : 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF4D6D),
                  ),
                ),
              ),
            ),
            Positioned(
              left: isMobile ? 16 : 20,
              right: isMobile ? 16 : 20,
              bottom: isMobile ? 14 : 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _categoryChip(context, category),
                  SizedBox(height: isMobile ? 8 : 10),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 21 : 25,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: isMobile ? 5 : 7),
                  if (rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: isMobile ? 5 : 7),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isMobile ? 9 : 12),
                  SizedBox(
                    height: isMobile ? 38 : 42,
                    child: OutlinedButton.icon(
                      onPressed: latitude == 0 && longitude == 0
                          ? null
                          : () => _openInMaps(latitude, longitude),
                      icon: const Icon(Icons.map_outlined, size: 17),
                      label: Text(
                        isMobile ? 'Maps' : 'Open in Maps',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white54,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(BuildContext context, String category) {
    final isMobile = _isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 11 : 13,
        vertical: isMobile ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: isMobile ? 11 : 12,
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = _isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 30),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(isMobile ? 26 : 32),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: isMobile ? 58 : 70,
            color: const Color(0xFF6D5DFF),
          ),
          const SizedBox(height: 18),
          Text(
            'No favorites yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 22 : 25,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save places from your generated trips and they will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(String category) {
    return Container(
      color: const Color(0xFFEDE9FE),
      child: Center(
        child: Icon(
          _iconForCategory(category),
          color: const Color(0xFF6D5DFF),
          size: 64,
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Museums':
        return Icons.museum;
      case 'Food':
        return Icons.restaurant;
      case 'Nature':
        return Icons.park;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Nightlife':
        return Icons.nightlife;
      case 'Concerts':
        return Icons.music_note;
      case 'Sports':
        return Icons.sports_soccer;
      case 'History':
        return Icons.account_balance;
      case 'Art':
        return Icons.palette;
      case 'Beaches':
        return Icons.beach_access;
      case 'Adventure':
        return Icons.hiking;
      case 'Family':
        return Icons.family_restroom;
      default:
        return Icons.place;
    }
  }
}
