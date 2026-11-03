import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../now_playing/now_playing_page.dart';
import '../odyssey/odyssey_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/track_entity.dart';

// ============================================================
// LIBRARY PAGE (SERENDIPITY ODYSSEY VAULT)
// Quản lý: Playlists, Liked Frequencies (Yêu thích) & Constell (Bản đồ sao)
// ============================================================

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  // 0: Playlists, 1: Liked Frequencies, 2: Constell (Bản đồ sao)
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(playerProvider.select((s) => s.favoriteVersion));
    ref.watch(playerProvider.select((s) => s.historyVersion));

    final notifier = ref.watch(playerProvider.notifier);
    final favorites = notifier.favorites;
    final history = notifier.sessionHistory;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Header
            _buildHeader(context),

            const SizedBox(height: 10),

            // 2. Segmented Sub-tabs (Playlists, Liked, Constell)
            _buildSubTabs(favorites.length, history.length),

            const SizedBox(height: 12),

            // 3. Body Content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildPlaylistsTab(context),
                  _buildLikedSongsTab(context, favorites),
                  _buildConstellTab(context, history),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Top Header
  // ----------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
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
                  child: Icon(Icons.auto_stories_rounded,
                      color: Color(0xFF380D00), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIBRARY VAULT',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'PERSONAL AUDIO ARCHIVES',
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

          // Add / Search Icon
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📂 Kho lưu trữ âm nhạc cá nhân đã đồng bộ')),
              );
            },
            icon: const Icon(Icons.cloud_done_rounded,
                color: AppTheme.tertiary, size: 22),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Segmented Sub-tabs
  // ----------------------------------------------------------
  Widget _buildSubTabs(int favoritesCount, int nodesCount) {
    final tabs = [
      {'label': 'Playlists', 'badge': null, 'icon': Icons.playlist_play_rounded},
      {'label': 'Liked Songs', 'badge': '$favoritesCount', 'icon': Icons.favorite_rounded},
      {'label': 'Constell', 'badge': '$nodesCount', 'icon': Icons.hub_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            final item = tabs[index];
            final badge = item['badge'] as String?;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 15,
                          color: isSelected
                              ? const Color(0xFF380D00)
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected
                                ? const Color(0xFF380D00)
                                : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        if (badge != null && badge != '0') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF380D00).withValues(alpha: 0.2)
                                  : AppTheme.surfaceHigh,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.jetBrainsMono(
                                color: isSelected
                                    ? const Color(0xFF380D00)
                                    : AppTheme.secondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Tab 1: Playlists
  // ----------------------------------------------------------
  Widget _buildPlaylistsTab(BuildContext context) {
    final customPlaylists = [
      {
        'title': 'Cyberpunk Odyssey',
        'desc': 'Synthwave, Darksynth & Electronic Pulse',
        'count': '18 tracks',
        'query': 'synthwave cyberpunk electronic music',
        'colors': [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)],
        'icon': Icons.bolt_rounded,
      },
      {
        'title': 'Vietnamese Chill Acoustic',
        'desc': 'Mộc mạc, bình yên, giai điệu thư thái',
        'count': '24 tracks',
        'query': 'vietnamese chill acoustic music',
        'colors': [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
        'icon': Icons.spa_rounded,
      },
      {
        'title': 'Lo-Fi Wormhole',
        'desc': 'Deep Study & Late Night Coding',
        'count': '32 tracks',
        'query': 'lofi hip hop radio beats to relax study to',
        'colors': [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
        'icon': Icons.nightlight_round,
      },
      {
        'title': 'Deep Techno Matrix',
        'desc': '128-135 BPM Underground Rhythm',
        'count': '15 tracks',
        'query': 'deep underground techno club mix',
        'colors': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
        'icon': Icons.graphic_eq_rounded,
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        // Create Playlist Action Card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo Playlist Mới',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tập hợp các bài hát theo sở thích của bạn',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng tạo playlist cá nhân đã sẵn sàng')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceHigh,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                    side: const BorderSide(color: AppTheme.glassBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Tạo ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Section Title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'CURATED PLAYLISTS',
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textHint,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // List of Curated Playlists
        for (final p in customPlaylists)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            ),
            child: InkWell(
              onTap: () {
                ref.read(playerProvider.notifier).playRandom();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NowPlayingPage()),
                );
              },
              child: Row(
                children: [
                  // Playlist Cover Art
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: p['colors'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (p['colors'] as List<Color>).first.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(p['icon'] as IconData, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p['desc'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.music_note_rounded, color: AppTheme.secondary, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              p['count'] as String,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppTheme.secondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Play button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 22),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Tab 2: Liked Songs (Favorites)
  // ----------------------------------------------------------
  Widget _buildLikedSongsTab(BuildContext context, List<TrackEntity> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                ),
                child: const Icon(Icons.favorite_border_rounded,
                    color: AppTheme.textHint, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'CHƯA CÓ BÀI HÁT YÊU THÍCH',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nhấn biểu tượng trái tim ❤️ khi đang nghe nhạc để lưu các bài hát bạn yêu thích vào Thư viện!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        // Warp All Header Bar
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${favorites.length} BÀI HÁT ĐÃ THÍCH',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Phát ngẫu nhiên tất cả bài hát',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF380D00),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  ref.read(playerProvider.notifier).playSpecific(favorites.first);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NowPlayingPage()),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  'Phát tất cả',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

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
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: track.mediumResThumbnail,
                      width: 44,
                      height: 44,
                      memCacheWidth: 100,
                      memCacheHeight: 100,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        width: 44,
                        height: 44,
                        color: AppTheme.surfaceHigh,
                        child: const Icon(Icons.music_note_rounded, color: AppTheme.primary),
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
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
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
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 20),
                    onPressed: () => ref.read(playerProvider.notifier).toggleFavorite(track),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Tab 3: Constell (Bản đồ sao / Odyssey Graph)
  // ----------------------------------------------------------
  Widget _buildConstellTab(BuildContext context, List<TrackEntity> history) {
    // Nhúng trực tiếp màn hình OdysseyPage (Constellation Node Graph)
    return const OdysseyPage();
  }
}
