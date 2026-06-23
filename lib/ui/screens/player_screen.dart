import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../core/theme.dart';

/// 全屏播放器页面
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final track = player.currentTrack;
        if (track == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0820),
            body: Center(child: Text('没有正在播放的歌曲',
              style: TextStyle(color: AppTheme.textSecondary))),
          );
        }

        // 播放时旋转封面
        if (player.isPlaying) {
          _rotateController.repeat();
        } else {
          _rotateController.stop();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B0820),
          appBar: AppBar(
            title: Text(track.name, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // 旋转封面
                _buildRotatingCover(track),
                const SizedBox(height: 40),

                // 歌曲信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(track.name,
                        style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(track.artistName,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(track.albumName,
                        style: const TextStyle(color: AppTheme.textHint, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 进度条
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          activeTrackColor: AppTheme.sakuraPink,
                          inactiveTrackColor: Colors.white.withAlpha(38),
                          thumbColor: AppTheme.sakuraPink,
                          overlayColor: AppTheme.sakuraPink.withAlpha(51),
                        ),
                        child: Slider(
                          value: player.progress.clamp(0.0, 1.0),
                          onChanged: (v) => player.seekTo(v),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(player.position),
                            style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                          Text(_formatDuration(player.duration),
                            style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 控制按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 上一首
                      IconButton(
                        onPressed: player.hasPrevious ? () => player.previous() : null,
                        icon: Icon(Icons.skip_previous,
                          color: player.hasPrevious ? Colors.white70 : Colors.white24,
                          size: 40),
                      ),
                      // 播放/暂停
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.sakuraPink, AppTheme.twilightPurple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.sakuraPink.withAlpha(77),
                              blurRadius: 20, spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => player.togglePlayPause(),
                          icon: Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white, size: 40,
                          ),
                        ),
                      ),
                      // 下一首
                      IconButton(
                        onPressed: player.hasNext ? () => player.next() : null,
                        icon: Icon(Icons.skip_next,
                          color: player.hasNext ? Colors.white70 : Colors.white24,
                          size: 40),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotatingCover(track) {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateController.value * 2 * pi,
          child: child,
        );
      },
      child: Container(
        width: 260, height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.sakuraPink.withAlpha(51),
              blurRadius: 40,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: AppTheme.twilightPurple.withAlpha(38),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipOval(
          child: track.imageUrl.isNotEmpty
              ? Image.network(track.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderDisc())
              : _placeholderDisc(),
        ),
      ),
    );
  }

  Widget _placeholderDisc() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.twilightPurple, AppTheme.sakuraPink, AppTheme.skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.white38, size: 80),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
