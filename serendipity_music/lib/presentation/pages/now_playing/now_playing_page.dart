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
              _buildTransportControls(isPlaying, isLoading, track),

              const SizedBox(height: 20),

              // 6. Action Chips Row (+PLAYLIST, LYRICS, QUEUE, 1.0x, SLEEP)
              _buildActionChipsRow(playerState.isSleepTimerActive),

              // 7. Active Sleep Timer Card (if active)
              if (playerState.isSleepTimerActive) ...[
                const SizedBox(height: 16),
                _buildSleepTimerActiveCard(),
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceHigh,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Đã thêm "${track.title}" vào Playlist',
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

          // Telemetry Chips: FLAC Lossless + BPM/Key
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
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
                          color: AppTheme.tertiary, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'FLAC Lossless',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.tertiary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: Text(
                    '128 BPM • C# Min',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
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
  Widget _buildTransportControls(bool isPlaying, bool isLoading, TrackEntity track) {
    final notifier = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle Trigger
          IconButton(
            tooltip: 'Shuffle',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚡ Đang ở chế độ ngẫu hứng Odyssey')),
              );
            },
            icon: const Icon(
              Icons.shuffle_rounded,
              color: AppTheme.secondary,
              size: 24,
            ),
          ),

          // Previous Button
          GestureDetector(
            onTap: () => notifier.skipToPrevious(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder, width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(
                Icons.skip_previous_rounded,
                color: AppTheme.textPrimary,
                size: 28,
              ),
            ),
          ),

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
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF380D00),
                        size: 38,
                      ),
              ),
            ),
          ),

          // Next Button
          GestureDetector(
            onTap: () => notifier.skipToNext(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder, width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(
                Icons.skip_next_rounded,
                color: AppTheme.textPrimary,
                size: 28,
              ),
            ),
          ),

          // Repeat Trigger
          IconButton(
            tooltip: 'Repeat',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔁 Lặp lại: Tự động chuyển bài liên quan')),
              );
            },
            icon: const Icon(
              Icons.repeat_rounded,
              color: AppTheme.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Micro Action Pill Row (+PLAYLIST, LYRICS, QUEUE, 1.0x, SLEEP)
  // ----------------------------------------------------------
  Widget _buildActionChipsRow(bool isSleepActive) {
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm bài hát vào Cyberpunk Odyssey')),
                );
              },
            ),
          ),
          const SizedBox(width: 6),

          // LYRICS
          Expanded(
            child: _buildGlassActionChip(
              icon: Icons.lyrics_rounded,
              label: 'LYRICS',
              color: AppTheme.primary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang tải lời bài hát đồng bộ...')),
                );
              },
            ),
          ),
          const SizedBox(width: 6),

          // QUEUE
          Expanded(
            child: _buildGlassActionChip(
              icon: Icons.queue_music_rounded,
              label: 'QUEUE',
              color: AppTheme.tertiary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hàng đợi tự động phát bài liên quan')),
                );
              },
            ),
          ),
          const SizedBox(width: 6),

          // 1.0x
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppTheme.glassBorder, width: 1),
              ),
              child: Text(
                '1.0x',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

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
                      ? AppTheme.primary.withValues(alpha: 0.5)
                      : AppTheme.glassBorder,
                  width: 1,
                ),
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
                    '30m',
                    style: GoogleFonts.jetBrainsMono(
                      color: isSleepActive ? AppTheme.primary : AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
  Widget _buildSleepTimerActiveCard() {
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
      child: Column(
        children: [
          Row(
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
                        'Fades out gently at track end',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '28:14',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gradient Progress Line
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLowest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.8,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => notifier.cancelSleepTimer(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => notifier.setSleepTimer(const Duration(minutes: 15)),
                child: Text(
                  '+15 Min',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SleepTimerSheet(),
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerProvider.notifier);
    final isActive = ref.watch(playerProvider).isSleepTimerActive;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⏱️ Sleep Timer',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isActive)
                TextButton(
                  onPressed: () {
                    notifier.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy hẹn giờ',
                      style: TextStyle(color: AppTheme.error)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // End of track option
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_off_rounded,
                color: AppTheme.primary),
            title: Text(
              'Sau khi hết bài hiện tại',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
            ),
            onTap: () {
              notifier.setSleepTimer(Duration.zero, endOfTrack: true);
              Navigator.pop(context);
            },
          ),

          // Fixed time options
          ...AppConstants.sleepTimerOptions.map((min) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_rounded,
                  color: AppTheme.textSecondary),
              title: Text(
                '$min phút',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
              ),
              onTap: () {
                notifier.setSleepTimer(Duration(minutes: min));
                Navigator.pop(context);
              },
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
