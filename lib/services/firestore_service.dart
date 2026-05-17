import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get uid => _auth.currentUser?.uid;

  static Future<void> createUserProfile({
    required String name,
    required String email,
  }) async {
    final userId = uid;
    if (userId == null) return;

    await _db.collection('users').doc(userId).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _tripDocumentId(Trip trip) {
    final city = trip.city
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final start =
        '${trip.startDate.year}-${trip.startDate.month.toString().padLeft(2, '0')}-${trip.startDate.day.toString().padLeft(2, '0')}';

    final end =
        '${trip.endDate.year}-${trip.endDate.month.toString().padLeft(2, '0')}-${trip.endDate.day.toString().padLeft(2, '0')}';

    return '${city}_${start}_$end';
  }

  static Future<void> saveTrip(Trip trip) async {
    final userId = uid;
    if (userId == null) return;

    final tripId = _tripDocumentId(trip);

    await _db
        .collection('users')
        .doc(userId)
        .collection('savedTrips')
        .doc(tripId)
        .set({
      'tripId': tripId,
      'city': trip.city,
      'startDate': Timestamp.fromDate(trip.startDate),
      'endDate': Timestamp.fromDate(trip.endDate),
      'budget': trip.budget,
      'interests': trip.interests,
      'latitude': trip.latitude,
      'longitude': trip.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> savedTripsStream() {
    final userId = uid;

    return _db
        .collection('users')
        .doc(userId)
        .collection('savedTrips')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  static Future<void> saveFavoritePlace({
    required String placeId,
    required String name,
    required String address,
    required String category,
    required String city,
    required double latitude,
    required double longitude,
    String? imageUrl,
    double? rating,
  }) async {
    final userId = uid;
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('favoritePlaces')
        .doc(placeId)
        .set({
      'placeId': placeId,
      'name': name,
      'address': address,
      'city': city,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removeFavoritePlace(String placeId) async {
    final userId = uid;
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('favoritePlaces')
        .doc(placeId)
        .delete();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> favoritePlacesStream() {
    final userId = uid;

    return _db
        .collection('users')
        .doc(userId)
        .collection('favoritePlaces')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}