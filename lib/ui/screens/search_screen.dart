import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/download_provider.dart';
import '../../core/theme.dart';
import '../widgets/anime_background.dart';
import '../widgets/search_bar.dart';
import '../widgets/music_card.dart';

/// 搜索结果页面
class SearchScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SearchScreen({super.key, required this.onBack});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('搜索音乐'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: widget.onBack,
          ),
        ),
        body: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MelodySearchBar(
                controller: _searchController,
                autofocus: true,
                onChanged: (text) {
                  if (text.trim().length >= 1) {
                    context.read<SearchProvider>().search(text);
                  }
                },
                onClear: () {
                  context.read<SearchProvider>().clear();
                },
              ),
            ),
            // 搜索结果
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Consumer<SearchProvider>(
      builder: (context, search, _) {
        if (search.isSearching && search.results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.sakuraPink),
                SizedBox(height: 16),
                Text('搜索中...', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        if (search.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                const SizedBox(height: 12),
                Text('搜索失败: ${search.error}',
                  style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => search.search(search.query),
                  child: const Text('重试', style: TextStyle(color: AppTheme.skyBlue)),
                ),
              ],
            ),
          );
        }

        if (search.query.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.white24, size: 64),
                SizedBox(height: 12),
                Text('输入关键词搜索歌曲', style: TextStyle(color: AppTheme.textHint)),
                SizedBox(height: 4),
                Text('支持歌曲名、艺人名、专辑名',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
              ],
            ),
          );
        }

        if (search.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_off, color: Colors.white24, size: 64),
                const SizedBox(height: 12),
                Text('没有找到 "${search.query}" 的歌曲',
                  style: const TextStyle(color: AppTheme.textHint)),
              ],
            ),
          );
        }

        final favorites = context.watch<FavoritesProvider>();
        final downloads = context.watch<DownloadProvider>();
        final player = context.watch<PlayerProvider>();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: search.results.length + (search.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= search.results.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(
                  color: AppTheme.sakuraPink, strokeWidth: 2)),
              );
            }

            final track = search.results[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: MusicCard(
                track: track,
                isFavorite: favorites.isFavorite(track.id),
                isDownloaded: downloads.isDownloaded(track.id),
                downloadProgress: downloads.getProgress(track.id),
                onTap: () => player.play(track, playlist: search.results),
                onFavoriteToggle: () => favorites.toggleFavorite(track),
                onDownload: track.isDownloadable == true
                    ? () => downloads.download(track)
                    : null,
                onDelete: downloads.isDownloaded(track.id)
                    ? () => downloads.removeDownload(track.id)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
