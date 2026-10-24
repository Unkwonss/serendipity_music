import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/player_provider.dart';
import '../../pages/now_playing/now_playing_page.dart';
import '../../../core/theme/app_theme.dart';

// ============================================================
// DOCKED HOLOGRAPHIC MINI-PLAYER (Serendipity Odyssey Design)
// ============================================================

class MiniPlayerWidget extends ConsumerStatefulWidget {
  const MiniPlayerWidget({super.key});

  @override
  ConsumerState<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends ConsumerState<MiniPlayerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final isPlaying = playerState.status == PlayerStatus.playing;
    final isLoading = playerState.status == PlayerStatus.loading;

    if (isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }

    final notifier = ref.read(playerProvider.notifier);
    final isFav = notifier.isFavorite(track.id);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const NowPlayingPage(),
          transitionsBuilder: (_, animation, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini Spinning Vinyl Record Thumbnail
            AnimatedBuilder(
              animation: _rotationController,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: track.mediumResThumbnail,
                        memCacheWidth: 100,
                        memCacheHeight: 100,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: AppTheme.surfaceHighest,
                          child: const Icon(
                            Icons.album_rounded,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Center Vinyl Pip
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLowest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Track Info & Mini Live Equalizer
            Expanded(
              child: ClipRect(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'NOW PLAYING',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Mini Equalizer Bars
                        if (isPlaying)
                          const _MiniEqualizerBars()
                        else
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppTheme.textHint,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      track.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Micro Controls: Favorite, Play/Pause, Next
            IconButton(
              onPressed: () => notifier.toggleFavorite(track),
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppTheme.primary : AppTheme.textSecondary,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            const SizedBox(width: 4),

            // Play / Pause Circle Button
            GestureDetector(
              onTap: () => notifier.togglePlayPause(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: const Color(0xFF5C1C00),
                          size: 22,
                        ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Next Track Button
            IconButton(
              onPressed: () => notifier.skipToNext(),
              icon: const Icon(
                Icons.skip_next_rounded,
                color: AppTheme.textPrimary,
                size: 24,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// Mini live animated equalizer bars
class _MiniEqualizerBars extends StatefulWidget {
  const _MiniEqualizerBars();

  @override
  State<_MiniEqualizerBars> createState() => _MiniEqualizerBarsState();
}

class _MiniEqualizerBarsState extends State<_MiniEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final val = _anim.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 2,
              height: 4 + (val * 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 1.5),
            Container(
              width: 2,
              height: 9 - (val * 5),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 1.5),
            Container(
              width: 2,
              height: 5 + ((1 - val) * 5),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }
}
