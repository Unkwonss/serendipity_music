import 'package:flutter/material.dart';
import 'track_entity.dart';

class PlaylistEntity {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<TrackEntity> tracks;
  final int colorValue;
  final int iconCodePoint;

  const PlaylistEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.tracks = const [],
    this.colorValue = 0xFFFF6B2C,
    this.iconCodePoint = 0xe4b6, // Icons.queue_music_rounded
  });

  int get trackCount => tracks.length;

  IconData get iconData =>
      // ignore: non_const_argument_for_const_parameter
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  PlaylistEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<TrackEntity>? tracks,
    int? colorValue,
    int? iconCodePoint,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      tracks: tracks ?? this.tracks,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'tracks': tracks.map((t) => {
        'id': t.id,
        'title': t.title,
        'artist': t.artist,
        'thumbnailUrl': t.thumbnailUrl,
        'durationMs': t.duration.inMilliseconds,
        'streamUrl': t.streamUrl,
        'genre': t.genre,
      }).toList(),
    };
  }

  factory PlaylistEntity.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] as List? ?? [];
    final parsedTracks = rawTracks.map((item) {
      final map = item as Map<String, dynamic>;
      return TrackEntity(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? 'Unknown',
        artist: map['artist'] as String? ?? 'Unknown Artist',
        thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
        streamUrl: map['streamUrl'] as String?,
        duration: Duration(milliseconds: map['durationMs'] as int? ?? 180000),
        genre: map['genre'] as String?,
      );
    }).toList();

    return PlaylistEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Playlist',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      colorValue: json['colorValue'] as int? ?? 0xFFFF6B2C,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe4b6,
      tracks: parsedTracks,
    );
  }
}
