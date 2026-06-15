class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;
  String? streamUrl;
  String? localPath; // For offline downloads

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.streamUrl,
    this.localPath,
  });

  // Convert a Song object to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'durationMs': duration.inMilliseconds,
      'localPath': localPath,
    };
  }

  // Create a Song object from JSON Map
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      localPath: json['localPath'] as String?,
    );
  }

  // Helper to get high quality square thumbnail
  String get squareThumbnail {
    // If it's a standard youtube image, we can crop/retrieve it or just use it.
    // YouTube standard images are 16:9 but using fit: BoxFit.cover in Flutter crops it perfectly to 1:1.
    return thumbnailUrl;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
