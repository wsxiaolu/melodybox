import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/track.dart';
import '../../data/local/storage.dart';
import '../../data/api/music_api.dart';

/// 播放器状态
enum PlayState { idle, loading, playing, paused, error }

/// 音乐播放器状态管理
class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Track? _currentTrack;
  PlayState _playState = PlayState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  List<Track> _playlist = [];
  int _currentIndex = -1;

  Track? get currentTrack => _currentTrack;
  PlayState get playState => _playState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _playState == PlayState.playing;
  bool get isShuffle => _isShuffle;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  /// 进度文本 "01:23 / 04:56"
  String get progressText {
    String fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    return '${fmt(_position)} / ${fmt(_duration)}';
  }

  PlayerProvider() {
    _player.playerStateStream.listen((state) {
      _onAudioPlayerStateChanged(state);
    });
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        next();
      }
    });
  }

  /// 播放单个歌曲
  Future<void> play(Track track, {List<Track>? playlist}) async {
    try {
      _playState = PlayState.loading;
      notifyListeners();

      if (playlist != null) {
        _playlist = playlist;
        _currentIndex = playlist.indexWhere((t) => t.id == track.id);
      }

      String audioUrl = track.audioUrl;

      // 如果没有直接的音频链接，通过 API 获取
      if (audioUrl.isEmpty && track.id > 0) {
        final api = MusicApi();
        final playData = await api.getPlayUrl(track.id);
        audioUrl = (playData['audio_url']?.toString() ?? '')
            .replaceAll('http://', 'https://');
        // 更新 track 的音频链接
        track = Track(
          id: track.id,
          name: playData['song_name']?.toString() ?? track.name,
          artistName: track.artistName,
          artistId: track.artistId,
          albumName: track.albumName,
          albumId: track.albumId,
          imageUrl: (playData['cover_url']?.toString() ?? track.imageUrl),
          audioUrl: audioUrl,
          duration: track.duration,
        );
      }

      // 优先使用本地下载的文件
      final storage = await LocalStorage.instance;
      final localPath = storage.getDownloadPath(track.id);
      final audioSource = (localPath != null && File(localPath).existsSync())
          ? AudioSource.file(localPath)
          : AudioSource.uri(Uri.parse(audioUrl));

      _currentTrack = track;
      await _player.setAudioSource(audioSource);
      await _player.play();
      _playState = PlayState.playing;
      notifyListeners();
    } catch (e) {
      _playState = PlayState.error;
      notifyListeners();
      debugPrint('播放失败: $e');
    }
  }

  /// 播放/暂停
  Future<void> togglePlayPause() async {
    if (_playState == PlayState.playing) {
      await _player.pause();
    } else if (_playState == PlayState.paused) {
      await _player.play();
    }
  }

  /// 暂停
  Future<void> pause() async {
    await _player.pause();
  }

  /// 恢复播放
  Future<void> resume() async {
    await _player.play();
  }

  /// 下一首
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _playlist.length) {
      nextIndex = 0; // 循环
    }
    await play(_playlist[nextIndex], playlist: _playlist);
  }

  /// 上一首
  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = _playlist.length - 1;
    }
    await play(_playlist[prevIndex], playlist: _playlist);
  }

  /// 拖拽进度
  Future<void> seekTo(double value) async {
    final pos = Duration(
        milliseconds: (value * _duration.inMilliseconds).round());
    await _player.seek(pos);
  }

  void _onAudioPlayerStateChanged(PlayerState state) {
    if (state.playing) {
      _playState = PlayState.playing;
    } else if (_player.processingState == ProcessingState.completed) {
      _playState = PlayState.paused;
    } else {
      _playState = _player.playing ? PlayState.playing : PlayState.paused;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
