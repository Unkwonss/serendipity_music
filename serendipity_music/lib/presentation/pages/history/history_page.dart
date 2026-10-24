import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/player_provider.dart';
import '../now_playing/now_playing_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/track_entity.dart';

// ============================================================
// TIMELINE & SONIC VAULT (Serendipity Odyssey Design)
// ============================================================

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  int _selectedFilter = 0; // 0: Timeline (All Discoveries), 1: Liked Frequencies

  @override
  Widget build(BuildContext context) {
    ref.watch(playerProvider.select((s) => s.historyVersion));
    ref.watch(playerProvider.select((s) => s.favoriteVersion));

    final notifier = ref.watch(playerProvider.notifier);
    final history = notifier.sessionHistory;
    final favorites = notifier.favorites;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Odyssey Header
            _buildHeader(context, history.isNotEmpty),

            const SizedBox(height: 10),

            // Segmented Filter Tabs
            _buildFilterTabs(favorites.length),

            const SizedBox(height: 12),

            // Content Body
            Expanded(
              child: _selectedFilter == 0
                  ? _buildTimelineTab(history)
                  : _buildFavoritesTab(favorites),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Header
  // ----------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool hasHistory) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.all_inclusive_rounded,
                      color: Color(0xFF380D00), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ODYSSEY',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'TIMELINE & VAULT',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (hasHistory)
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surfaceHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppTheme.glassBorder),
                    ),
                    title: Text(
                      'Prune Timeline Cache',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: Text(
                      'Bạn có chắc chắn muốn xóa toàn bộ lịch sử nghe khỏi dòng thời gian?',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Hủy',
                            style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorContainer,
                          foregroundColor: AppTheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Prune All',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(playerProvider.notifier).clearHistory();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLow,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cleaning_services_rounded,
                        color: AppTheme.textSecondary, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'Prune',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.textSecondary,
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

  // ----------------------------------------------------------
  // Segmented Filter Tabs
  // ----------------------------------------------------------
  Widget _buildFilterTabs(int favCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'All Discoveries',
                icon: Icons.all_inclusive_rounded,
                isSelected: _selectedFilter == 0,
                onTap: () => setState(() => _selectedFilter = 0),
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'Liked ($favCount)',
                icon: Icons.favorite_rounded,
                isSelected: _selectedFilter == 1,
                onTap: () => setState(() => _selectedFilter = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF380D00)
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                color: isSelected
                    ? const Color(0xFF380D00)
                    : AppTheme.textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // TAB 1: Timeline (with luminescent spine & glowing node markers)
  // ----------------------------------------------------------
  Widget _buildTimelineTab(List<TrackEntity> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài nào trong dòng thời gian\nHãy nhấn ⚡ để mở cổng ngẫu hứng!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
      physics: const BouncingScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (_, index) {
        final track = history[index];
        return _buildTimelineTile(track, index, history.length);
      },
    );
  }

  Widget _buildTimelineTile(TrackEntity track, int index, int total) {
    final durationSec = track.duration.inSeconds;
    final m = (durationSec ~/ 60).toString().padLeft(2, '0');
    final s = (durationSec % 60).toString().padLeft(2, '0');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Luminescent Spine Column
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Glowing wire line
                Positioned(
                  top: 0,
                  bottom: index == total - 1 ? 26 : 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.8),
                          AppTheme.primary.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Glowing Node Marker
                Positioned(
                  top: 18,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == 0 ? AppTheme.primary : AppTheme.secondary,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (index == 0 ? AppTheme.primary : AppTheme.secondary)
                              .withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Sliding Timeline Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  ref.read(playerProvider.notifier).playSpecific(track);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NowPlayingPage()),
                  );
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Artwork with play overlay
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: track.mediumResThumbnail,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Container(
                                  width: 48,
                                  height: 48,
                                  color: AppTheme.surfaceHigh,
                                  child: const Icon(Icons.music_note_rounded,
                                      color: AppTheme.primary),
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                color: Colors.black.withValues(alpha: 0.25),
                                child: const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 24),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Title & Artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
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

                        const SizedBox(width: 8),

                        // Duration
                        Text(
                          '$m:$s',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Telemetry Meta Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.scatter_plot_rounded,
                                color: AppTheme.primary, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Via Chaos Flow',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppTheme.textHint,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_done_rounded,
                                  color: AppTheme.tertiary, size: 11),
                              const SizedBox(width: 3),
                              Text(
                                'Cached',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppTheme.tertiary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // TAB 2: Liked Frequencies (Feature Card + List)
  // ----------------------------------------------------------
  Widget _buildFavoritesTab(List<TrackEntity> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài hát yêu thích\nNhấn vào biểu tượng ❤️ khi nghe để lưu trữ!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
      physics: const BouncingScrollPhysics(),
      children: [
        // Liked Frequencies Feature Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C1C28), AppTheme.surfaceHigh, AppTheme.surfaceLow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Color(0xFF380D00), size: 26),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHighest,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'VAULT ARCHIVE',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.secondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                'Liked Frequencies',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${favorites.length} Tracks',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: AppTheme.textHint)),
                  const SizedBox(width: 6),
                  Text(
                    'Sonic Resonance Collection',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Animated Soundwave Spectrum Graphics
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in [8, 14, 22, 10, 18, 24, 12, 26, 16, 9, 20, 14, 25, 11])
                    Expanded(
                      child: Container(
                        height: h.toDouble(),
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Warp All Action Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF380D00),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  if (favorites.isNotEmpty) {
                    ref.read(playerProvider.notifier).playSpecific(favorites.first);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NowPlayingPage()),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  'Warp All',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // List of Liked Tracks
        for (final track in favorites)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            ),
            child: InkWell(
              onTap: () {
                ref.read(playerProvider.notifier).playSpecific(track);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NowPlayingPage()),
                );
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: track.mediumResThumbnail,
                      memCacheWidth: 120,
                      memCacheHeight: 120,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.surfaceHigh,
                        child: const Icon(Icons.music_note_rounded,
                            color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
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
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded,
                        color: AppTheme.primary, size: 22),
                    onPressed: () {
                      ref.read(playerProvider.notifier).toggleFavorite(track);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
