import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/track_entity.dart';
import '../../domain/entities/chaos_filter.dart';
import '../music_source_interface.dart';
import '../../core/constants/app_constants.dart';

// ============================================================
// YOUTUBE BACKEND SERVICE
// Kết nối với server FastAPI yt-dlp trung gian
// Lấy nhạc YouTube không bị lỗi 403, không lo cập nhật APK
// ============================================================

class YouTubeBackendService implements MusicSourceService {
  final String _baseUrl;
  final http.Client _client;
  final Random _random = Random();

  List<TrackEntity> _cachedTracks = [];
  bool _isReplenishing = false;

  YouTubeBackendService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? AppConstants.youtubeBackendBaseUrl,
        _client = client ?? http.Client();

  // ----------------------------------------------------------
  // Tìm kiếm bài hát YouTube qua Backend
  // ----------------------------------------------------------
  @override
  Future<List<TrackEntity>> searchTracks(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    debugPrint('🔎 [YouTubeBackend] Tìm kiếm: "$cleanQuery" (limit: $limit)...');

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': cleanQuery,
        'limit': '$limit',
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('❌ [YouTubeBackend] HTTP ${response.statusCode}: ${response.body}');
        return [];
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = data['results'] as List? ?? [];
      final results = items.map((item) => _mapJsonToTrack(item)).toList();

      debugPrint('✅ [YouTubeBackend] Tìm thấy ${results.length} bài hát cho "$cleanQuery"');
      return results;
    } catch (e, stack) {
      debugPrint('❌ [YouTubeBackend Error] Lỗi tìm kiếm "$cleanQuery": $e');
      debugPrint('📋 StackTrace:\n$stack');
      return [];
    }
  }

  // ----------------------------------------------------------
  // Lấy 1 bài hát ngẫu nhiên
  // ----------------------------------------------------------
  @override
  Future<TrackEntity> getRandomTrack({
    ChaosFilter? filter,
    Set<String>? excludeIds,
  }) async {
    final effectiveExclude = excludeIds ?? {};

    // 1. Kiểm tra cache có sẵn không
    final available = _cachedTracks.where((t) => !effectiveExclude.contains(t.id)).toList();
    if (available.isNotEmpty) {
      final picked = available[_random.nextInt(available.length)];
      debugPrint('⚡ [YouTubeBackend] Chọn bài từ cache: "${picked.title}" - ${picked.artist}');

      if (available.length < 5) {
        _replenishCacheInBackground(filter);
      }
      return picked;
    }

    // 2. Gọi backend lấy bài random
    debugPrint('🌐 [YouTubeBackend] Gọi API lấy bài ngẫu nhiên...');
    final queryParams = <String, String>{};
    if (filter != null && !filter.isEmpty) {
      if (filter.genre != null) queryParams['genre'] = filter.genre!;
      if (filter.mood != null) queryParams['mood'] = filter.mood!;
      if (filter.decade != null) queryParams['decade'] = filter.decade!;
    }

    final uri = Uri.parse('$_baseUrl/random').replace(queryParameters: queryParams);
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final track = _mapStreamJsonToTrack(data);
        debugPrint('🎯 [YouTubeBackend] Chọn ngẫu nhiên: "${track.title}" - ${track.artist}');
        return track;
      }
    } catch (e) {
      debugPrint('⚠️ [YouTubeBackend] Lỗi gọi /random: $e');
    }

    // Fallback: Tìm kiếm bài phổ biến
    final fallbackList = await searchTracks('vietnamese chill acoustic hits', limit: 10);
    if (fallbackList.isNotEmpty) {
      _cachedTracks = fallbackList;
      return fallbackList.first;
    }

    throw Exception('Không thể nạp bài hát từ YouTube Backend. Vui lòng kiểm tra server!');
  }

  // ----------------------------------------------------------
  // Lấy stream URL cho bài hát theo Video ID
  // ----------------------------------------------------------
  @override
  Future<TrackEntity?> getTrackById(String id) async {
    final uri = Uri.parse('$_baseUrl/stream').replace(
      queryParameters: {'id': id},
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return _mapStreamJsonToTrack(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [YouTubeBackend] Lỗi lấy stream cho ID $id: $e');
      return null;
    }
  }

  // ----------------------------------------------------------
  // Lấy danh sách bài hát liên quan (cùng ca sĩ, chương trình, thể loại)
  // ----------------------------------------------------------
  @override
  Future<List<TrackEntity>> getRelatedTracks(TrackEntity track, {int limit = 15}) async {
    debugPrint('📻 [YouTubeBackend] Tìm bài hát liên quan cho: "${track.title}" - ${track.artist}...');
    final uri = Uri.parse('$_baseUrl/related').replace(
      queryParameters: {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'limit': '$limit',
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final items = data['results'] as List? ?? [];
        final results = items.map((item) => _mapJsonToTrack(item)).toList();
        debugPrint('✅ [YouTubeBackend] Tìm thấy ${results.length} bài hát liên quan (Query: ${data['query']})');
        return results;
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [YouTubeBackend] Lỗi lấy bài liên quan: $e');
      return [];
    }
  }

  // ----------------------------------------------------------
  // Pre-warm cache khi app mở
  // ----------------------------------------------------------
  @override
  Future<void> warmupCache({ChaosFilter? filter}) async {
    if (_cachedTracks.isNotEmpty) return;
    try {
      debugPrint('⚡ [YouTubeBackend] Pre-warming cache ngầm khi mở app...');
      final query = filter?.genre ?? 'vietnamese chill acoustic music';
      final results = await searchTracks(query, limit: 15);
      if (results.isNotEmpty) {
        _cachedTracks = results;
        debugPrint('⚡ [YouTubeBackend] Cache đã nạp sẵn ${results.length} bài hát trong RAM!');
      }
    } catch (_) {}
  }

  void _replenishCacheInBackground(ChaosFilter? filter) {
    if (_isReplenishing) return;
    _isReplenishing = true;
    final query = filter?.genre ?? 'vietnamese lofi chill acoustic';
    searchTracks(query, limit: 10).then((newBatch) {
      if (newBatch.isNotEmpty) {
        final existingIds = _cachedTracks.map((t) => t.id).toSet();
        final additions = newBatch.where((t) => !existingIds.contains(t.id)).toList();
        _cachedTracks.addAll(additions);
        debugPrint('📦 [YouTubeBackend] Đã nạp ngầm thêm ${additions.length} bài vào kho!');
      }
    }).catchError((_) {}).whenComplete(() {
      _isReplenishing = false;
    });
  }

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------
  TrackEntity _mapJsonToTrack(Map<String, dynamic> item) {
    final durationMs = item['durationMs'] as int? ?? 180000;
    return TrackEntity(
      id: item['id'] as String,
      title: item['title'] as String? ?? 'Unknown',
      artist: item['artist'] as String? ?? 'Unknown Artist',
      thumbnailUrl: item['thumbnailUrl'] as String? ?? '',
      duration: Duration(milliseconds: durationMs),
      mimeType: 'audio/mp4',
    );
  }

  TrackEntity _mapStreamJsonToTrack(Map<String, dynamic> data) {
    final durationMs = data['durationMs'] as int? ?? 180000;
    return TrackEntity(
      id: data['id'] as String,
      title: data['title'] as String? ?? 'Unknown',
      artist: data['artist'] as String? ?? 'Unknown Artist',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      duration: Duration(milliseconds: durationMs),
      streamUrl: data['streamUrl'] as String?,
      mimeType: data['mimeType'] as String? ?? 'audio/mp4',
    );
  }

  @override
  void clearCache() {
    _cachedTracks.clear();
  }

  @override
  void dispose() {
    _client.close();
  }
}
