import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/player_provider.dart';
import '../../pages/now_playing/now_playing_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/music_source_interface.dart';
import '../../../domain/entities/track_entity.dart';

// ============================================================
// SEARCH & DISCOVERY PAGE (Serendipity Odyssey Design)
// ============================================================

final _searchResultsProvider =
    StateNotifierProvider<_SearchNotifier, AsyncValue<List<dynamic>>>(
        (ref) => _SearchNotifier(ref.watch(musicServiceProvider)));

class _SearchNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final MusicSourceService _service;
  _SearchNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      debugPrint('🔎 [Search UI] Tìm kiếm: "$clean"');
      final results = await _service.searchTracks(clean);
      state = AsyncValue.data(results);
    } catch (e, st) {
      debugPrint('❌ [Search UI Error] Lỗi khi tìm kiếm "$clean": $e');
      state = AsyncValue.error(e, st);
    }
  }
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _quickFilters = [
    'All',
    'Cyberpunk',
    'Ambient Space',
    'Synthwave 80s',
    'Neo-Tokyo LoFi',
    'Deep Techno',
    'V-Pop Ballad',
    'Rap Việt',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    if (filter == 'All') {
      _controller.clear();
      ref.read(_searchResultsProvider.notifier).search('vietnamese chill acoustic music');
    } else {
      _controller.text = filter;
      ref.read(_searchResultsProvider.notifier).search(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_searchResultsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Odyssey Header
            _buildHeader(),

            // 2. Interactive Search Bar
            _buildSearchInput(),

            const SizedBox(height: 10),

            // 3. Quick Cosmic Filter Chips
            _buildQuickFilters(),

            const SizedBox(height: 8),

            // 4. Results List or Discovery Wormhole Card
            Expanded(
              child: results.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return _buildDiscoveryHeroView();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                    physics: const BouncingScrollPhysics(),
                    itemCount: tracks.length,
                    itemBuilder: (_, i) => _TrackTile(track: tracks[i]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Lỗi kết nối: $e',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Top Odyssey Header
  // ----------------------------------------------------------
  Widget _buildHeader() {
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
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'SERENDIPITY RADAR',
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

          // Right Icons: Sensors Broadcast + Profile Ring
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📡 Telemetry Radar đang quét sóng âm')),
                  );
                },
                icon: const Icon(Icons.sensors_rounded,
                    color: AppTheme.textSecondary, size: 22),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.surfaceLow,
                  child: Icon(Icons.person_rounded,
                      color: AppTheme.textPrimary, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Search Input Bar
  // ----------------------------------------------------------
  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, genres, vibes...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textHint,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (q) =>
                    ref.read(_searchResultsProvider.notifier).search(q),
                onChanged: (v) => setState(() {}),
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: AppTheme.textSecondary, size: 18),
                onPressed: () {
                  _controller.clear();
                  ref.read(_searchResultsProvider.notifier).search('');
                },
              ),
            IconButton(
              icon: const Icon(Icons.graphic_eq_rounded,
                  color: AppTheme.tertiary, size: 18),
              onPressed: () {
                ref.read(playerProvider.notifier).playRandom();
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Quick Cosmic Filter Chips
  // ----------------------------------------------------------
  Widget _buildQuickFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _quickFilters[i];
          final isSelected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () => _onFilterSelected(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected && filter == 'All') ...[
                    const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF380D00), size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filter,
                    style: GoogleFonts.jetBrainsMono(
                      color: isSelected
                          ? const Color(0xFF380D00)
                          : AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // Discovery Hero Wormhole View (Default Empty Screen)
  // ----------------------------------------------------------
  Widget _buildDiscoveryHeroView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
      physics: const BouncingScrollPhysics(),
      children: [
        // Serendipity Wormhole Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
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
                      const SizedBox(width: 6),
                      Text(
                        'SERENDIPITY RADAR',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'FEATURED',
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

              Row(
                children: [
                  // Artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2A1B3D), Color(0xFF44318D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            color: AppTheme.primary.withValues(alpha: 0.8),
                            size: 40,
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Icon(
                              Icons.album_rounded,
                              color: AppTheme.secondary.withValues(alpha: 0.8),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starlight Drift',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Solar Pulse • Interstellar EP',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '128 BPM',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppTheme.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'C# Minor',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppTheme.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '98% Match to Vibe',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      ref.read(playerProvider.notifier).playRandom();
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(
                      'Quick Play',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.equalizer_rounded, color: AppTheme.secondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Recommended Frequencies',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              'SONIC RADAR',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Sample discovery vibe cards
        _buildVibeCard(
          title: 'Hyperion Eclipse',
          artist: 'NOVA7',
          pulses: '2.4M pulses',
          duration: '3:42',
          tag: 'Synthwave',
          onTap: () {
            _controller.text = 'Hyperion Eclipse';
            ref.read(_searchResultsProvider.notifier).search('Hyperion Eclipse');
          },
        ),
        const SizedBox(height: 8),
        _buildVibeCard(
          title: 'Orbital Resonance',
          artist: 'Celestial Grid',
          pulses: 'Rare Find',
          duration: '4:15',
          tag: 'Ambient Wave',
          onTap: () {
            _controller.text = 'Orbital Resonance';
            ref.read(_searchResultsProvider.notifier).search('Orbital Resonance');
          },
        ),
        const SizedBox(height: 8),
        _buildVibeCard(
          title: 'Neon Solitude',
          artist: 'Kuroshio LoFi',
          pulses: 'Hi-Res Audio',
          duration: '5:02',
          tag: 'Neo-Tokyo',
          onTap: () {
            _controller.text = 'Neon Solitude';
            ref.read(_searchResultsProvider.notifier).search('Neon Solitude');
          },
        ),
      ],
    );
  }

  Widget _buildVibeCard({
    required String title,
    required String artist,
    required String pulses,
    required String duration,
    required String tag,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        artist,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text(
                        pulses,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              duration,
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Track Tile Component
// ============================================================

class _TrackTile extends ConsumerWidget {
  final dynamic track;
  const _TrackTile({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TrackEntity trackEntity;
    if (track is TrackEntity) {
      trackEntity = track as TrackEntity;
    } else {
      trackEntity = TrackEntity(
        id: track.id as String,
        title: track.title as String,
        artist: track.artist as String,
        thumbnailUrl: (track.thumbnailUrl ?? '') as String,
        duration: track.duration is Duration
            ? track.duration as Duration
            : Duration(seconds: (track.durationSeconds ?? 180) as int),
      );
    }

    final durationSec = trackEntity.duration.inSeconds;
    final m = (durationSec ~/ 60).toString().padLeft(2, '0');
    final s = (durationSec % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          ref.read(playerProvider.notifier).playSpecific(trackEntity);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NowPlayingPage()),
          );
        },
        child: Row(
          children: [
            // Thumbnail with Play overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: trackEntity.thumbnailUrl,
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
                          color: AppTheme.primary, size: 22),
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
                    trackEntity.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          trackEntity.artist,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

            const SizedBox(width: 4),

            // Favorite button
            IconButton(
              icon: const Icon(Icons.favorite_border_rounded,
                  color: AppTheme.textHint, size: 20),
              onPressed: () {
                ref.read(playerProvider.notifier).toggleFavorite(trackEntity);
              },
            ),
          ],
        ),
      ),
    );
  }
}
