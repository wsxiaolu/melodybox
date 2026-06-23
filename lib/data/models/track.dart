/// 歌曲数据模型
class Track {
  final int id;
  final String name;
  final String artistName;
  final int artistId;
  final String albumName;
  final int albumId;
  final String imageUrl;
  final String audioUrl;
  final int duration; // 秒
  final String? shareUrl;
  final bool? isDownloadable;

  Track({
    required this.id,
    required this.name,
    required this.artistName,
    required this.artistId,
    required this.albumName,
    required this.albumId,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    this.shareUrl,
    this.isDownloadable,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '未知歌曲',
      artistName: json['artist_name']?.toString() ?? '未知艺人',
      artistId: int.tryParse(json['artist_id']?.toString() ?? '0') ?? 0,
      albumName: json['album_name']?.toString() ?? '未知专辑',
      albumId: int.tryParse(json['album_id']?.toString() ?? '0') ?? 0,
      imageUrl: json['image']?.toString() ?? json['album_image']?.toString() ?? '',
      audioUrl: json['audio']?.toString() ?? '',
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      shareUrl: json['shareurl']?.toString(),
      isDownloadable: json['audiodownload_allowed'] is bool
          ? json['audiodownload_allowed']
          : (int.tryParse(json['audiodownload_allowed']?.toString() ?? '0') ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist_name': artistName,
      'artist_id': artistId,
      'album_name': albumName,
      'album_id': albumId,
      'image': imageUrl,
      'audio': audioUrl,
      'duration': duration,
      'shareurl': shareUrl,
    };
  }

  String get durationText {
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => '$name - $artistName';
}
