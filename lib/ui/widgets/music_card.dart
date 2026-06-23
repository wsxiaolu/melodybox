import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/models/track.dart';
import '../../core/theme.dart';

/// 歌曲卡片组件
class MusicCard extends StatelessWidget {
  final Track track;
  final bool isFavorite;
  final bool isDownloaded;
  final double? downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const MusicCard({
    super.key,
    required this.track,
    required this.isFavorite,
    required this.isDownloaded,
    this.downloadProgress,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha(38),
                  Colors.white.withAlpha(10),
                ],
              ),
              border: Border.all(color: Colors.white.withAlpha(51)),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 封面图
                _buildCover(),
                const SizedBox(width: 14),

                // 歌曲信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${track.albumName} · ${track.durationText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // 操作按钮
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: track.imageUrl.isNotEmpty
            ? Image.network(
                track.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderCover(),
              )
            : _placeholderCover(),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.twilightPurple, AppTheme.sakuraPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 28),
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收藏按钮
        IconButton(
          onPressed: onFavoriteToggle,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppTheme.favorite : Colors.white54,
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(height: 4),
        // 下载按钮
        if (isDownloaded && onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: '删除下载',
          )
        else if (downloadProgress != null && downloadProgress! < 1.0)
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: downloadProgress,
              strokeWidth: 2.5,
              color: AppTheme.skyBlue,
              backgroundColor: Colors.white12,
            ),
          )
        else if (onDownload != null)
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined, color: Colors.white54, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: '下载',
          ),
      ],
    );
  }
}
