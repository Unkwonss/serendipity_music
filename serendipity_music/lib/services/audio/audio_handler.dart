import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import '../../domain/entities/track_entity.dart';

// ============================================================
// AUDIO HANDLER — Tích hợp audio_service + just_audio
// Hỗ trợ: background playback, lock screen controls,
//          sleep timer, audio session configuration
// ============================================================

class SerendipityAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(seconds: 4),
        maxBufferDuration: Duration(seconds: 30),
        bufferForPlaybackDuration: Duration(milliseconds: 400),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 1),
      ),
    ),
  );

  TrackEntity? _currentTrack;
  DateTime? _sleepTimerEnd;

  // Callback để tự động load bài tiếp theo hoặc bài trước
  Future<TrackEntity?> Function()? onRequestNextTrack;
  Future<TrackEntity?> Function()? onRequestPreviousTrack;
  void Function(TrackEntity)? onTrackStarted;

  SerendipityAudioHandler() {
    _init();
  }

  void _init() {
    // Cấu hình Android AudioSession chuyên dụng cho Music
    AudioSession.instance.then((session) {
      session.configure(const AudioSessionConfiguration.music());
    }).catchError((_) {});

    // Đặt mức volume 0.92 để triệt tiêu hoàn toàn hiện tượng digital clipping / rè tiếng
    _player.setVolume(0.92);

    // Lắng nghe trạng thái phát
    _player.playerStateStream.listen(_onPlayerStateChanged);

    // Lắng nghe vị trí hiện tại để kiểm tra sleep timer
    _player.positionStream.listen(_onPositionChanged);

    // Phát broadcast playback state ra audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  // ----------------------------------------------------------
  // Phát bài hát
  // ----------------------------------------------------------
  Future<void> playTrack(TrackEntity track) async {
    _currentTrack = track;

    if (track.streamUrl == null) {
      throw Exception('Stream URL not resolved for track: ${track.id}');
    }

    debugPrint('📡 [AudioHandler] Notification MediaItem: "${track.title}" - ${track.artist}');
    mediaItem.add(_toMediaItem(track));

    // Báo cho UI (PlayerNotifier) cập nhật tên & ảnh bìa bài mới NGAY LẬP TỨC
    onTrackStarted?.call(track);


    // Set audio source và phát nhạc MP3 trực tiếp
    try {
      debugPrint('🌐 [AudioHandler] Nạp URL vào AudioPlayer: "${track.title}"');
      await _player.setUrl(track.streamUrl!);
      debugPrint('▶️ [AudioHandler] Bắt đầu phát...');
      // KHÔNG await _player.play() vì trong just_audio nó sẽ bị treo cho tới khi hết bài!
      _player.play().catchError((e) {
        debugPrint('⚠️ [AudioPlayer] Lỗi trong lúc phát: $e');
      });
      debugPrint('✅ [AudioHandler] Đã gửi lệnh phát nhạc!');
    } catch (e, stack) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('abort') || errStr.contains('cancelled') || errStr.contains('interrupted')) {
        debugPrint('ℹ️ [AudioHandler] Bỏ qua lỗi đổi bài nhanh: $e');
        return;
      }
      debugPrint('❌ [AudioHandler Error] Lỗi khi nạp URL vào Player: $e');
      debugPrint('📋 [AudioHandler StackTrace]:\n$stack');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // Kiểm tra sleep timer
  // ----------------------------------------------------------
  void _onPositionChanged(Duration position) {
    if (_sleepTimerEnd != null && DateTime.now().isAfter(_sleepTimerEnd!)) {
      stop();
      _sleepTimerEnd = null;
      return;
    }
  }

  bool _isChangingTrack = false;

  // ----------------------------------------------------------
  // Xử lý khi bài hát kết thúc → tự động sang bài kế
  // ----------------------------------------------------------
  void _onPlayerStateChanged(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      if (!_isChangingTrack) {
        _isChangingTrack = true;
        skipToNext().whenComplete(() {
          _isChangingTrack = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // Sleep Timer
  // ----------------------------------------------------------
  void setSleepTimer(Duration duration, {bool endOfTrack = false}) {
    if (endOfTrack) {
      // Tắt sau khi phát hết bài hiện tại
      _player.playerStateStream
          .where((s) => s.processingState == ProcessingState.completed)
          .first
          .then((_) => stop());
    } else {
      _sleepTimerEnd = DateTime.now().add(duration);
    }
  }

  void cancelSleepTimer() {
    _sleepTimerEnd = null;
  }

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEnd == null) return null;
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ----------------------------------------------------------
  // BaseAudioHandler overrides (media notification controls)
  // ----------------------------------------------------------
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final next = await onRequestNextTrack?.call();
    if (next != null) await playTrack(next);
  }

  @override
  Future<void> skipToPrevious() async {
    final prev = await onRequestPreviousTrack?.call();
    if (prev != null) {
      await playTrack(prev);
    }
  }

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------
  TrackEntity? get currentTrack => _currentTrack;
  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  MediaItem _toMediaItem(TrackEntity track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      artUri: Uri.parse(track.mediumResThumbnail),
      duration: track.duration,
    );
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
