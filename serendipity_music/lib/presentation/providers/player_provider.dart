import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../../domain/entities/track_entity.dart';
import '../../domain/entities/chaos_filter.dart';
import '../../services/audio/audio_handler.dart';
import '../../services/music_source_interface.dart';
import '../../services/jamendo/jamendo_music_service.dart';
import '../../services/youtube/youtube_backend_service.dart';
import '../../data/datasources/local_history_storage.dart';
import '../../core/constants/app_constants.dart';

// ============================================================
// PLAYER STATE
// ============================================================

enum PlayerStatus { idle, loading, playing, paused, error }

class PlayerState {
  final PlayerStatus status;
  final TrackEntity? currentTrack;
  final String? errorMessage;
  final bool isSleepTimerActive;
  final int historyVersion;
  final int favoriteVersion;
  final ChaosFilter filter;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentTrack,
    this.errorMessage,
    this.isSleepTimerActive = false,
    this.historyVersion = 0,
    this.favoriteVersion = 0,
    this.filter = ChaosFilter.empty,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    TrackEntity? currentTrack,
    String? errorMessage,
    bool? isSleepTimerActive,
    int? historyVersion,
    int? favoriteVersion,
    ChaosFilter? filter,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      errorMessage: errorMessage ?? this.errorMessage,
      isSleepTimerActive: isSleepTimerActive ?? this.isSleepTimerActive,
      historyVersion: historyVersion ?? this.historyVersion,
      favoriteVersion: favoriteVersion ?? this.favoriteVersion,
      filter: filter ?? this.filter,
    );
  }
}

// ============================================================
// PLAYER PROVIDER (Riverpod Notifier)
// ============================================================

class PlayerNotifier extends StateNotifier<PlayerState> {
  final SerendipityAudioHandler _audioHandler;
  final MusicSourceService _musicService;
  final LocalHistoryStorage _historyStorage;

  // Anti-loop buffer: Lưu tối đa 50 trackId gần nhất
  final Queue<String> _playedIds = Queue();

  // Session history: Toàn bộ bài đã nghe trong phiên
  final List<TrackEntity> _sessionHistory = [];

  // Favorites: Toàn bộ bài hát yêu thích (Đã tim)
  final List<TrackEntity> _favorites = [];
  final Set<String> _favoriteIds = {};

  // Vị trí con trỏ trong lịch sử khi người dùng bấm Previous / Next
  int _currentHistoryIndex = 0;
  StreamSubscription? _playerStateSub;

  // Autoplay theo bài liên quan (Contextual Autoplay / Radio)
  // Khi người dùng bấm nghe 1 bài cụ thể (từ Search/History), các bài tiếp theo sẽ là bài liên quan
  final List<TrackEntity> _relatedAutoplayQueue = [];
  bool _isAutoplayRelatedMode = false;
  bool _isFetchingRelated = false;

  PlayerNotifier(
    this._audioHandler,
    this._musicService,
    this._historyStorage,
  ) : super(const PlayerState()) {
    _audioHandler.onRequestNextTrack = _onAudioHandlerRequestNext;
    _audioHandler.onRequestPreviousTrack = _onAudioHandlerRequestPrevious;
    _audioHandler.onTrackStarted = _onTrackStarted;
    _listenToPlayerState();
    _loadHistory();
  }

  void _listenToPlayerState() {
    _playerStateSub = _audioHandler.player.playerStateStream.listen((justAudioState) {
      final isPlaying = justAudioState.playing;
      final procState = justAudioState.processingState;

      if (procState == ja.ProcessingState.loading || procState == ja.ProcessingState.buffering) {
        if (state.status != PlayerStatus.loading) {
          state = state.copyWith(status: PlayerStatus.loading);
        }
      } else if (isPlaying) {
        if (state.status != PlayerStatus.playing) {
          state = state.copyWith(status: PlayerStatus.playing);
        }
      } else if (!isPlaying && procState != ja.ProcessingState.idle) {
        if (state.status != PlayerStatus.paused) {
          state = state.copyWith(status: PlayerStatus.paused);
        }
      }
    });
  }

  void _loadHistory() {
    try {
      final saved = _historyStorage.getHistory();
      _sessionHistory.addAll(saved);

      final favs = _historyStorage.getFavorites();
      _favorites.addAll(favs);
      _favoriteIds.addAll(favs.map((t) => t.id));

      if (_sessionHistory.isNotEmpty || _favorites.isNotEmpty) {
        state = state.copyWith(
          historyVersion: state.historyVersion + 1,
          favoriteVersion: state.favoriteVersion + 1,
        );
      }
    } catch (_) {}
  }

  // ----------------------------------------------------------
  // Phát bài ngẫu nhiên (nút ⚡ trung tâm)
  // ----------------------------------------------------------
  Future<void> playRandom() async {
    debugPrint('\n========================================');
    debugPrint('⚡ [Player] Bắt đầu tìm kiếm bài hát ngẫu nhiên...');
    _isAutoplayRelatedMode = false;
    _relatedAutoplayQueue.clear();
    _currentHistoryIndex = 0;
    state = state.copyWith(status: PlayerStatus.loading);
    try {
      final track = await _getNextRandomTrack();
      if (track == null) throw Exception('Không tìm thấy bài hát phù hợp');
      debugPrint('🎯 [Player] Chọn được bài ngẫu nhiên: "${track.title}" (${track.id})');
      state = state.copyWith(currentTrack: track);
      await _playTrack(track);
    } catch (e, stack) {
      debugPrint('❌ [Player Error] Lỗi khi phát ngẫu nhiên: $e');
      debugPrint('📋 [Player StackTrace]:\n$stack');
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ----------------------------------------------------------
  // Phát bài cụ thể (từ màn hình Search / History)
  // ----------------------------------------------------------
  Future<void> playSpecific(TrackEntity track) async {
    debugPrint('\n========================================');
    debugPrint('▶️ [Player] Chọn phát bài cụ thể: "${track.title}" - ${track.artist} (ID: ${track.id})');
    _currentHistoryIndex = 0;
    _isAutoplayRelatedMode = true;
    _relatedAutoplayQueue.clear();

    // Khởi chạy tìm kiếm bài liên quan trong nền để sẵn sàng phát tiếp theo
    unawaited(_fetchRelatedQueue(track));

    state = state.copyWith(
      currentTrack: track,
      status: PlayerStatus.loading,
    );
    try {
      await _playTrack(track);
    } catch (e, stack) {
      debugPrint('❌ [Player Error] Lỗi khi phát bài "${track.title}": $e');
      debugPrint('📋 [Player StackTrace]:\n$stack');
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ----------------------------------------------------------
  // Internal: Nạp trước các bài liên quan vào hàng đợi autoplay
  // ----------------------------------------------------------
  Future<void> _fetchRelatedQueue(TrackEntity track) async {
    if (_isFetchingRelated) return;
    _isFetchingRelated = true;
    try {
      debugPrint('📻 [RelatedAutoplay] Đang tìm bài liên quan đến "${track.title}" - ${track.artist}...');
      final related = await _musicService.getRelatedTracks(track, limit: 10);
      final existingIds = <String>{
        track.id,
        ..._playedIds,
        ..._relatedAutoplayQueue.map((t) => t.id),
      };
      final filtered = related.where((t) => !existingIds.contains(t.id)).toList();
      _relatedAutoplayQueue.addAll(filtered);
      debugPrint('📻 [RelatedAutoplay] Đã nạp ${filtered.length} bài liên quan mới (Hàng đợi hiện có: ${_relatedAutoplayQueue.length})');
    } catch (e) {
      debugPrint('⚠️ [RelatedAutoplay] Lỗi khi nạp bài liên quan: $e');
    } finally {
      _isFetchingRelated = false;
    }
  }

  // ----------------------------------------------------------
  // Skip sang bài tiếp theo (hỗ trợ quay lại từ lịch sử hoặc bài liên quan / random)
  // ----------------------------------------------------------
  Future<void> skipToNext() async {
    debugPrint('⏭️ [Player] Người dùng bấm Skip sang bài tiếp theo...');
    state = state.copyWith(status: PlayerStatus.loading);
    if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      final nextTrack = _sessionHistory[_currentHistoryIndex];
      debugPrint('⏭️ [Player] Phát bài kế tiếp từ lịch sử: "${nextTrack.title}" (Index: $_currentHistoryIndex)');
      state = state.copyWith(currentTrack: nextTrack);
      await _playTrack(nextTrack);
      return;
    }

    TrackEntity? next;
    if (_isAutoplayRelatedMode && _relatedAutoplayQueue.isNotEmpty) {
      next = _relatedAutoplayQueue.removeAt(0);
      debugPrint('📻 [RelatedAutoplay] Phát bài tiếp theo từ hàng đợi liên quan: "${next.title}" - ${next.artist}');
      if (_relatedAutoplayQueue.length < 3) {
        unawaited(_fetchRelatedQueue(next));
      }
    } else {
      next = await _getNextRandomTrack();
    }

    if (next != null) {
      state = state.copyWith(currentTrack: next);
      await _playTrack(next);
    }
  }

  // ----------------------------------------------------------
  // Quay lại bài trước trong lịch sử (⏮️)
  // ----------------------------------------------------------
  Future<void> skipToPrevious() async {
    debugPrint('⏮️ [Player] Người dùng bấm Previous...');
    if (_sessionHistory.isEmpty) return;
    if (_currentHistoryIndex < _sessionHistory.length - 1) {
      _currentHistoryIndex++;
      final prevTrack = _sessionHistory[_currentHistoryIndex];
      debugPrint('⏮️ [Player] Quay lại bài trước: "${prevTrack.title}" (Index: $_currentHistoryIndex)');
      state = state.copyWith(currentTrack: prevTrack, status: PlayerStatus.loading);
      await _playTrack(prevTrack);
    } else {
      debugPrint('⏮️ [Player] Đã ở bài đầu tiên trong lịch sử nghe');
    }
  }

  // ----------------------------------------------------------
  // Play / Pause toggle
  // ----------------------------------------------------------
  Future<void> togglePlayPause() async {
    if (_audioHandler.isPlaying) {
      debugPrint('⏸️ [Player] Tạm dừng phát nhạc');
      await _audioHandler.pause();
      state = state.copyWith(status: PlayerStatus.paused);
    } else {
      debugPrint('▶️ [Player] Tiếp tục phát nhạc');
      await _audioHandler.play();
      state = state.copyWith(status: PlayerStatus.playing);
    }
  }

  // ----------------------------------------------------------
  // Seek
  // ----------------------------------------------------------
  Future<void> seek(Duration position) async {
    debugPrint('⏩ [Player] Tua đến vị trí: ${position.inSeconds}s');
    await _audioHandler.seek(position);
  }

  // ----------------------------------------------------------
  // Cập nhật Chaos Filter
  // ----------------------------------------------------------
  void updateFilter(ChaosFilter filter) {
    debugPrint('🎲 [ChaosFilter] Cập nhật bộ lọc mới: ${filter.summary}');
    _musicService.clearCache();
    state = state.copyWith(filter: filter);
  }

  // ----------------------------------------------------------
  // Sleep Timer
  // ----------------------------------------------------------
  void setSleepTimer(Duration duration, {bool endOfTrack = false}) {
    debugPrint('⏰ [SleepTimer] Đặt hẹn giờ tắt nhạc sau ${duration.inMinutes} phút (Hết bài: $endOfTrack)');
    _audioHandler.setSleepTimer(duration, endOfTrack: endOfTrack);
    state = state.copyWith(isSleepTimerActive: true);
  }

  void cancelSleepTimer() {
    debugPrint('⏰ [SleepTimer] Đã hủy hẹn giờ tắt nhạc');
    _audioHandler.cancelSleepTimer();
    state = state.copyWith(isSleepTimerActive: false);
  }

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------
  List<TrackEntity> get sessionHistory =>
      List.unmodifiable(_sessionHistory);
  List<TrackEntity> get favorites =>
      List.unmodifiable(_favorites);
  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);
  ChaosFilter get currentFilter => state.filter;
  Stream<Duration> get positionStream => _audioHandler.positionStream;
  Stream<Duration?> get durationStream => _audioHandler.durationStream;

  // ----------------------------------------------------------
  // Thao tác Yêu thích (Đã tim ❤️)
  // ----------------------------------------------------------
  Future<void> toggleFavorite(TrackEntity track) async {
    final isFav = _favoriteIds.contains(track.id);
    if (isFav) {
      _favoriteIds.remove(track.id);
      _favorites.removeWhere((t) => t.id == track.id);
      await _historyStorage.removeFavorite(track.id);
      debugPrint('💔 [Favorites] Bỏ thích bài: "${track.title}"');
    } else {
      _favoriteIds.add(track.id);
      _favorites.insert(0, track);
      await _historyStorage.saveFavorite(track);
      debugPrint('❤️ [Favorites] Đã thích bài: "${track.title}"');
    }
    state = state.copyWith(favoriteVersion: state.favoriteVersion + 1);
  }

  // ----------------------------------------------------------
  // Callbacks cho AudioHandler (background / notification)
  // ----------------------------------------------------------
  Future<TrackEntity?> _onAudioHandlerRequestNext() async {
    TrackEntity? next;
    if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      next = _sessionHistory[_currentHistoryIndex];
    } else if (_isAutoplayRelatedMode && _relatedAutoplayQueue.isNotEmpty) {
      next = _relatedAutoplayQueue.removeAt(0);
      debugPrint('📻 [RelatedAutoplay Auto] Tự động chuyển sang bài liên quan: "${next.title}" - ${next.artist}');
      if (_relatedAutoplayQueue.length < 3) {
        unawaited(_fetchRelatedQueue(next));
      }
    } else {
      next = await _getNextRandomTrack();
    }
    if (next != null) {
      if (next.streamUrl == null) {
        final fetched = await _musicService.getTrackById(next.id);
        if (fetched != null && fetched.streamUrl != null) {
          next = fetched;
        }
      }
      state = state.copyWith(currentTrack: next, status: PlayerStatus.loading);
    }
    return next;
  }

  Future<TrackEntity?> _onAudioHandlerRequestPrevious() async {
    if (_sessionHistory.isEmpty) return null;
    if (_currentHistoryIndex < _sessionHistory.length - 1) {
      _currentHistoryIndex++;
      var prev = _sessionHistory[_currentHistoryIndex];
      if (prev.streamUrl == null) {
        final fetched = await _musicService.getTrackById(prev.id);
        if (fetched != null && fetched.streamUrl != null) {
          prev = fetched;
        }
      }
      state = state.copyWith(currentTrack: prev, status: PlayerStatus.loading);
      return prev;
    }
    return null;
  }

  // ----------------------------------------------------------
  // Internal: Lấy bài ngẫu nhiên tiếp theo
  // ----------------------------------------------------------
  Future<TrackEntity?> _getNextRandomTrack() async {
    try {
      final excludeIds = _playedIds.toSet();
      debugPrint('🔍 [Player] Tìm track ngẫu nhiên từ Jamendo (Loại trừ ${excludeIds.length} bài đã phát)...');
      final track = await _musicService.getRandomTrack(
        filter: state.filter,
        excludeIds: excludeIds,
      );
      debugPrint('🎯 [Player] Đã chọn track: "${track.title}" (ID: ${track.id})');
      return track;
    } catch (e, stack) {
      debugPrint('❌ [Player Error] Lỗi trong _getNextRandomTrack: $e');
      debugPrint('📋 [Player StackTrace]:\n$stack');
      return null;
    }
  }

  // ----------------------------------------------------------
  // Internal: Phát track + nạp streamUrl nếu chưa có
  // ----------------------------------------------------------
  Future<void> _playTrack(TrackEntity track) async {
    var resolvedTrack = track;
    if (resolvedTrack.streamUrl == null) {
      debugPrint('⏳ [Player] Track chưa có streamUrl, đang nạp từ Jamendo: ${track.title} (${track.id})...');
      final fetched = await _musicService.getTrackById(track.id);
      if (fetched != null && fetched.streamUrl != null) {
        resolvedTrack = fetched;
      } else {
        throw Exception('Không thể tải URL bài hát "${track.title}"');
      }
    }
    debugPrint('📻 [Player] Đang nạp track "${resolvedTrack.title}" vào AudioHandler...');
    await _audioHandler.playTrack(resolvedTrack);
  }

  // ----------------------------------------------------------
  // Internal: Callback khi bài bắt đầu phát
  // ----------------------------------------------------------
  void _onTrackStarted(TrackEntity track) {
    if (_currentHistoryIndex == 0) {
      if (_sessionHistory.isEmpty || _sessionHistory.first.id != track.id) {
        final withTime = track.copyWith(playedAt: DateTime.now());
        _sessionHistory.insert(0, withTime);
        _historyStorage.saveTrack(withTime);
      }
    }

    // Anti-loop buffer
    _playedIds.addLast(track.id);
    if (_playedIds.length > AppConstants.antiLoopBufferSize) {
      _playedIds.removeFirst();
    }

    state = state.copyWith(
      status: PlayerStatus.playing,
      currentTrack: track,
      historyVersion: state.historyVersion + 1,
    );
  }

  // ----------------------------------------------------------
  // Xóa toàn bộ lịch sử nghe
  // ----------------------------------------------------------
  Future<void> clearHistory() async {
    debugPrint('🧹 [History] Người dùng bấm xóa sạch toàn bộ lịch sử nghe');
    _sessionHistory.clear();
    await _historyStorage.clearHistory();
    state = state.copyWith(historyVersion: state.historyVersion + 1);
  }

  // ----------------------------------------------------------
  // Xóa 1 bài khỏi lịch sử
  // ----------------------------------------------------------
  Future<void> deleteHistoryTrack(String id) async {
    debugPrint('🗑️ [History] Xóa bài hát khỏi lịch sử (ID: $id)');
    _sessionHistory.removeWhere((t) => t.id == id);
    await _historyStorage.deleteTrack(id);
    state = state.copyWith(historyVersion: state.historyVersion + 1);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _audioHandler.dispose();
    super.dispose();
  }
}

// ============================================================
// RIVERPOD PROVIDERS
// ============================================================

final audioHandlerProvider = Provider<SerendipityAudioHandler>((ref) {
  final handler = SerendipityAudioHandler();
  ref.onDispose(handler.dispose);
  return handler;
});

final musicServiceProvider = Provider<MusicSourceService>((ref) {
  final MusicSourceService service;
  if (AppConstants.activeMusicSource == MusicSource.youtubeBackend) {
    debugPrint('🎵 [MusicSource] Sử dụng nguồn nhạc: YouTube Backend API');
    service = YouTubeBackendService();
  } else {
    debugPrint('🎵 [MusicSource] Sử dụng nguồn nhạc: Jamendo Official API');
    service = JamendoMusicService();
  }
  ref.onDispose(service.dispose);
  return service;
});

// Tương thích ngược với các file khác
final jamendoMusicServiceProvider = musicServiceProvider;

final historyStorageProvider = Provider<LocalHistoryStorage>((ref) {
  return LocalHistoryStorage();
});

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(
    ref.watch(audioHandlerProvider),
    ref.watch(musicServiceProvider),
    ref.watch(historyStorageProvider),
  );
});
