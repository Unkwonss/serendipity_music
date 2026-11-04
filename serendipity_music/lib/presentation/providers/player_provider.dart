import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../../domain/entities/track_entity.dart';
import '../../domain/entities/playlist_entity.dart';
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
  final bool isRepeatActive;
  final bool isShuffleActive;
  final String? sleepTimerLabel;
  final double playbackSpeed;
  final int historyVersion;
  final int favoriteVersion;
  final int queueVersion;
  final int playlistVersion;
  final ChaosFilter filter;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentTrack,
    this.errorMessage,
    this.isSleepTimerActive = false,
    this.isRepeatActive = false,
    this.isShuffleActive = false,
    this.sleepTimerLabel,
    this.playbackSpeed = 1.0,
    this.historyVersion = 0,
    this.favoriteVersion = 0,
    this.queueVersion = 0,
    this.playlistVersion = 0,
    this.filter = ChaosFilter.empty,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    TrackEntity? currentTrack,
    String? errorMessage,
    bool? isSleepTimerActive,
    bool? isRepeatActive,
    bool? isShuffleActive,
    String? sleepTimerLabel,
    double? playbackSpeed,
    int? historyVersion,
    int? favoriteVersion,
    int? queueVersion,
    int? playlistVersion,
    ChaosFilter? filter,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      errorMessage: errorMessage ?? this.errorMessage,
      isSleepTimerActive: isSleepTimerActive ?? this.isSleepTimerActive,
      isRepeatActive: isRepeatActive ?? this.isRepeatActive,
      isShuffleActive: isShuffleActive ?? this.isShuffleActive,
      sleepTimerLabel: sleepTimerLabel ?? this.sleepTimerLabel,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      historyVersion: historyVersion ?? this.historyVersion,
      favoriteVersion: favoriteVersion ?? this.favoriteVersion,
      queueVersion: queueVersion ?? this.queueVersion,
      playlistVersion: playlistVersion ?? this.playlistVersion,
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

  // Playlists: Danh sách phát cá nhân của người dùng
  final List<PlaylistEntity> _playlists = [];

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

      final pls = _historyStorage.getPlaylists();
      _playlists.addAll(pls);

      if (_sessionHistory.isNotEmpty || _favorites.isNotEmpty || _playlists.isNotEmpty) {
        state = state.copyWith(
          historyVersion: state.historyVersion + 1,
          favoriteVersion: state.favoriteVersion + 1,
          playlistVersion: state.playlistVersion + 1,
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

      // Nạp trước các bài tiếp theo vào Queue ngay lập tức để khi mở Queue sẽ hiện ra luôn
      unawaited(_fetchRelatedQueue(track));

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
  // Phát bài cụ thể (từ màn hình Search / History / Favorites)
  // ----------------------------------------------------------
  Future<void> playSpecific(TrackEntity track, {List<TrackEntity>? contextQueue}) async {
    debugPrint('\n========================================');
    debugPrint('▶️ [Player] Chọn phát bài cụ thể: "${track.title}" - ${track.artist} (ID: ${track.id})');
    _currentHistoryIndex = 0;
    _isAutoplayRelatedMode = true;
    _relatedAutoplayQueue.clear();

    // 1. NGAY LẬP TỨC nạp các bài tiếp theo từ danh sách nguồn vào Queue (0ms delay)
    if (contextQueue != null && contextQueue.isNotEmpty) {
      final index = contextQueue.indexWhere((t) => t.id == track.id);
      if (index >= 0 && index < contextQueue.length - 1) {
        final upcoming = contextQueue.sublist(index + 1);
        _relatedAutoplayQueue.addAll(upcoming);
        debugPrint('📋 [Queue Instant] Đã nạp ngay ${upcoming.length} bài tiếp theo từ context vào Queue!');
      } else if (index == contextQueue.length - 1 && contextQueue.length > 1) {
        final upcoming = contextQueue.sublist(0, index);
        _relatedAutoplayQueue.addAll(upcoming);
        debugPrint('📋 [Queue Instant] Bài cuối danh sách, nạp lại ${upcoming.length} bài trước đó vào Queue!');
      }
    } else {
      // Tìm trong _sessionHistory nếu có
      final histIndex = _sessionHistory.indexWhere((t) => t.id == track.id);
      if (histIndex >= 0 && histIndex < _sessionHistory.length - 1) {
        final upcoming = _sessionHistory.sublist(histIndex + 1);
        _relatedAutoplayQueue.addAll(upcoming);
        debugPrint('📋 [Queue Instant] Đã nạp ngay ${upcoming.length} bài tiếp theo từ Lịch sử vào Queue!');
      }
    }

    // 2. Nếu Queue vẫn còn ít bài (< 3), nạp bổ sung từ Favorites hoặc cache
    if (_relatedAutoplayQueue.length < 3) {
      final extra = _favorites
          .where((t) => t.id != track.id && !_relatedAutoplayQueue.any((q) => q.id == t.id))
          .take(6);
      _relatedAutoplayQueue.addAll(extra);
    }

    // Luôn đảm bảo bài đang phát không bị trùng lặp trong Queue
    _relatedAutoplayQueue.removeWhere((t) => t.id == track.id);

    // 3. Nếu đang bật Shuffle, tự động xáo trộn danh sách Queue vừa nạp
    if (state.isShuffleActive && _relatedAutoplayQueue.isNotEmpty) {
      _relatedAutoplayQueue.shuffle();
    }

    // Cập nhật state với currentTrack và queueVersion mới để UI Queue hiển thị bài hát NGAY LẬP TỨC
    state = state.copyWith(
      currentTrack: track,
      status: PlayerStatus.loading,
      queueVersion: state.queueVersion + 1,
    );

    // 4. Khởi chạy tìm kiếm thêm bài liên quan mới trong nền để nối đuôi vào Queue
    unawaited(_fetchRelatedQueue(track));

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
      var related = await _musicService.getRelatedTracks(track, limit: 12);

      // Nếu API related rỗng hoặc quá ít, tự động tìm kiếm thêm bài theo nghệ sĩ đã làm sạch tên
      final cleanArtist = track.artist
          .replaceAll(RegExp(r'(Official|Topic|VEVO|Channel|Music)', caseSensitive: false), '')
          .trim();

      if (related.length < 5 && cleanArtist.isNotEmpty && cleanArtist != 'Unknown Artist') {
        debugPrint('📻 [RelatedAutoplay] Nạp thêm bài theo nghệ sĩ "$cleanArtist"...');
        final more = await _musicService.searchTracks('$cleanArtist hits', limit: 8);
        related = [...related, ...more];
      }
      if (related.isEmpty) {
        final fallback = await _musicService.searchTracks('vietnamese chill pop hits', limit: 10);
        related = fallback;
      }

      // Tránh trùng lặp với bài hiện tại và các bài đã có sẵn trong Queue
      final currentId = state.currentTrack?.id ?? track.id;
      final existingIds = <String>{
        track.id,
        currentId,
        ..._relatedAutoplayQueue.map((t) => t.id),
      };
      final filtered = related.where((t) => !existingIds.contains(t.id)).toList();
      _relatedAutoplayQueue.addAll(filtered);

      // Đảm bảo không trùng bài đang phát
      _relatedAutoplayQueue.removeWhere((t) => t.id == currentId || t.id == track.id);
      debugPrint('📻 [RelatedAutoplay] Đã nạp ${filtered.length} bài mới vào Queue (Tổng hiện có: ${_relatedAutoplayQueue.length})');

      // Báo cho UI Queue cập nhật và hiển thị danh sách bài hát ngay lập tức
      state = state.copyWith(queueVersion: state.queueVersion + 1);
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
      final idx = state.isShuffleActive
          ? math.Random().nextInt(_relatedAutoplayQueue.length)
          : 0;
      next = _relatedAutoplayQueue.removeAt(idx);
      state = state.copyWith(queueVersion: state.queueVersion + 1);
      debugPrint('📻 [RelatedAutoplay] Phát bài tiếp theo từ Queue: "${next.title}" - ${next.artist} (Shuffle: ${state.isShuffleActive})');
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
    if (_sessionHistory.isEmpty) {
      await seek(Duration.zero);
      return;
    }
    if (_currentHistoryIndex < _sessionHistory.length - 1) {
      _currentHistoryIndex++;
      final prevTrack = _sessionHistory[_currentHistoryIndex];
      debugPrint('⏮️ [Player] Quay lại bài trước: "${prevTrack.title}" (Index: $_currentHistoryIndex)');
      state = state.copyWith(currentTrack: prevTrack, status: PlayerStatus.loading);
      await _playTrack(prevTrack);
    } else {
      // Đã ở bài đầu tiên trong lịch sử, tua lại từ đầu
      debugPrint('⏮️ [Player] Đã ở bài đầu tiên, tua lại từ 0:00');
      await seek(Duration.zero);
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
    final label = endOfTrack ? 'End' : '${duration.inMinutes}m';
    debugPrint('⏰ [SleepTimer] Đặt hẹn giờ tắt nhạc: $label (Hết bài: $endOfTrack)');
    _audioHandler.setSleepTimer(duration, endOfTrack: endOfTrack);
    state = state.copyWith(
      isSleepTimerActive: true,
      sleepTimerLabel: label,
    );
  }

  void cancelSleepTimer() {
    debugPrint('⏰ [SleepTimer] Đã hủy hẹn giờ tắt nhạc');
    _audioHandler.cancelSleepTimer();
    state = state.copyWith(
      isSleepTimerActive: false,
      sleepTimerLabel: null,
    );
  }

  // ----------------------------------------------------------
  // Repeat Mode (Lặp lại bài hát: Bật / Tắt)
  // ----------------------------------------------------------
  Future<void> toggleRepeat() async {
    final next = !state.isRepeatActive;
    await _audioHandler.player.setLoopMode(next ? ja.LoopMode.one : ja.LoopMode.off);
    state = state.copyWith(isRepeatActive: next);
    debugPrint('🔁 [Player] Chế độ lặp lại: ${next ? "BẬT (Lặp lại 1 bài)" : "TẮT"}');
  }

  // ----------------------------------------------------------
  // Shuffle Mode (Trộn bài: Bật / Tắt)
  // ----------------------------------------------------------
  Future<void> toggleShuffle() async {
    final next = !state.isShuffleActive;
    if (next && _relatedAutoplayQueue.isNotEmpty) {
      _relatedAutoplayQueue.shuffle();
    }
    state = state.copyWith(
      isShuffleActive: next,
      queueVersion: state.queueVersion + 1,
    );
    debugPrint('🔀 [Player] Chế độ trộn bài (Shuffle): ${next ? "BẬT" : "TẮT"}');
  }

  // ----------------------------------------------------------
  // Playback Speed
  // ----------------------------------------------------------
  Future<void> setPlaybackSpeed(double speed) async {
    debugPrint('⚡ [Player] Đặt tốc độ phát: ${speed}x');
    await _audioHandler.player.setSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  // ----------------------------------------------------------
  // Queue Management (Danh sách phát & Kéo thả sắp xếp)
  // ----------------------------------------------------------
  List<TrackEntity> get queue {
    final currentId = state.currentTrack?.id;
    if (currentId == null) {
      return List.unmodifiable(_relatedAutoplayQueue);
    }
    return List.unmodifiable(_relatedAutoplayQueue.where((t) => t.id != currentId));
  }

  Future<void> ensureQueueLoaded() async {
    if (state.currentTrack != null && _relatedAutoplayQueue.isEmpty) {
      // Nạp tức thì các bài từ Lịch sử hoặc Favorites để Queue không bao giờ bị rỗng
      final fallback = _sessionHistory.where((t) => t.id != state.currentTrack!.id).take(5);
      if (fallback.isNotEmpty) {
        _relatedAutoplayQueue.addAll(fallback);
        state = state.copyWith(queueVersion: state.queueVersion + 1);
      }
      _isFetchingRelated = false;
      await _fetchRelatedQueue(state.currentTrack!);
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex >= 0 &&
        oldIndex < _relatedAutoplayQueue.length &&
        newIndex >= 0 &&
        newIndex <= _relatedAutoplayQueue.length) {
      final item = _relatedAutoplayQueue.removeAt(oldIndex);
      _relatedAutoplayQueue.insert(newIndex, item);
      state = state.copyWith(queueVersion: state.queueVersion + 1);
      debugPrint('🔀 [Queue] Đã đổi vị trí bài hát từ $oldIndex sang $newIndex');
    }
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _relatedAutoplayQueue.length) {
      final removed = _relatedAutoplayQueue.removeAt(index);
      state = state.copyWith(queueVersion: state.queueVersion + 1);
      debugPrint('🗑️ [Queue] Đã xóa khỏi hàng đợi: "${removed.title}"');
    }
  }

  Future<void> playFromQueue(int index) async {
    final visibleQueue = queue;
    if (index < 0 || index >= visibleQueue.length) return;

    final nextTrack = visibleQueue[index];
    // Xóa bài này khỏi _relatedAutoplayQueue để không bị trùng lặp
    _relatedAutoplayQueue.removeWhere((t) => t.id == nextTrack.id);

    debugPrint('▶️ [Queue] Chuyển phát trực tiếp từ hàng đợi: "${nextTrack.title}" - ${nextTrack.artist}');

    // Giữ nguyên toàn bộ hàng đợi còn lại, chỉ cập nhật bài đang phát!
    state = state.copyWith(
      currentTrack: nextTrack,
      status: PlayerStatus.loading,
      queueVersion: state.queueVersion + 1,
    );

    // Tự động tìm thêm bài nối đuôi nếu danh sách còn ít hơn 3 bài
    if (_relatedAutoplayQueue.length < 3) {
      unawaited(_fetchRelatedQueue(nextTrack));
    }

    try {
      await _playTrack(nextTrack);
    } catch (e, stack) {
      debugPrint('❌ [Queue Error] Lỗi khi phát bài "${nextTrack.title}": $e');
      debugPrint('📋 StackTrace:\n$stack');
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Lỗi phát bài: $e',
      );
    }
  }

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------
  List<TrackEntity> get sessionHistory =>
      List.unmodifiable(_sessionHistory);
  List<TrackEntity> get favorites =>
      List.unmodifiable(_favorites);
  List<PlaylistEntity> get playlists =>
      List.unmodifiable(_playlists);
  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);
  ChaosFilter get currentFilter => state.filter;
  Stream<Duration> get positionStream => _audioHandler.positionStream;
  Stream<Duration?> get durationStream => _audioHandler.durationStream;

  // ----------------------------------------------------------
  // Thao tác Playlist (Tạo mới, Thêm bài, Xóa bài, Xóa Playlist)
  // ----------------------------------------------------------
  Future<PlaylistEntity> createPlaylist(String name, {int? colorValue, int? iconCodePoint}) async {
    final cleanName = name.trim().isEmpty ? 'Playlist Mới' : name.trim();
    final playlist = PlaylistEntity(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      createdAt: DateTime.now(),
      colorValue: colorValue ?? 0xFFFF6B2C,
      iconCodePoint: iconCodePoint ?? 0xe4b6,
      tracks: const [],
    );
    _playlists.insert(0, playlist);
    await _historyStorage.savePlaylist(playlist);
    state = state.copyWith(playlistVersion: state.playlistVersion + 1);
    debugPrint('📁 [Playlists] Đã tạo playlist mới: "$cleanName"');
    return playlist;
  }

  Future<void> addTrackToPlaylist(String playlistId, TrackEntity track) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final p = _playlists[index];
      if (!p.tracks.any((t) => t.id == track.id)) {
        final updated = p.copyWith(tracks: [...p.tracks, track]);
        _playlists[index] = updated;
        await _historyStorage.savePlaylist(updated);
        state = state.copyWith(playlistVersion: state.playlistVersion + 1);
        debugPrint('✅ [Playlists] Đã thêm bài "${track.title}" vào playlist "${p.name}"');
      }
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final p = _playlists[index];
      final updated = p.copyWith(tracks: p.tracks.where((t) => t.id != trackId).toList());
      _playlists[index] = updated;
      await _historyStorage.savePlaylist(updated);
      state = state.copyWith(playlistVersion: state.playlistVersion + 1);
      debugPrint('🗑️ [Playlists] Đã xóa bài $trackId khỏi playlist "${p.name}"');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _historyStorage.deletePlaylist(playlistId);
    state = state.copyWith(playlistVersion: state.playlistVersion + 1);
    debugPrint('🗑️ [Playlists] Đã xóa playlist ID: $playlistId');
  }

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
      final idx = state.isShuffleActive
          ? math.Random().nextInt(_relatedAutoplayQueue.length)
          : 0;
      next = _relatedAutoplayQueue.removeAt(idx);
      state = state.copyWith(queueVersion: state.queueVersion + 1);
      debugPrint('📻 [RelatedAutoplay Auto] Tự động chuyển sang bài: "${next.title}" - ${next.artist} (Shuffle: ${state.isShuffleActive})');
      if (_relatedAutoplayQueue.length < 3) {
        unawaited(_fetchRelatedQueue(next));
      }
    } else {
      next = await _getNextRandomTrack();
    }
    if (next != null) {
      if (next.streamUrl == null || LocalHistoryStorage.isUrlExpired(next.streamUrl)) {
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
      if (prev.streamUrl == null || LocalHistoryStorage.isUrlExpired(prev.streamUrl)) {
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
  // Internal: Phát track + nạp streamUrl nếu chưa có hoặc đã hết hạn
  // ----------------------------------------------------------
  Future<void> _playTrack(TrackEntity track) async {
    var resolvedTrack = track;
    final isExpired = LocalHistoryStorage.isUrlExpired(resolvedTrack.streamUrl);
    if (resolvedTrack.streamUrl == null || isExpired) {
      debugPrint('⏳ [Player] Stream URL ${isExpired ? "đã hết hạn" : "chưa có"}, đang lấy URL mới từ Backend: ${track.title} (${track.id})...');
      var fetched = await _musicService.getTrackById(track.id);
      if (fetched == null || fetched.streamUrl == null) {
        debugPrint('⚠️ [Player] ID trực tiếp không tải được stream, thử fallback tìm kiếm: "${track.title}"');
        final cleanTitle = track.title.replaceAll(RegExp(r'[\[\(].*?[\]\)]'), '').trim();
        final searchResults = await _musicService.searchTracks('$cleanTitle ${track.artist}', limit: 3);
        if (searchResults.isNotEmpty) {
          fetched = await _musicService.getTrackById(searchResults.first.id);
        }
      }
      if (fetched != null && fetched.streamUrl != null) {
        resolvedTrack = fetched;
        state = state.copyWith(currentTrack: resolvedTrack);
      } else {
        // Tạm dừng bài cũ để không bị stuck audio bài cũ khi gặp lỗi bài mới
        await _audioHandler.pause();
        throw Exception('Không thể tải URL bài hát "${track.title}"');
      }
    }

    debugPrint('📻 [Player] Đang nạp track "${resolvedTrack.title}" vào AudioHandler...');
    try {
      await _audioHandler.playTrack(resolvedTrack);
    } catch (e) {
      debugPrint('⚠️ [Player] Nạp stream thất bại, thử làm mới stream URL từ Backend: $e');
      final fetched = await _musicService.getTrackById(track.id);
      if (fetched != null && fetched.streamUrl != null) {
        resolvedTrack = fetched;
        state = state.copyWith(currentTrack: resolvedTrack);
        await _audioHandler.playTrack(resolvedTrack);
      } else {
        await _audioHandler.pause();
        rethrow;
      }
    }
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
