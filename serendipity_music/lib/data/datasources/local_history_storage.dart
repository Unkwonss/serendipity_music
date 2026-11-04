import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/track_entity.dart';
import '../../domain/entities/playlist_entity.dart';

// ============================================================
// LOCAL HISTORY & PLAYLIST STORAGE
// Lưu trữ lịch sử nghe nhạc, yêu thích và playlist 100% local dùng Hive
// ============================================================

class LocalHistoryStorage {
  static const String boxName = 'track_history_box';
  static const String favoritesBoxName = 'favorites_box';
  static const String playlistsBoxName = 'playlists_box';
  Box? _box;
  Box? _favBox;
  Box? _playBox;

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }

    if (!Hive.isBoxOpen(favoritesBoxName)) {
      _favBox = await Hive.openBox(favoritesBoxName);
    } else {
      _favBox = Hive.box(favoritesBoxName);
    }

    if (!Hive.isBoxOpen(playlistsBoxName)) {
      _playBox = await Hive.openBox(playlistsBoxName);
    } else {
      _playBox = Hive.box(playlistsBoxName);
    }
  }

  Box get _historyBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('LocalHistoryStorage is not initialized. Call init() first.');
    }
    return _box!;
  }

  Box get _favoritesBox {
    if (_favBox == null || !_favBox!.isOpen) {
      throw StateError('FavoritesBox is not initialized. Call init() first.');
    }
    return _favBox!;
  }

  Box get _playlistsBox {
    if (_playBox == null || !_playBox!.isOpen) {
      throw StateError('PlaylistsBox is not initialized. Call init() first.');
    }
    return _playBox!;
  }

  // ----------------------------------------------------------
  // Lưu 1 bài hát vào lịch sử
  // ----------------------------------------------------------
  Future<void> saveTrack(TrackEntity track) async {
    try {
      final key = '${track.id}_${DateTime.now().millisecondsSinceEpoch}';
      final data = {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'thumbnailUrl': track.thumbnailUrl,
        'streamUrl': track.streamUrl,
        'durationMs': track.duration.inMilliseconds,
        'playedAt': (track.playedAt ?? DateTime.now()).toIso8601String(),
        'genre': track.genre,
        'language': track.language,
        'regionCode': track.regionCode,
        'decade': track.decade,
        'mood': track.mood,
      };
      await _historyBox.put(key, jsonEncode(data));
      debugPrint('💾 [HistoryStorage] Đã lưu vào bộ nhớ máy: "${track.title}"');
    } catch (e) {
      debugPrint('❌ [HistoryStorage Error] Lỗi lưu lịch sử: $e');
    }
  }

  // ----------------------------------------------------------
  // Kiểm tra stream URL đã hết hạn chưa (YouTube GoogleVideo expire timestamp)
  // ----------------------------------------------------------
  static bool isUrlExpired(String? url) {
    if (url == null || url.isEmpty) return true;
    try {
      final uri = Uri.parse(url);
      final expireParam = uri.queryParameters['expire'];
      if (expireParam != null) {
        final expireSec = int.tryParse(expireParam);
        if (expireSec != null) {
          final expireDate = DateTime.fromMillisecondsSinceEpoch(expireSec * 1000);
          return DateTime.now().isAfter(expireDate.subtract(const Duration(minutes: 5)));
        }
      }
    } catch (_) {}
    return false;
  }

  // ----------------------------------------------------------
  // Lấy toàn bộ lịch sử (sắp xếp mới nhất lên đầu)
  // ----------------------------------------------------------
  List<TrackEntity> getHistory() {
    final list = <TrackEntity>[];
    for (var key in _historyBox.keys.toList().reversed) {
      final raw = _historyBox.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw as String) as Map<String, dynamic>;
        final rawStreamUrl = map['streamUrl'] as String?;
        list.add(TrackEntity(
          id: map['id'] as String? ?? '',
          title: map['title'] as String? ?? 'Unknown',
          artist: map['artist'] as String? ?? 'Unknown Artist',
          thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
          streamUrl: isUrlExpired(rawStreamUrl) ? null : rawStreamUrl,
          duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
          playedAt: map['playedAt'] != null
              ? DateTime.tryParse(map['playedAt'] as String)
              : null,
          genre: map['genre'] as String?,
          language: map['language'] as String?,
          regionCode: map['regionCode'] as String?,
          decade: map['decade'] as String?,
          mood: map['mood'] as String?,
        ));
      } catch (_) {}
    }
    return list;
  }

  // ----------------------------------------------------------
  // Xóa toàn bộ lịch sử
  // ----------------------------------------------------------
  Future<void> clearHistory() async {
    await _historyBox.clear();
  }

  // ----------------------------------------------------------
  // Xóa 1 bài hát khỏi lịch sử theo ID
  // ----------------------------------------------------------
  Future<void> deleteTrack(String id) async {
    final keysToDelete = <dynamic>[];
    for (var key in _historyBox.keys) {
      final raw = _historyBox.get(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw as String) as Map<String, dynamic>;
          if (map['id'] == id) {
            keysToDelete.add(key);
          }
        } catch (_) {}
      }
    }
    for (var key in keysToDelete) {
      await _historyBox.delete(key);
    }
  }

  // ----------------------------------------------------------
  // FAVORITES (Bài hát yêu thích / Đã tim ❤️)
  // ----------------------------------------------------------
  Future<void> saveFavorite(TrackEntity track) async {
    try {
      final data = {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'thumbnailUrl': track.thumbnailUrl,
        'durationMs': track.duration.inMilliseconds,
        'streamUrl': track.streamUrl,
        'genre': track.genre,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await _favoritesBox.put(track.id, jsonEncode(data));
      debugPrint('❤️ [Favorites] Đã lưu vào yêu thích: "${track.title}"');
    } catch (e) {
      debugPrint('❌ [Favorites Error] Lỗi lưu yêu thích: $e');
    }
  }

  Future<void> removeFavorite(String trackId) async {
    try {
      await _favoritesBox.delete(trackId);
      debugPrint('💔 [Favorites] Đã xóa khỏi yêu thích (ID: $trackId)');
    } catch (e) {
      debugPrint('❌ [Favorites Error] Lỗi xóa yêu thích: $e');
    }
  }

  bool isFavorite(String trackId) {
    try {
      return _favoritesBox.containsKey(trackId);
    } catch (_) {
      return false;
    }
  }

  List<TrackEntity> getFavorites() {
    final list = <TrackEntity>[];
    for (var key in _favoritesBox.keys.toList().reversed) {
      final raw = _favoritesBox.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw as String) as Map<String, dynamic>;
        final rawStreamUrl = map['streamUrl'] as String?;
        list.add(TrackEntity(
          id: map['id'] as String? ?? '',
          title: map['title'] as String? ?? 'Unknown',
          artist: map['artist'] as String? ?? 'Unknown Artist',
          thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
          streamUrl: isUrlExpired(rawStreamUrl) ? null : rawStreamUrl,
          duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
          genre: map['genre'] as String?,
        ));
      } catch (_) {}
    }
    return list;
  }

  // ----------------------------------------------------------
  // PLAYLISTS (Danh sách phát cá nhân)
  // ----------------------------------------------------------
  Future<void> savePlaylist(PlaylistEntity playlist) async {
    try {
      await _playlistsBox.put(playlist.id, jsonEncode(playlist.toJson()));
      debugPrint('📁 [PlaylistStorage] Đã lưu playlist: "${playlist.name}" (${playlist.trackCount} bài)');
    } catch (e) {
      debugPrint('❌ [PlaylistStorage Error] Lỗi lưu playlist: $e');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _playlistsBox.delete(playlistId);
      debugPrint('🗑️ [PlaylistStorage] Đã xóa playlist ID: $playlistId');
    } catch (e) {
      debugPrint('❌ [PlaylistStorage Error] Lỗi xóa playlist: $e');
    }
  }

  List<PlaylistEntity> getPlaylists() {
    final list = <PlaylistEntity>[];
    for (var key in _playlistsBox.keys.toList().reversed) {
      final raw = _playlistsBox.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw as String) as Map<String, dynamic>;
        list.add(PlaylistEntity.fromJson(map));
      } catch (_) {}
    }
    return list;
  }

  Future<void> addTrackToPlaylist(String playlistId, TrackEntity track) async {
    try {
      final raw = _playlistsBox.get(playlistId);
      if (raw == null) return;
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final playlist = PlaylistEntity.fromJson(map);

      // Tránh trùng bài trong cùng playlist
      if (playlist.tracks.any((t) => t.id == track.id)) {
        debugPrint('ℹ️ [PlaylistStorage] Bài "${track.title}" đã có sẵn trong playlist "${playlist.name}"');
        return;
      }

      final updatedTracks = [...playlist.tracks, track];
      final updated = playlist.copyWith(tracks: updatedTracks);
      await savePlaylist(updated);
      debugPrint('✅ [PlaylistStorage] Đã thêm "${track.title}" vào playlist "${playlist.name}"');
    } catch (e) {
      debugPrint('❌ [PlaylistStorage Error] Lỗi thêm bài vào playlist: $e');
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      final raw = _playlistsBox.get(playlistId);
      if (raw == null) return;
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final playlist = PlaylistEntity.fromJson(map);

      final updatedTracks = playlist.tracks.where((t) => t.id != trackId).toList();
      final updated = playlist.copyWith(tracks: updatedTracks);
      await savePlaylist(updated);
      debugPrint('🗑️ [PlaylistStorage] Đã xóa bài $trackId khỏi playlist "${playlist.name}"');
    } catch (e) {
      debugPrint('❌ [PlaylistStorage Error] Lỗi xóa bài khỏi playlist: $e');
    }
  }
}
