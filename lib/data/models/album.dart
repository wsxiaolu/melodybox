/// 专辑/歌单数据模型
class Album {
  final int id;
  final String name;
  final String artistName;
  final String imageUrl;
  final int tracksCount;
  final String? releaseDate;

  Album({
    required this.id,
    required this.name,
    required this.artistName,
    required this.imageUrl,
    required this.tracksCount,
    this.releaseDate,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '未知专辑',
      artistName: json['artist_name']?.toString() ?? '未知艺人',
      imageUrl: json['image']?.toString() ?? '',
      tracksCount: int.tryParse(json['tracks']?.toString() ?? '0') ?? 0,
      releaseDate: json['releasedate']?.toString(),
    );
  }

  @override
  String toString() => '$name ($tracksCount首)';
}
