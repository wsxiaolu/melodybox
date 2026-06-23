import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../../core/constants.dart';

/// 本地存储管理器（跨平台：Android + Windows）
/// 收藏用 SharedPreferences，下载记录用 JSON 文件
class LocalStorage {
  static LocalStorage? _instance;
  static Future<LocalStorage> get instance async {
    _instance ??= await LocalStorage._init();
    return _instance!;
  }

  late final SharedPreferences _prefs;
  late final String _downloadsPath;
  late final String _favoritesPath;
  List<Map<String, dynamic>> _downloads = [];

  LocalStorage._();

  static Future<LocalStorage> _init() async {
    final storage = LocalStorage._();
    storage._prefs = await SharedPreferences.getInstance();

    final appDir = await getApplicationDocumentsDirectory();
    final melodyDir = Directory('${appDir.path}/melody_box');

    if (!await melodyDir.exists()) {
      await melodyDir.create(recursive: true);
    }

    // 下载音乐存放目录
    final downloadsDir = Directory('${melodyDir.path}/${AppConstants.downloadDirName}');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    storage._downloadsPath = downloadsDir.path;

    // 收藏文件
    storage._favoritesPath = '${melodyDir.path}/${AppConstants.favoritesFileName}';
    final favFile = File(storage._favoritesPath);
    if (!await favFile.exists()) {
      await favFile.writeAsString('[]');
    }

    // 加载下载记录
    final dlFile = File('${melodyDir.path}/downloads.json');
    if (await dlFile.exists()) {
      final content = await dlFile.readAsString();
      storage._downloads = List<Map<String, dynamic>>.from(
        json.decode(content) as List,
      );
    }

    return storage;
  }

  // ==================== 收藏 ====================

  /// 获取收藏的歌曲完整列表
  Future<List<Track>> getFavoriteTracks() async {
    try {
      final file = File(_favoritesPath);
      final content = await file.readAsString();
      final list = json.decode(content) as List<dynamic>;
      return list
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取收藏的歌曲 ID 列表
  Future<List<int>> getFavoriteIds() async {
    final tracks = await getFavoriteTracks();
    return tracks.map((t) => t.id).toList();
  }

  Future<void> addFavorite(Track track) async {
    final tracks = await getFavoriteTracks();
    if (!tracks.any((t) => t.id == track.id)) {
      tracks.insert(0, track);
      await File(_favoritesPath).writeAsString(
          json.encode(tracks.map((t) => t.toJson()).toList()));
    }
  }

  Future<void> removeFavorite(int trackId) async {
    final tracks = await getFavoriteTracks();
    tracks.removeWhere((t) => t.id == trackId);
    await File(_favoritesPath).writeAsString(json.encode(
        tracks.map((t) => t.toJson()).toList()));
  }

  Future<bool> isFavorite(int trackId) async {
    final tracks = await getFavoriteTracks();
    return tracks.any((t) => t.id == trackId);
  }

  // ==================== 下载记录 ====================

  List<Map<String, dynamic>> get downloads => List.unmodifiable(_downloads);

  bool isDownloaded(int trackId) {
    return _downloads.any((d) => d['track_id'] == trackId);
  }

  String? getDownloadPath(int trackId) {
    try {
      return _downloads.firstWhere((d) => d['track_id'] == trackId)['local_path'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> addDownload(Track track, String localPath) async {
    if (!isDownloaded(track.id)) {
      _downloads.add({
        'track_id': track.id,
        'track_name': track.name,
        'artist_name': track.artistName,
        'image_url': track.imageUrl,
        'local_path': localPath,
        'downloaded_at': DateTime.now().toIso8601String(),
      });
      await _saveDownloads();
    }
  }

  Future<void> removeDownload(int trackId) async {
    _downloads.removeWhere((d) => d['track_id'] == trackId);
    // 也删除文件
    final file = File('$_downloadsPath/$trackId.mp3');
    if (await file.exists()) {
      await file.delete();
    }
    await _saveDownloads();
  }

  Future<void> _saveDownloads() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dlFile = File('${appDir.path}/melody_box/downloads.json');
    await dlFile.writeAsString(json.encode(_downloads));
  }

  /// 获取下载文件夹路径
  String get downloadsPath => _downloadsPath;

  /// 获取某个歌曲的本地文件路径
  String getLocalFilePath(int trackId) => '$_downloadsPath/$trackId.mp3';

  // ==================== 设置 ====================

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    return _prefs.getString(key) ?? defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    await _prefs.setString(key, value);
  }
}
