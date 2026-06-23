import 'package:flutter/foundation.dart';
import '../../data/local/storage.dart';
import '../../data/models/track.dart';

/// 收藏状态管理
class FavoritesProvider extends ChangeNotifier {
  List<Track> _favoriteTracks = [];

  List<Track> get favoriteTracks => _favoriteTracks;

  Future<void> loadFavorites() async {
    final storage = await LocalStorage.instance;
    _favoriteTracks = await storage.getFavoriteTracks();
    notifyListeners();
  }

  bool isFavorite(int trackId) {
    return _favoriteTracks.any((t) => t.id == trackId);
  }

  Future<void> toggleFavorite(Track track) async {
    final storage = await LocalStorage.instance;
    if (isFavorite(track.id)) {
      _favoriteTracks.removeWhere((t) => t.id == track.id);
      await storage.removeFavorite(track.id);
    } else {
      _favoriteTracks.insert(0, track);
      await storage.addFavorite(track);
    }
    notifyListeners();
  }
}
