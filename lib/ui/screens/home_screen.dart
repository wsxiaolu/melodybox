import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api/music_api.dart';
import '../../data/models/track.dart';
import '../../providers/player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/download_provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../widgets/anime_background.dart';
import '../widgets/mini_player.dart';

/// 首页：热门推荐 + 最新歌曲 + 精选专辑
class HomeScreen extends StatefulWidget {
  final ValueChanged<String> onNavigateToSearch;

  const HomeScreen({super.key, required this.onNavigateToSearch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicApi _api = MusicApi();
  final ScrollController _scrollController = ScrollController();

  List<Track> _chartTracks = [];
  List<Track> _searchExampleTracks = [];
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getChartTracks(limit: 15),
        _api.getFeaturedAlbums(limit: 8),
      ]);

      final chartData = results[0] as List<Map<String, dynamic>>;
      final albumData = results[1] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _chartTracks = chartData
              .map((e) => Track.fromJson(e))
              .toList();
          _albums = albumData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            children: [
              const SizedBox(height: 8),
              const Text('🎵 MelodyBox',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: AppTheme.sakuraPink, letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(AppConstants.appSubtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          toolbarHeight: 80,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.sakuraPink))
            : _error != null
                ? _buildErrorView()
                : RefreshIndicator(
                    color: AppTheme.sakuraPink,
                    onRefresh: _loadData,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // 搜索栏入口
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: GestureDetector(
                              onTap: () => widget.onNavigateToSearch(''),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        Colors.white.withAlpha(38), Colors.white.withAlpha(10),
                                      ]),
                                      border: Border.all(color: Colors.white.withAlpha(51)),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: const Row(children: [
                                      Icon(Icons.search, color: Colors.white54, size: 22),
                                      SizedBox(width: 10),
                                      Text('搜索歌曲、艺人、专辑...',
                                        style: TextStyle(color: Colors.white38, fontSize: 14)),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 热门推荐
                        if (_chartTracks.isNotEmpty) ...[
                          _sectionHeader('🔥 热门排行'),
                          _trackGrid(_chartTracks),
                        ],

                        // 精选专辑
                        if (_albums.isNotEmpty) ...[
                          _sectionHeader('💿 精选专辑'),
                          _albumList(),
                        ],

                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                      ],
                    ),
                  ),
        bottomSheet: MiniPlayer(onTap: () {}),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text('网络连接失败', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.textHint, fontSize: 11), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sakuraPink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {double marginTop = 24}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, marginTop, 20, 8),
        child: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ),
    );
  }

  Widget _trackGrid(List<Track> tracks) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildGridCard(tracks[index]),
          childCount: tracks.length,
        ),
      ),
    );
  }

  Widget _buildGridCard(Track track) {
    final player = context.read<PlayerProvider>();
    final favorites = context.read<FavoritesProvider>();

    return GestureDetector(
      onTap: () => player.play(track, playlist: _chartTracks),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withAlpha(25), Colors.white.withAlpha(8),
              ]),
              border: Border.all(color: Colors.white.withAlpha(38)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: SizedBox(
                      width: double.infinity,
                      child: track.imageUrl.isNotEmpty
                          ? Image.network(track.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _miniPlaceholder())
                          : _miniPlaceholder(),
                    ),
                  ),
                ),
                // 信息
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(track.artistName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.twilightPurple, AppTheme.sakuraPink],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Icon(Icons.music_note, color: Colors.white38, size: 32),
    );
  }

  Widget _albumList() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _albums.length,
          itemBuilder: (context, index) {
            final album = _albums[index];
            final name = album['name'] as String? ?? '未知';
            final image = album['image_url'] as String? ?? '';
            final count = album['tracks_count'] ?? 0;
            final id = album['id'] as int? ?? 0;

            return GestureDetector(
              onTap: () async {
                final tracksData = await _api.getAlbumTracks(id);
                final tracks = tracksData
                    .map((e) => Track.fromJson(e))
                    .toList();
                if (tracks.isNotEmpty && context.mounted) {
                  context.read<PlayerProvider>().play(tracks.first, playlist: tracks);
                }
              },
              child: SizedBox(
                width: 130,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 80, height: 80,
                          child: image.isNotEmpty
                              ? Image.network(image, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _miniPlaceholder())
                              : _miniPlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                      Text('$count首',
                        style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
