import 'package:dio/dio.dart';

/// MelodyBox 音乐 API — 通过本地代理服务器获取 gequhai.com 数据
class MusicApi {
  final Dio _dio;

  MusicApi()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://localhost:8080',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ));

  // ==================== 搜索 ====================

  Future<Map<String, dynamic>> searchTracks({
    required String query,
    int offset = 0,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get('/api/search', queryParameters: {
        'q': query,
      });

      final data = response.data as Map<String, dynamic>;
      final allTracks = (data['tracks'] as List<dynamic>?)
              ?.map((e) => _normalizeTrack(e as Map<String, dynamic>))
              .toList() ??
          [];

      // 手动分页
      final paged = allTracks.skip(offset).take(limit).toList();
      return {
        'tracks': paged,
        'total': allTracks.length,
      };
    } catch (e) {
      return {'tracks': <Map<String, dynamic>>[], 'total': 0, 'error': e.toString()};
    }
  }

  // ==================== 热门 / 排行榜 ====================

  Future<List<Map<String, dynamic>>> getChartTracks({int limit = 20}) async {
    try {
      final response = await _dio.get('/api/hot');
      final data = response.data as Map<String, dynamic>;
      final tracks = (data['tracks'] as List<dynamic>?)
              ?.map((e) => _normalizeTrack(e as Map<String, dynamic>))
              .take(limit)
              .toList() ??
          [];
      return tracks;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNewTracks({int limit = 20}) async {
    return getChartTracks(limit: limit);
  }

  // ==================== 专辑 ====================

  Future<List<Map<String, dynamic>>> getFeaturedAlbums({int limit = 10}) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getAlbumTracks(int albumId) async {
    return [];
  }

  // ==================== 播放 / 下载 ====================

  /// 获取歌曲的播放/下载链接
  Future<Map<String, dynamic>> getPlayUrl(int songId) async {
    try {
      final response = await _dio.get('/api/play/$songId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'audio_url': '', 'download_url': ''};
    }
  }

  // ==================== 数据格式化 ====================

  Map<String, dynamic> _normalizeTrack(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? 0,
      'name': json['name']?.toString() ?? '未知',
      'artist_name': json['artist_name']?.toString() ?? '未知',
      'artist_id': 0,
      'album_name': json['album_name']?.toString() ?? '',
      'album_id': 0,
      'image_url': json['image_url']?.toString() ?? json['cover_url']?.toString() ?? '',
      'audio_url': json['audio_url']?.toString() ?? '',
      'duration': 0,
      'is_downloadable': true,
      'play_id': json['id'] ?? 0,
    };
  }
}
