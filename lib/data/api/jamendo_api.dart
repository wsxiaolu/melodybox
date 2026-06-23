import 'package:dio/dio.dart';
import '../models/track.dart';
import '../models/album.dart';
import '../../core/constants.dart';

/// Jamendo API v3.0 封装
/// 文档: https://developer.jamendo.com/v3.0
class JamendoApi {
  final Dio _dio;
  final String _clientId;

  JamendoApi({String? clientId})
      : _clientId = clientId ?? AppConstants.jamendoClientId,
        _dio = Dio(BaseOptions(
          baseUrl: AppConstants.jamendoBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (_) {},
    ));
  }

  // ==================== 搜索 ====================

  /// 搜索歌曲
  Future<SearchTracksResult> searchTracks({
    required String query,
    int offset = 0,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get('/tracks', queryParameters: {
        'client_id': _clientId,
        'format': 'json',
        'search': query,
        'limit': limit,
        'offset': offset,
        'include': 'musicinfo',
        'groupby': 'artist_id',
        'audioformat': 'mp31',
        'order': 'popularity_total',
      });

      final data = response.data;
      final headers = data['headers'] as Map<String, dynamic>?;
      final total = int.tryParse(headers?['results_fullcount']?.toString() ?? '0') ?? 0;
      final results = (data['results'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .where((t) => t.audioUrl.isNotEmpty)
              .toList() ??
          [];

      return SearchTracksResult(tracks: results, total: total);
    } catch (e) {
      return SearchTracksResult(tracks: [], total: 0, error: e.toString());
    }
  }

  // ==================== 推荐/热门 ====================

  /// 热门推荐歌曲
  Future<List<Track>> getFeaturedTracks({int limit = 20}) async {
    try {
      final response = await _dio.get('/tracks', queryParameters: {
        'client_id': _clientId,
        'format': 'json',
        'featured': 'true',
        'limit': limit,
        'include': 'musicinfo',
        'audioformat': 'mp31',
        'order': 'popularity_total',
      });

      final results = (response.data['results'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .where((t) => t.audioUrl.isNotEmpty)
              .toList() ??
          [];
      return results;
    } catch (e) {
      return [];
    }
  }

  /// 最新歌曲
  Future<List<Track>> getLatestTracks({int limit = 20}) async {
    try {
      final response = await _dio.get('/tracks', queryParameters: {
        'client_id': _clientId,
        'format': 'json',
        'limit': limit,
        'include': 'musicinfo',
        'audioformat': 'mp31',
        'order': 'date',
      });

      final results = (response.data['results'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .where((t) => t.audioUrl.isNotEmpty)
              .toList() ??
          [];
      return results;
    } catch (e) {
      return [];
    }
  }

  /// 热门专辑
  Future<List<Album>> getFeaturedAlbums({int limit = 10}) async {
    try {
      final response = await _dio.get('/albums', queryParameters: {
        'client_id': _clientId,
        'format': 'json',
        'featured': 'true',
        'limit': limit,
        'order': 'popularity_total',
      });

      final results = (response.data['results'] as List<dynamic>?)
              ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return results;
    } catch (e) {
      return [];
    }
  }

  // ==================== 专辑详情 ====================

  /// 获取专辑内的歌曲
  Future<List<Track>> getAlbumTracks(int albumId) async {
    try {
      final response = await _dio.get('/tracks', queryParameters: {
        'client_id': _clientId,
        'format': 'json',
        'album_id': albumId.toString(),
        'include': 'musicinfo',
        'audioformat': 'mp31',
        'limit': '50',
      });

      final results = (response.data['results'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .where((t) => t.audioUrl.isNotEmpty)
              .toList() ??
          [];
      return results;
    } catch (e) {
      return [];
    }
  }
}

/// 搜索返回结果
class SearchTracksResult {
  final List<Track> tracks;
  final int total;
  final String? error;

  SearchTracksResult({required this.tracks, required this.total, this.error});

  bool get hasError => error != null;
}
