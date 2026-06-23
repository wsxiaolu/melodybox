import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../core/theme.dart';

/// 迷你播放器（底部常驻栏）
class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final track = player.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A0533).withAlpha(230),
                      const Color(0xFF0D1B3E).withAlpha(230),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.white.withAlpha(26)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 进度条
                    LinearProgressIndicator(
                      value: player.progress,
                      backgroundColor: Colors.white.withAlpha(25),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.sakuraPink),
                      minHeight: 2,
                    ),
                    const SizedBox(height: 8),
                    // 歌曲信息 + 控制
                    Row(
                      children: [
                        // 封面
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: track.imageUrl.isNotEmpty
                                ? Image.network(track.imageUrl, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _musicIcon())
                                : _musicIcon(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(track.artistName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        // 播放/暂停
                        IconButton(
                          onPressed: () => player.togglePlayPause(),
                          icon: Icon(
                            player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: AppTheme.sakuraPink, size: 36,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                        // 下一首
                        IconButton(
                          onPressed: () => player.next(),
                          icon: const Icon(Icons.skip_next, color: Colors.white54, size: 30),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ],
                    ),
                    // 安全区（iPhone底部）
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _musicIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.twilightPurple, AppTheme.sakuraPink],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 22),
    );
  }
}
