import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/player_provider.dart';
import '../now_playing/now_playing_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/chaos_constants.dart';
import '../../../domain/entities/chaos_filter.dart';

// ============================================================
// CHAOS FILTER MODAL / PAGE (Serendipity Odyssey Design)
// ============================================================

class ChaosFilterPage extends ConsumerStatefulWidget {
  final bool isModal;
  const ChaosFilterPage({super.key, this.isModal = true});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => const ChaosFilterPage(isModal: true),
    );
  }

  @override
  ConsumerState<ChaosFilterPage> createState() => _ChaosFilterPageState();
}

class _ChaosFilterPageState extends ConsumerState<ChaosFilterPage> {
  bool _isIgniting = false;

  Future<void> _igniteStream() async {
    if (_isIgniting) return;
    setState(() => _isIgniting = true);

    final notifier = ref.read(playerProvider.notifier);
    try {
      await notifier.playRandom();
      if (!mounted) return;

      final playerState = ref.read(playerProvider);
      if (playerState.status == PlayerStatus.error && playerState.currentTrack == null) {
        setState(() => _isIgniting = false);
        return;
      }

      // Đóng modal lọc và chuyển ngay sang màn hình NowPlaying
      if (widget.isModal && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NowPlayingPage()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isIgniting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceHigh,
            content: Text('Lỗi kích hoạt: $e', style: const TextStyle(color: AppTheme.error)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(playerProvider.select((s) => s.filter));
    final notifier = ref.read(playerProvider.notifier);

    // Tính toán mức Entropy dựa trên số bộ lọc đang bật
    int activeFilterCount = 0;
    if (filter.genre != null) activeFilterCount++;
    if (filter.mood != null) activeFilterCount++;
    if (filter.decade != null) activeFilterCount++;
    if (filter.regionCode != null) activeFilterCount++;
    if (filter.language != null) activeFilterCount++;
    if (filter.instrument != null) activeFilterCount++;
    if (filter.tempo != null) activeFilterCount++;

    final double entropyPercent = activeFilterCount == 0
        ? 1.0 // 100% Chaos ngẫu nhiên tuyệt đối
        : (1.0 - (activeFilterCount * 0.12)).clamp(0.2, 0.95);

    final String entropyLabel = activeFilterCount == 0
        ? '100% [Pure Serendipity]'
        : '${(entropyPercent * 100).round()}% [Focused Odyssey]';

    final sheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: widget.isModal ? sheetHeight : double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: widget.isModal
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.zero,
        border: widget.isModal
            ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1)
            : null,
        boxShadow: widget.isModal
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 36,
                  offset: const Offset(0, -8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Drag handle pill (chỉ hiện khi là modal)
          if (widget.isModal)
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

          // Header
          _buildHeader(context, notifier),

          const Divider(color: Colors.white12, height: 1),

          // Filter Sections List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Chaos Engine Hero Card
                _buildChaosEngineHeroCard(
                  entropyPercent: entropyPercent,
                  entropyLabel: entropyLabel,
                  activeCount: activeFilterCount,
                  onFlux: () {
                    // FLUX: Reset hoặc xáo trộn ngẫu nhiên
                    notifier.updateFilter(ChaosFilter.empty);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎲 Kích hoạt Flux: Đặt lại 100% Serendipity tự do!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 01. Audio Spectrums (Genres)
                _FilterSection(
                  number: '01',
                  title: 'Audio Spectrums',
                  icon: Icons.category_rounded,
                  selectedBadge: filter.genre != null ? '1 Selected' : null,
                  child: _ChipSelector(
                    options: ChaosConstants.genres,
                    selected: filter.genre,
                    onSelect: (v) => notifier.updateFilter(filter.copyWith(genre: v)),
                    onClear: () => notifier.updateFilter(filter.clearField('genre')),
                  ),
                ),

                // 02. Somatic States (Moods)
                _FilterSection(
                  number: '02',
                  title: 'Somatic States',
                  icon: Icons.psychology_rounded,
                  iconColor: AppTheme.secondary,
                  selectedBadge: filter.mood != null ? 'Active' : null,
                  child: _ChipSelectorMap(
                    options: ChaosConstants.moods,
                    selected: filter.mood,
                    onSelect: (k) => notifier.updateFilter(filter.copyWith(mood: k)),
                    onClear: () => notifier.updateFilter(filter.clearField('mood')),
                  ),
                ),

                // Synesthetic Portal Card
                _buildSynestheticPortalCard(),

                const SizedBox(height: 20),

                // 03. Temporal Horizon (Decades)
                _FilterSection(
                  number: '03',
                  title: 'Temporal Horizon',
                  icon: Icons.history_toggle_off_rounded,
                  iconColor: AppTheme.tertiary,
                  selectedBadge: filter.decade != null ? 'Active' : null,
                  child: _ChipSelectorMap(
                    options: ChaosConstants.decades,
                    selected: filter.decade,
                    onSelect: (k) => notifier.updateFilter(filter.copyWith(decade: k)),
                    onClear: () => notifier.updateFilter(filter.clearField('decade')),
                  ),
                ),

                // 04. Sonic Terrains (Regions)
                _FilterSection(
                  number: '04',
                  title: 'Sonic Terrains',
                  icon: Icons.public_rounded,
                  iconColor: AppTheme.secondary,
                  selectedBadge: filter.regionCode != null ? 'Active' : null,
                  child: _ChipSelectorMap(
                    options: ChaosConstants.regions,
                    selected: filter.regionCode,
                    displayKeys: true,
                    onSelect: (k) => notifier.updateFilter(filter.copyWith(regionCode: k)),
                    onClear: () => notifier.updateFilter(filter.clearField('regionCode')),
                  ),
                ),

                // 05. Acoustic Machinery (Instruments)
                _FilterSection(
                  number: '05',
                  title: 'Acoustic Machinery',
                  icon: Icons.piano_rounded,
                  selectedBadge: filter.instrument != null ? 'Active' : null,
                  child: _ChipSelectorMap(
                    options: ChaosConstants.instruments,
                    selected: filter.instrument,
                    displayKeys: true,
                    onSelect: (k) => notifier.updateFilter(filter.copyWith(instrument: k)),
                    onClear: () => notifier.updateFilter(filter.clearField('instrument')),
                  ),
                ),

                // 06. Sonic Velocity (Tempo / BPM)
                _FilterSection(
                  number: '06',
                  title: 'Sonic Velocity (Tempo)',
                  icon: Icons.speed_rounded,
                  iconColor: AppTheme.primary,
                  selectedBadge: filter.tempo != null ? 'Active' : null,
                  child: _ChipSelectorMap(
                    options: ChaosConstants.tempos,
                    selected: filter.tempo,
                    displayKeys: true,
                    onSelect: (k) => notifier.updateFilter(filter.copyWith(tempo: k)),
                    onClear: () => notifier.updateFilter(filter.clearField('tempo')),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Action Bar: [ 🚀 Ignite Chaos Stream ]
          _buildIgniteActionBar(activeFilterCount),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayerNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.isModal && Navigator.of(context).canPop())
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt_rounded, color: Color(0xFF380D00), size: 20),
                  ),
                ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ODYSSEY CHAOS',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'CHAOS ENGINE FILTER',
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
          TextButton.icon(
            onPressed: () {
              notifier.updateFilter(ChaosFilter.empty);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã khôi phục 100% ngẫu hứng không lọc'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.restart_alt_rounded, color: AppTheme.primary, size: 16),
            label: Text(
              'Reset',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaosEngineHeroCard({
    required double entropyPercent,
    required String entropyLabel,
    required int activeCount,
    required VoidCallback onFlux,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
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
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grain_rounded, color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chaos Engine v3.0',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onFlux,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighest,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.casino_rounded, color: AppTheme.secondary, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'FLUX',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
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
                  const SizedBox(width: 6),
                  Text(
                    'Entropy Level',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              Text(
                entropyLabel,
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLowest,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: entropyPercent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSynestheticPortalCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1B3D), Color(0xFF1E3C72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.waves_rounded, color: AppTheme.tertiary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.all_inclusive_rounded, color: AppTheme.primary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Singularity Stream',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Synthesizing acoustic dimensions',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighest,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.tertiary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIgniteActionBar(int activeFilterCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xF212131A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B2C),
              foregroundColor: const Color(0xFF1A0500),
              elevation: 8,
              shadowColor: const Color(0xFFFF6B2C).withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: _isIgniting ? null : _igniteStream,
            child: _isIgniting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A0500),
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Đang tìm kiếm bài hát...',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: const Color(0xFF1A0500),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 22, color: Color(0xFF1A0500)),
                      const SizedBox(width: 8),
                      Text(
                        'Ignite Chaos Stream',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF1A0500),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activeFilterCount == 0 ? 'Pure Chaos' : '$activeFilterCount Filter',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A0500),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Filter Section Wrapper
// ============================================================

class _FilterSection extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? selectedBadge;
  final Widget child;

  const _FilterSection({
    required this.number,
    required this.title,
    required this.icon,
    this.iconColor,
    this.selectedBadge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor ?? AppTheme.primary, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '$number. $title',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (selectedBadge != null)
                Text(
                  selectedBadge!,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.secondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// Chip Selector for List<String>
// ============================================================

class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;
  final VoidCallback onClear;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => isSelected ? onClear() : onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
                        color: AppTheme.primary.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              opt,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// Chip Selector for Map<String, String>
// ============================================================

class _ChipSelectorMap extends StatelessWidget {
  final Map<String, String> options;
  final String? selected;
  final void Function(String) onSelect;
  final VoidCallback onClear;
  final bool displayKeys;

  const _ChipSelectorMap({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onClear,
    this.displayKeys = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final key = entry.key;
        final label = entry.value;
        final isSelected = selected == key;

        return GestureDetector(
          onTap: () => isSelected ? onClear() : onSelect(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
                        color: AppTheme.primary.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              displayKeys ? '$key - $label' : label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
