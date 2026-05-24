import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favorites = {};

  Set<String> get favorites => _favorites;

  bool isFavorite(String id) {
    return _favorites.contains(id);
  }

  void toggleFavorite(String id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }

    notifyListeners();
  }
}