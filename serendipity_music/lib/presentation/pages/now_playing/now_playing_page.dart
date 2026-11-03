import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/player_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/track_entity.dart';

// ============================================================
// NOW PLAYING HUD (Serendipity Odyssey Design)
// Cyber-dark cosmic vinyl deck with high-fidelity telemetry HUD
// ============================================================

class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vinylController;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;

    if (track == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textPrimary, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Chưa có bài nào đang phát\nHãy chọn bài hát hoặc nhấn ⚡ để bắt đầu!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final isPlaying = playerState.status == PlayerStatus.playing;
    final isLoading = playerState.status == PlayerStatus.loading;

    if (isPlaying) {
      if (!_vinylController.isAnimating) {
        _vinylController.repeat();
      }
    } else {
      _vinylController.stop();
    }

    ref.watch(playerProvider.select((s) => s.favoriteVersion));

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // 1. Top HUD Bar
              _buildTopHudBar(context),

              const SizedBox(height: 12),

              // 2. Cosmic Spinning Vinyl Record with Tonearm
              _buildCosmicVinylDeck(track, isPlaying),

              const SizedBox(height: 20),

              // 3. Track Info + Actions + Telemetry Chips
              _buildTrackInfoAndTelemetry(track),

              const SizedBox(height: 18),

              // 4. Interactive Audio Scrubber & Timestamps
              _buildAudioScrubber(),

              const SizedBox(height: 16),

              // 5. Playback Transport Controls
              _buildTransportControls(isPlaying, isLoading, track, playerState.isRepeatActive),

              const SizedBox(height: 20),

              // 6. Action Chips Row (+PLAYLIST, QUEUE, 1.0x, SLEEP)
              _buildActionChipsRow(track, playerState),

              // 7. Active Sleep Timer Card (if active)
              if (playerState.isSleepTimerActive) ...[
                const SizedBox(height: 16),
                _buildSleepTimerActiveCard(playerState.sleepTimerLabel),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Top HUD Bar
  // ----------------------------------------------------------
  Widget _buildTopHudBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minimize Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder, width: 1),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textPrimary,
                size: 24,
              ),
            ),
          ),

          // Playing From Center Badge
          Column(
            children: [
              Text(
                'PLAYING FROM',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chaos Engine',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 3D ATMOS Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.spatial_audio_rounded,
                    color: AppTheme.secondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  '3D ATMOS',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.secondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Cosmic Vinyl Deck with Tonearm
  // ----------------------------------------------------------
  Widget _buildCosmicVinylDeck(TrackEntity track, bool isPlaying) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Radial Nebula Aura
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppTheme.tertiary.withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Vinyl Turntable Base & Grooved Disc
          AnimatedBuilder(
            animation: _vinylController,
            builder: (_, child) {
              return Transform.rotate(
                angle: _vinylController.value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF22222D),
                    Color(0xFF15151C),
                    Color(0xFF0D0D12),
                    Color(0xFF1A1A24),
                    Color(0xFF0B0B10),
                  ],
                  stops: [0.0, 0.35, 0.6, 0.72, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.9),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Concentric Vinyl Soundwave Grooves
                  for (double r = 40; r <= 120; r += 16)
                    Container(
                      width: r * 2,
                      height: r * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.04),
                          width: 1,
                        ),
                      ),
                    ),

                  // Center Label with Album Art
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CachedNetworkImage(
                              imageUrl: track.highResThumbnail,
                              memCacheWidth: 200,
                              memCacheHeight: 200,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                color: AppTheme.surfaceHigh,
                                child: const Icon(Icons.album_rounded,
                                    color: Colors.white),
                              ),
                            ),
                            // Semi-transparent center overlay with ODYSSEY logo
                            Container(
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                            // Center Spindle Hole
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppTheme.bgDeep,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sleek Stylized Tonearm (Cần kim xoay vào trong đè lên đĩa khi Play, về bệ nghỉ khi Pause)
          Positioned(
            top: 6,
            right: 28,
            child: SizedBox(
              width: 90,
              height: 165,
              child: Stack(
                children: [
                  // 1. Moving Arm + Cartridge (Xoay quanh tâm Base Pivot)
                  Positioned(
                    top: 16,
                    right: 0,
                    width: 32,
                    height: 145,
                    child: AnimatedRotation(
                      // SỐ DƯƠNG (0.075 vòng = +27 độ): Cần kim quét sang TRÁI đè ngay lên mặt đĩa than khi Play!
                      // 0.0 vòng: Cần kim thẳng đứng ở ngoài đĩa khi Pause!
                      turns: isPlaying ? 0.075 : 0.0,
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Arm Wire
                          Container(
                            width: 3,
                            height: 105,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.textOutline,
                                  AppTheme.secondaryFixed,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Cartridge Head (Đầu kim đè lên đĩa than)
                          Positioned(
                            top: 108,
                            child: Container(
                              width: 16,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 2,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.tertiary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Fixed Base Pivot (Trục tròn cố định sang trọng)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.outlineVariant,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.bgDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Track Title + Actions + Telemetry Chips
  // ----------------------------------------------------------
  Widget _buildTrackInfoAndTelemetry(TrackEntity track) {
    final notifier = ref.read(playerProvider.notifier);
    final isFav = notifier.isFavorite(track.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Artist + Actions (Playlist, Favorite)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.02,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.artist,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppTheme.secondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Add to Playlist Button
              GestureDetector(
                onTap: () => _showAddToPlaylistSheet(context, track),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.glassBorder, width: 1),
                  ),
                  child: const Icon(
                    Icons.playlist_add_rounded,
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Heart Favorite Button
              GestureDetector(
                onTap: () async {
                  await notifier.toggleFavorite(track);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceHigh,
                      content: Text(
                        isFav
                            ? '💔 Đã xóa khỏi mục Yêu thích'
                            : '❤️ Đã lưu bài hát vào mục Yêu thích!',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.glassBorder, width: 1),
                    boxShadow: isFav
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppTheme.primary : AppTheme.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Telemetry Chip: BPM / Acoustic Key
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq_rounded,
                    color: AppTheme.primary, size: 14),
                const SizedBox(width: 5),
                Text(
                  '128 BPM • C# Min',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Interactive Audio Scrubber & Timestamps
  // ----------------------------------------------------------
  Widget _buildAudioScrubber() {
    final notifier = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<Duration>(
        stream: notifier.positionStream,
        builder: (_, posSnap) {
          return StreamBuilder<Duration?>(
            stream: notifier.durationStream,
            builder: (_, durSnap) {
              final position = posSnap.data ?? Duration.zero;
              final duration = durSnap.data ?? Duration.zero;
              final remaining = duration > position ? duration - position : Duration.zero;

              final progress = duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0.0;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.surfaceHighest,
                      trackHeight: 4,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                        elevation: 4,
                      ),
                      overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (v) {
                        final seekTo = Duration(
                          milliseconds: (v * duration.inMilliseconds).round(),
                        );
                        notifier.seek(seekTo);
                      },
                    ),
                  ),

                  // Timestamps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(position),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '-${_fmt(remaining)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // Transport Playback Controls
  // ----------------------------------------------------------
  Widget _buildTransportControls(
    bool isPlaying,
    bool isLoading,
    TrackEntity track,
    bool isRepeatActive,
  ) {
    final notifier = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Repeat Toggle Button (Nút lặp lại Bật/Tắt sáng/tối)
          GestureDetector(
            onTap: () async {
              await notifier.toggleRepeat();
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surfaceHigh,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  content: Row(
                    children: [
                      Icon(
                        !isRepeatActive
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: !isRepeatActive
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        !isRepeatActive
                            ? '🔁 Đã BẬT lặp lại bài hát (Loop ON)'
                            : '➡️ Đã TẮT lặp lại (Loop OFF)',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isRepeatActive
                    ? AppTheme.primary.withValues(alpha: 0.22)
                    : AppTheme.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRepeatActive
                      ? AppTheme.primary
                      : AppTheme.glassBorder,
                  width: isRepeatActive ? 1.8 : 1,
                ),
                boxShadow: isRepeatActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.55),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isRepeatActive
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    key: ValueKey<bool>(isRepeatActive),
                    color: isRepeatActive
                        ? AppTheme.primary
                        : const Color(0xFF6B6B80),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 28),

          // Hero Play/Pause Button (72px)
          GestureDetector(
            onTap: () => notifier.togglePlayPause(),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.55),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFF380D00),
                        size: 38,
                      ),
              ),
            ),
          ),

          const SizedBox(width: 28),

          // Next Button (54px)
          GestureDetector(
            onTap: () => notifier.skipToNext(),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.skip_next_rounded,
                color: AppTheme.textPrimary,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Micro Action Pill Row (+PLAYLIST, QUEUE, 1.0x, SLEEP)
  // ----------------------------------------------------------
  Widget _buildActionChipsRow(TrackEntity track, PlayerState playerState) {
    final isSleepActive = playerState.isSleepTimerActive;
    final sleepLabel = playerState.sleepTimerLabel ?? 'Sleep';
    final speedLabel = '${playerState.playbackSpeed}x';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // + PLAYLIST
          Expanded(
            child: _buildGlassActionChip(
              icon: Icons.playlist_add_rounded,
              label: '+ PLAYLIST',
              color: AppTheme.primary,
              onTap: () => _showAddToPlaylistSheet(context, track),
            ),
          ),
          const SizedBox(width: 8),

          // QUEUE
          Expanded(
            child: _buildGlassActionChip(
              icon: Icons.queue_music_rounded,
              label: 'QUEUE',
              color: AppTheme.tertiary,
              onTap: () => _showQueueSheet(context),
            ),
          ),
          const SizedBox(width: 8),

          // SPEED (1.0x, 1.25x...)
          GestureDetector(
            onTap: () => _showSpeedSelectorSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: playerState.playbackSpeed != 1.0
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: playerState.playbackSpeed != 1.0
                      ? AppTheme.primary
                      : AppTheme.glassBorder,
                  width: 1,
                ),
              ),
              child: Text(
                speedLabel,
                style: GoogleFonts.jetBrainsMono(
                  color: playerState.playbackSpeed != 1.0
                      ? AppTheme.primary
                      : AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // SLEEP TIMER
          GestureDetector(
            onTap: () => _showSleepTimerDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSleepActive
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isSleepActive
                      ? AppTheme.primary.withValues(alpha: 0.6)
                      : AppTheme.glassBorder,
                  width: 1,
                ),
                boxShadow: isSleepActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bedtime_rounded,
                    color: isSleepActive ? AppTheme.primary : AppTheme.secondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSleepActive ? sleepLabel : 'Sleep',
                    style: GoogleFonts.jetBrainsMono(
                      color: isSleepActive ? AppTheme.primary : AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Sleep Timer Active Card
  // ----------------------------------------------------------
  Widget _buildSleepTimerActiveCard(String? label) {
    final notifier = ref.read(playerProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
                  color: AppTheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Timer Active',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Tự động tắt sau: ${label ?? "Active"}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => notifier.cancelSleepTimer(),
            icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.error),
            label: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Modals & BottomSheets
  // ----------------------------------------------------------
  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const _SleepTimerSheet(),
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, TrackEntity track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _AddToPlaylistModal(track: track),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => const _QueueModal(),
    );
  }

  void _showSpeedSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const _SpeedSelectorModal(),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ============================================================
// Sleep Timer Bottom Sheet
// ============================================================

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final isActive = playerState.isSleepTimerActive;
    final currentLabel = playerState.sleepTimerLabel;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: const BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Hẹn giờ tắt nhạc (Sleep Timer)',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (isActive)
                TextButton(
                  onPressed: () {
                    notifier.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy', style: TextStyle(color: AppTheme.error)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // End of track option
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              currentLabel == 'End' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: currentLabel == 'End' ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            title: Text(
              'Sau khi hết bài hiện tại',
              style: GoogleFonts.plusJakartaSans(
                color: currentLabel == 'End' ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: currentLabel == 'End' ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            onTap: () {
              notifier.setSleepTimer(Duration.zero, endOfTrack: true);
              Navigator.pop(context);
            },
          ),

          // Fixed time options
          ...AppConstants.sleepTimerOptions.map((min) {
            final label = '${min}m';
            final isSelected = currentLabel == label;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 20,
              ),
              title: Text(
                '$min phút',
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              onTap: () {
                notifier.setSleepTimer(Duration(minutes: min));
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// Add to Playlist Bottom Sheet
// ============================================================

class _AddToPlaylistModal extends StatefulWidget {
  final TrackEntity track;
  const _AddToPlaylistModal({required this.track});

  @override
  State<_AddToPlaylistModal> createState() => _AddToPlaylistModalState();
}

class _AddToPlaylistModalState extends State<_AddToPlaylistModal> {
  final List<Map<String, dynamic>> _playlists = [
    {
      'name': 'Cyberpunk Odyssey',
      'count': 18,
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFFF6B2C),
    },
    {
      'name': 'Vietnamese Chill Acoustic',
      'count': 24,
      'icon': Icons.park_rounded,
      'color': const Color(0xFF00E5FF),
    },
    {
      'name': 'Neo-Tokyo Midnight LoFi',
      'count': 15,
      'icon': Icons.nights_stay_rounded,
      'color': const Color(0xFFE040FB),
    },
    {
      'name': 'Deep Focus Ambient',
      'count': 12,
      'icon': Icons.spa_rounded,
      'color': const Color(0xFFFFB74D),
    },
    {
      'name': 'Vocal Euphoria',
      'count': 9,
      'icon': Icons.mic_rounded,
      'color': const Color(0xFF00E676),
    },
  ];

  void _createNewPlaylist() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tạo Playlist mới',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tên playlist...',
            hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.glassBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: const Color(0xFF1A0500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _selectPlaylist(name);
              }
            },
            child: Text('Tạo & Thêm', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _selectPlaylist(String name) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceHigh,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã thêm "${widget.track.title}" vào Playlist "$name"',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.playlist_add_rounded, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm vào Playlist',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            widget.track.title,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Create new playlist button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _createNewPlaylist,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tạo Playlist mới...',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Playlists list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: _playlists.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final p = _playlists[i];
                final pColor = p['color'] as Color;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _selectPlaylist(p['name'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: pColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(p['icon'] as IconData, color: pColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${p['count']} bài hát',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle_outline_rounded,
                            color: AppTheme.textSecondary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Queue Bottom Sheet (Reorderable List)
// ============================================================

class _QueueModal extends ConsumerStatefulWidget {
  const _QueueModal();

  @override
  ConsumerState<_QueueModal> createState() => _QueueModalState();
}

class _QueueModalState extends ConsumerState<_QueueModal> {
  @override
  void initState() {
    super.initState();
    _loadInitialQueue();
  }

  Future<void> _loadInitialQueue() async {
    await ref.read(playerProvider.notifier).ensureQueueLoaded();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(playerProvider.select((s) => s.queueVersion));
    final playerState = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final currentTrack = playerState.currentTrack;
    final queue = notifier.queue;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.queue_music_rounded, color: AppTheme.tertiary, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HÀNG ĐỢI PHÁT (QUEUE)',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Kéo giữ biểu tượng ☰ để thay đổi thứ tự phát',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Now Playing Card
          if (currentTrack != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: currentTrack.thumbnailUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 48,
                          height: 48,
                          color: AppTheme.surfaceLowest,
                          child: const Icon(Icons.music_note_rounded, color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ĐANG PHÁT',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A0500),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.waves_rounded, color: AppTheme.primary, size: 14),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            currentTrack.title,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentTrack.artist,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Section Title: TIẾP THEO
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TIẾP THEO (${queue.length} BÀI HÁT)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Auto-DJ Playlist',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Reorderable Queue List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Đang nạp các bài hát liên quan...',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: queue.length,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      notifier.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (ctx, i) {
                      final track = queue[i];
                      return Container(
                        key: ValueKey('${track.id}_$i'),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            // Reorder Drag Handle
                            ReorderableDragStartListener(
                              index: i,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.drag_handle_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: track.thumbnailUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  width: 40,
                                  height: 40,
                                  color: AppTheme.surfaceLowest,
                                  child: const Icon(Icons.music_note_rounded, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Title & Artist
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    track.artist,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Play immediately
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primary, size: 24),
                              tooltip: 'Phát bài này ngay',
                              onPressed: () {
                                notifier.playFromQueue(i);
                                Navigator.pop(context);
                              },
                            ),

                            // Delete from queue
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                              tooltip: 'Xóa khỏi hàng đợi',
                              onPressed: () => notifier.removeFromQueue(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Speed Selector Bottom Sheet
// ============================================================

class _SpeedSelectorModal extends ConsumerWidget {
  const _SpeedSelectorModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSpeed = ref.watch(playerProvider.select((s) => s.playbackSpeed));
    final notifier = ref.read(playerProvider.notifier);
    final speeds = [
      {'speed': 0.5, 'label': '0.5x (Rất chậm)'},
      {'speed': 0.75, 'label': '0.75x (Chậm)'},
      {'speed': 1.0, 'label': '1.0x (Tiêu chuẩn)'},
      {'speed': 1.25, 'label': '1.25x (Nhanh nhẹ)'},
      {'speed': 1.5, 'label': '1.5x (Nhanh)'},
      {'speed': 1.75, 'label': '1.75x (Rất nhanh)'},
      {'speed': 2.0, 'label': '2.0x (Gấp đôi)'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Tốc độ phát nhạc',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...speeds.map((s) {
            final val = s['speed'] as double;
            final isSelected = (currentSpeed - val).abs() < 0.05;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 20,
              ),
              title: Text(
                s['label'] as String,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                notifier.setPlaybackSpeed(val);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
