import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/track_entity.dart';
import '../../domain/entities/chaos_filter.dart';

import '../music_source_interface.dart';
import '../../core/constants/app_constants.dart';

// ============================================================
// JAMENDO MUSIC SERVICE
// Nguồn nhạc Creative Commons / Indie chính thức qua Jamendo API v3.0
// Tốc độ cao, stream MP3 trực tiếp, 0 độ trễ, không lỗi 403
// ============================================================

class JamendoMusicService implements MusicSourceService {
  static const String _baseUrl = 'https://api.jamendo.com/v3.0';
  static const String _defaultClientId = AppConstants.jamendoClientId;

  final String clientId;
  final http.Client _client;
  final Random _random = Random();

  // Cache danh sách bài hát đang có để lấy nhanh ngẫu hứng
  List<TrackEntity> _cachedTracks = [];

  JamendoMusicService({
    String? clientId,
    http.Client? client,
  })  : clientId = clientId ?? _defaultClientId,
        _client = client ?? http.Client();

  bool _isReplenishing = false;

  // ----------------------------------------------------------
  // Pre-warm cache khi app mở (để bấm ⚡ phát ngay lập tức 0ms)
  // ----------------------------------------------------------
  @override
  Future<void> warmupCache({ChaosFilter? filter}) async {
    if (_cachedTracks.isNotEmpty) return;
    try {
      debugPrint('⚡ [JamendoService] Pre-warming cache ngầm khi mở app...');
      final batch = await _fetchBatchFromJamendo(filter);
      if (batch.isNotEmpty) {
        _cachedTracks = batch;
        debugPrint('⚡ [JamendoService] Cache đã nạp sẵn ${batch.length} bài hát trong RAM!');
      }
    } catch (_) {}
  }

  void _replenishCacheInBackground(ChaosFilter? filter) {
    if (_isReplenishing) return;
    _isReplenishing = true;
    _fetchBatchFromJamendo(filter).then((newBatch) {
      if (newBatch.isNotEmpty) {
        final existingIds = _cachedTracks.map((t) => t.id).toSet();
        final additions = newBatch.where((t) => !existingIds.contains(t.id)).toList();
        _cachedTracks.addAll(additions);
        debugPrint('📦 [JamendoService] Đã nạp ngầm thêm ${additions.length} bài vào kho dự trữ (Tổng: ${_cachedTracks.length})');
      }
    }).catchError((_) {}).whenComplete(() {
      _isReplenishing = false;
    });
  }

  // ----------------------------------------------------------
  // Tìm kiếm bài hát theo từ khóa (cho màn hình Tìm kiếm)
  // ----------------------------------------------------------
  @override
  Future<List<TrackEntity>> searchTracks(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    debugPrint('🔎 [JamendoService] Tìm kiếm bài hát: "$cleanQuery" (limit: $limit)...');

    final uri = Uri.parse('$_baseUrl/tracks/').replace(
      queryParameters: {
        'client_id': clientId,
        'format': 'json',
        'search': cleanQuery,
        'limit': '$limit',
        'offset': '$offset',
        'audioformat': 'mp32',
        'imagesize': '300',
        'order': 'popularity_total',
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));
      final results = _parseResults(response);
      debugPrint('✅ [JamendoService] Tìm thấy ${results.length} bài hát cho từ khóa "$cleanQuery"');
      return results;
    } catch (e, stack) {
      debugPrint('❌ [JamendoService Error] Lỗi khi tìm kiếm "$cleanQuery": $e');
      debugPrint('📋 StackTrace:\n$stack');
      return [];
    }
  }

  // ----------------------------------------------------------
  // Lấy 1 bài hát ngẫu nhiên cho nút Chaos Player (⚡)
  // ----------------------------------------------------------
  @override
  Future<TrackEntity> getRandomTrack({
    ChaosFilter? filter,
    Set<String>? excludeIds,
  }) async {
    final effectiveExclude = excludeIds ?? {};

    // 1. Kiểm tra cache có sẵn bài chưa phát không -> lấy ngay lập tức (0ms)
    final available = _cachedTracks.where((t) => !effectiveExclude.contains(t.id)).toList();
    if (available.isNotEmpty) {
      final picked = available[_random.nextInt(available.length)];
      debugPrint('⚡ [JamendoService] Chọn bài từ cache tức thì: "${picked.title}" - ${picked.artist}');

      // Nếu bài trong kho sắp hết (< 5 bài), tự động gọi ngầm nạp thêm
      if (available.length < 5) {
        _replenishCacheInBackground(filter);
      }
      return picked;
    }

    // 2. Nếu cache rỗng hoặc đã nghe hết, tải batch mới từ Jamendo API
    debugPrint('🌐 [JamendoService] Nạp batch nhạc mới từ Jamendo API...');
    final newBatch = await _fetchBatchFromJamendo(filter);

    if (newBatch.isEmpty) {
      // Fallback: Lấy các bài nổi bật mặc định nếu filter quá chặt
      debugPrint('⚠️ [JamendoService] Filter không có kết quả, lấy bài thịnh hành...');
      final fallbackBatch = await _fetchPopularTracks();
      if (fallbackBatch.isNotEmpty) {
        _cachedTracks = fallbackBatch;
        return fallbackBatch[_random.nextInt(fallbackBatch.length)];
      }
      throw Exception('Không tìm thấy bài hát nào từ Jamendo. Vui lòng thử lại.');
    }

    _cachedTracks = newBatch;
    final candidates = newBatch.where((t) => !effectiveExclude.contains(t.id)).toList();
    final chosen = candidates.isNotEmpty
        ? candidates[_random.nextInt(candidates.length)]
        : newBatch[_random.nextInt(newBatch.length)];

    debugPrint('🎯 [JamendoService] Chọn bài ngẫu nhiên: "${chosen.title}" - ${chosen.artist} (ID: ${chosen.id})');
    return chosen;
  }

  // ----------------------------------------------------------
  // Lấy chi tiết bài hát theo ID (nếu cần phát từ Playlist/History)
  // ----------------------------------------------------------
  @override
  Future<TrackEntity?> getTrackById(String id) async {
    final uri = Uri.parse('$_baseUrl/tracks/').replace(
      queryParameters: {
        'client_id': clientId,
        'format': 'json',
        'id': id,
        'audioformat': 'mp32',
        'imagesize': '300',
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      final list = _parseResults(response);
      return list.isNotEmpty ? list.first : null;
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // Lấy bài hát liên quan cho Jamendo (theo genre hoặc artist)
  // ----------------------------------------------------------
  @override
  Future<List<TrackEntity>> getRelatedTracks(TrackEntity track, {int limit = 15}) async {
    final query = track.genre ?? track.artist;
    return searchTracks(query, limit: limit);
  }

  // ----------------------------------------------------------
  // Gọi API Jamendo dựa trên ChaosFilter
  // ----------------------------------------------------------
  Future<List<TrackEntity>> _fetchBatchFromJamendo(ChaosFilter? filter) async {
    final queryParams = <String, String>{
      'client_id': clientId,
      'format': 'json',
      'limit': '20',
      'audioformat': 'mp32',
      'imagesize': '300',
      'boost': 'popularity_month',
    };

    // Randomize offset nhỏ (0-2) để tránh vượt quá số lượng bài
    final randomOffset = _random.nextInt(3);
    if (randomOffset > 0) {
      queryParams['offset'] = '$randomOffset';
    }

    final tags = <String>[];

    if (filter != null && !filter.isEmpty) {
      if (filter.genre != null && filter.genre!.isNotEmpty) {
        tags.add(_sanitizeTag(filter.genre!));
      }
      if (filter.mood != null && filter.mood!.isNotEmpty) {
        tags.add(_sanitizeTag(filter.mood!));
      }
      if (filter.instrument != null && filter.instrument!.isNotEmpty) {
        tags.add(_sanitizeTag(filter.instrument!));
      }
      if (filter.tempo != null && filter.tempo!.isNotEmpty) {
        final speed = _mapTempoToSpeed(filter.tempo!);
        if (speed != null) queryParams['speed'] = speed;
      }
      if (filter.language != null && filter.language!.length == 2) {
        queryParams['lang'] = filter.language!.toLowerCase();
      }
    }

    if (tags.isNotEmpty) {
      queryParams['tags'] = tags.join('+');
    } else {
      // Khi không có filter: Chọn ngẫu nhiên 1 tag phổ biến để có nhạc hay
      const popularTags = [
        'lofi', 'chill', 'rock', 'jazz', 'ambient', 'electronic',
        'indie', 'piano', 'guitar', 'pop', 'synthwave', 'funk'
      ];
      final randomTag = popularTags[_random.nextInt(popularTags.length)];
      queryParams['tags'] = randomTag;
    }

    final uri = Uri.parse('$_baseUrl/tracks/').replace(queryParameters: queryParams);
    debugPrint('🌐 [JamendoService] GET $uri');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      var results = _parseResults(response);

      // Nếu có offset mà kết quả rỗng, thử lại với offset 0
      if (results.isEmpty && randomOffset > 0) {
        queryParams.remove('offset');
        final fallbackUri = Uri.parse('$_baseUrl/tracks/').replace(queryParameters: queryParams);
        debugPrint('🌐 [JamendoService] Retry offset 0: $fallbackUri');
        final fallbackResponse = await http.get(fallbackUri).timeout(const Duration(seconds: 6));
        results = _parseResults(fallbackResponse);
      }

      return results;
    } catch (e) {
      debugPrint('⚠️ [JamendoService] Lỗi khi gọi Jamendo API: $e');
      return [];
    }
  }

  // ----------------------------------------------------------
  // Lấy danh sách bài hát thịnh hành (Popular/Featured)
  // ----------------------------------------------------------
  Future<List<TrackEntity>> _fetchPopularTracks({int limit = 20}) async {
    final uri = Uri.parse('$_baseUrl/tracks/').replace(
      queryParameters: {
        'client_id': clientId,
        'format': 'json',
        'limit': '$limit',
        'boost': 'popularity_month',
        'audioformat': 'mp32',
        'imagesize': '300',
      },
    );
    debugPrint('🌐 [JamendoService] Fallback GET $uri');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      final res = _parseResults(response);
      debugPrint('🔥 [JamendoService] Nạp bài thịnh hành thành công: ${res.length} bài');
      return res;
    } catch (e) {
      debugPrint('⚠️ [JamendoService] Lỗi khi nạp bài thịnh hành: $e');
      return [];
    }
  }

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------
  List<TrackEntity> _parseResults(http.Response response) {
    if (response.statusCode != 200) {
      debugPrint('❌ [JamendoService] HTTP ${response.statusCode}: ${response.body}');
      return [];
    }
    try {
      final data = jsonDecode(response.body);
      final headers = data['headers'];
      final results = data['results'] as List? ?? [];
      if (results.isEmpty) {
        debugPrint('⚠️ [JamendoService] 0 results: ${headers?['error_message']} (code: ${headers?['code']}, warnings: ${headers?['warnings']})');
      }
      return results
          .where((item) => item['audio'] != null && (item['audio'] as String).isNotEmpty)
          .map((item) => _parseItem(item))
          .toList();
    } catch (e) {
      debugPrint('❌ [JamendoService] Lỗi parse JSON: $e');
      return [];
    }
  }

  TrackEntity _parseItem(Map<String, dynamic> item) {
    final durationSec = item['duration'] is int
        ? item['duration'] as int
        : (int.tryParse(item['duration']?.toString() ?? '') ?? 180);

    final imageUrl = (item['image'] as String?)?.isNotEmpty == true
        ? item['image'] as String
        : (item['album_image'] as String?) ?? '';

    return TrackEntity(
      id: item['id'].toString(),
      title: item['name'] ?? 'Untitled',
      artist: item['artist_name'] ?? 'Unknown Artist',
      thumbnailUrl: imageUrl,
      duration: Duration(seconds: durationSec),
      streamUrl: item['audio'],
      mimeType: 'audio/mpeg',
      genre: item['musicinfo']?['tags']?['genres']?.firstOrNull,
    );
  }

  String _sanitizeTag(String tag) {
    var cleaned = tag
        .toLowerCase()
        .replaceAll('music', '')
        .replaceAll('songs', '')
        .replaceAll('hits', '')
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '+');
    switch (cleaned) {
      case 'electronic+edm':
      case 'edm':
        return 'electronic+edm';
      case 'lo-fi+chill':
      case 'lofi':
        return 'lofi';
      case 'indie+folk':
        return 'indie+folk';
      case 'r&b+soul':
      case 'rnb':
        return 'rnb';
      case 'hip+hop':
        return 'hiphop';
      case 'bossa+nova':
        return 'bossanova';
      default:
        return cleaned;
    }
  }

  String? _mapTempoToSpeed(String tempo) {
    switch (tempo.toLowerCase()) {
      case 'slow':
        return 'low';
      case 'medium':
        return 'medium';
      case 'fast':
        return 'high';
      case 'very_fast':
        return 'veryhigh';
      default:
        return null;
    }
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
