import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../data/local/storage.dart';
import '../../data/models/track.dart';

/// 下载任务状态
enum DownloadStatus { idle, downloading, completed, failed }

/// 单个下载任务
class DownloadTask {
  final Track track;
  DownloadStatus status;
  double progress; // 0.0 ~ 1.0
  String? error;

  DownloadTask({
    required this.track,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.error,
  });
}

/// 下载状态管理
class DownloadProvider extends ChangeNotifier {
  final Map<int, DownloadTask> _tasks = {};
  List<Map<String, dynamic>> _downloadedItems = [];
  final Dio _dio = Dio();

  Map<int, DownloadTask> get tasks => _tasks;
  List<Map<String, dynamic>> get downloadedItems => _downloadedItems;

  DownloadProvider() {
    _dio.interceptors.add(LogInterceptor(logPrint: (_) {}));
  }

  Future<void> loadDownloads() async {
    final storage = await LocalStorage.instance;
    _downloadedItems = List.from(storage.downloads);
    notifyListeners();
  }

  bool isDownloaded(int trackId) {
    return _downloadedItems.any((d) => d['track_id'] == trackId);
  }

  bool isDownloading(int trackId) {
    return _tasks.containsKey(trackId) &&
        _tasks[trackId]!.status == DownloadStatus.downloading;
  }

  double? getProgress(int trackId) {
    return _tasks[trackId]?.progress;
  }

  /// 开始下载
  Future<void> download(Track track) async {
    if (isDownloaded(track.id) || isDownloading(track.id)) return;

    final task = DownloadTask(track: track);
    _tasks[track.id] = task;

    try {
      task.status = DownloadStatus.downloading;
      notifyListeners();

      final storage = await LocalStorage.instance;
      final filePath = storage.getLocalFilePath(track.id);

      await _dio.download(
        track.audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            task.progress = received / total;
            notifyListeners();
          }
        },
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      task.status = DownloadStatus.completed;
      task.progress = 1.0;

      await storage.addDownload(track, filePath);
      _downloadedItems = List.from(storage.downloads);

      notifyListeners();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      notifyListeners();
    }
  }

  /// 删除下载
  Future<void> removeDownload(int trackId) async {
    final storage = await LocalStorage.instance;
    await storage.removeDownload(trackId);
    _tasks.remove(trackId);
    _downloadedItems = List.from(storage.downloads);
    notifyListeners();
  }

  /// 取消下载
  void cancelDownload(int trackId) {
    _tasks.remove(trackId);
    notifyListeners();
  }
}
