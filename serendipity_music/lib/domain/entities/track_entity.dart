// ============================================================
// TRACK ENTITY — Domain model cho bài hát
// ============================================================

class TrackEntity {
  final String id;           // YouTube videoId
  final String title;        // Tên bài hát
  final String artist;       // Tên nghệ sĩ / channel
  final String thumbnailUrl; // URL ảnh thumbnail
  final Duration duration;   // Thời lượng
  final String? streamUrl;   // Audio stream URL (từ yt-explode)
  final int? streamSize;     // Tổng số bytes của audio stream
  final String? mimeType;    // MIME type (audio/mp4, audio/webm)
  final DateTime? playedAt;  // Thời điểm nghe (cho history)

  // Metadata phụ (từ Chaos Filter)
  final String? genre;
  final String? language;
  final String? regionCode;
  final String? decade;
  final String? mood;

  const TrackEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.streamUrl,
    this.streamSize,
    this.mimeType,
    this.playedAt,
    this.genre,
    this.language,
    this.regionCode,
    this.decade,
    this.mood,
  });

  TrackEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    Duration? duration,
    String? streamUrl,
    int? streamSize,
    String? mimeType,
    DateTime? playedAt,
    String? genre,
    String? language,
    String? regionCode,
    String? decade,
    String? mood,
  }) {
    return TrackEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
      streamSize: streamSize ?? this.streamSize,
      mimeType: mimeType ?? this.mimeType,
      playedAt: playedAt ?? this.playedAt,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      regionCode: regionCode ?? this.regionCode,
      decade: decade ?? this.decade,
      mood: mood ?? this.mood,
    );
  }

  /// URL thumbnail chất lượng cao
  String get highResThumbnail =>
      thumbnailUrl.isNotEmpty ? thumbnailUrl : 'https://img.youtube.com/vi/$id/maxresdefault.jpg';

  String get mediumResThumbnail =>
      thumbnailUrl.isNotEmpty ? thumbnailUrl : 'https://img.youtube.com/vi/$id/hqdefault.jpg';

  String get durationFormatted {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TrackEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
