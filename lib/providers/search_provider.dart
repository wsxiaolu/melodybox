import 'package:flutter/foundation.dart';
import '../../data/api/music_api.dart';
import '../../data/models/track.dart';

/// 搜索状态管理
class SearchProvider extends ChangeNotifier {
  final MusicApi _api = MusicApi();

  List<Track> _results = [];
  bool _isSearching = false;
  String _query = '';
  String? _error;
  int _totalResults = 0;

  List<Track> get results => _results;
  bool get isSearching => _isSearching;
  String get query => _query;
  String? get error => _error;
  int get totalResults => _totalResults;
  bool get hasMore => _results.length < _totalResults;

  /// 执行搜索
  Future<void> search(String query) async {
    _query = query.trim();
    if (_query.isEmpty) {
      _results = [];
      _totalResults = 0;
      _error = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    final result = await _api.searchTracks(query: _query);
    _results = (result['tracks'] as List)
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
    _totalResults = result['total'] as int;
    _error = result['error'] as String?;
    _isSearching = false;
    notifyListeners();
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isSearching || !hasMore) return;

    _isSearching = true;
    notifyListeners();

    final result = await _api.searchTracks(
      query: _query,
      offset: _results.length,
    );
    final more = (result['tracks'] as List)
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
    _results.addAll(more);
    _isSearching = false;
    notifyListeners();
  }

  /// 清空搜索
  void clear() {
    _results = [];
    _query = '';
    _isSearching = false;
    _error = null;
    _totalResults = 0;
    notifyListeners();
  }
}
