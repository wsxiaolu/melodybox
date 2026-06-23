import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/player_provider.dart';
import '../../data/models/track.dart';
import '../../core/theme.dart';
import '../widgets/anime_background.dart';
import '../widgets/music_card.dart';
import '../widgets/mini_player.dart';

/// 下载管理页面
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadProvider>().loadDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('下载管理')),
        body: Consumer<DownloadProvider>(
          builder: (context, dlProvider, _) {
            if (dlProvider.downloadedItems.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_outlined, color: Colors.white24, size: 64),
                    SizedBox(height: 12),
                    Text('还没有下载的歌曲', style: TextStyle(color: AppTheme.textHint)),
                    SizedBox(height: 4),
                    Text('在歌曲卡片上点击下载图标即可离线收听',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                  ],
                ),
              );
            }

            final player = context.watch<PlayerProvider>();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: dlProvider.downloadedItems.length,
              itemBuilder: (context, index) {
                final item = dlProvider.downloadedItems[index];
                final track = Track(
                  id: item['track_id'] as int,
                  name: item['track_name'] as String? ?? '未知',
                  artistName: item['artist_name'] as String? ?? '未知',
                  artistId: 0,
                  albumName: '',
                  albumId: 0,
                  imageUrl: item['image_url'] as String? ?? '',
                  audioUrl: item['local_path'] as String? ?? '',
                  duration: 0,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: MusicCard(
                    track: track,
                    isFavorite: false,
                    isDownloaded: true,
                    onTap: () => player.play(track),
                    onFavoriteToggle: () {},
                    onDelete: () => dlProvider.removeDownload(track.id),
                  ),
                );
              },
            );
          },
        ),
        bottomSheet: MiniPlayer(
          onTap: () {
            // 打开全屏播放器
          },
        ),
      ),
    );
  }
}
