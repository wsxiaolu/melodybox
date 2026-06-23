/// 艺人数据模型
class Artist {
  final int id;
  final String name;
  final String imageUrl;
  final String? shortDescription;
  final int? albumsCount;
  final int? tracksCount;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.shortDescription,
    this.albumsCount,
    this.tracksCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '未知艺人',
      imageUrl: json['image']?.toString() ?? '',
      shortDescription: json['shortdescription']?.toString(),
      albumsCount: int.tryParse(json['albums']?.toString() ?? '0') ?? 0,
      tracksCount: int.tryParse(json['tracks']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  String toString() => name;
}
