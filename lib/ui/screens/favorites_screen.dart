import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/player_provider.dart';
import '../../core/theme.dart';
import '../widgets/anime_background.dart';
import '../widgets/music_card.dart';
import '../widgets/mini_player.dart';

/// 收藏页面
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('我的收藏')),
        body: Consumer<FavoritesProvider>(
          builder: (context, favProvider, _) {
            final tracks = favProvider.favoriteTracks;

            if (tracks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, color: Colors.white24, size: 64),
                    SizedBox(height: 12),
                    Text('还没有收藏的歌曲', style: TextStyle(color: AppTheme.textHint)),
                    SizedBox(height: 4),
                    Text('在歌曲卡片上点击 ♡ 即可收藏',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                  ],
                ),
              );
            }

            final player = context.watch<PlayerProvider>();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: MusicCard(
                    track: track,
                    isFavorite: true,
                    isDownloaded: false,
                    onTap: () => player.play(track, playlist: tracks),
                    onFavoriteToggle: () => favProvider.toggleFavorite(track),
                  ),
                );
              },
            );
          },
        ),
        bottomSheet: MiniPlayer(
          onTap: () {},
        ),
      ),
    );
  }
}
