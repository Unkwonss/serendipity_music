import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/player_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/chaos_constants.dart';
import '../../../domain/entities/chaos_filter.dart';

// ============================================================
// CHAOS FILTER STUDIO (Serendipity Odyssey Design)
// ============================================================

class ChaosFilterPage extends ConsumerWidget {
  const ChaosFilterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 150),
          physics: const BouncingScrollPhysics(),
          children: [
            // Top Odyssey Header
            _buildHeader(context, notifier),

            const SizedBox(height: 12),

            // Ambient Holographic Glow Aura Card: Chaos Engine v3.0
            _buildChaosEngineHeroCard(
              entropyPercent: entropyPercent,
              entropyLabel: entropyLabel,
              activeCount: activeFilterCount,
              onFlux: () {
                // Roll random filter selection
                notifier.playRandom();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎲 Kích hoạt Flux: Đang quay số ngẫu hứng...')),
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

            // 05. Acoustic Instruments
            _FilterSection(
              number: '05',
              title: 'Acoustic Instruments',
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

            // 06. Sonic Velocity (BPM / Tempo)
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
    );
  }

  Widget _buildHeader(BuildContext context, PlayerNotifier notifier) {
    return Row(
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
                  'CHAOS STUDIO',
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
              const SnackBar(content: Text('Đã khôi phục 100% ngẫu hứng không lọc')),
            );
          },
          icon: const Icon(Icons.restart_alt_rounded,
              color: AppTheme.primary, size: 16),
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
    );
  }

  Widget _buildChaosEngineHeroCard({
    required double entropyPercent,
    required String entropyLabel,
    required int activeCount,
    required VoidCallback onFlux,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 8),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grain_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chaos Engine v3.0',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onFlux,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighest,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.casino_rounded,
                          color: AppTheme.secondary, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'FLUX',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.textPrimary,
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

          const SizedBox(height: 14),

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
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                entropyLabel,
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.primary,
                  fontSize: 11,
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
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      blurRadius: 10,
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

  Widget _buildSynestheticPortalCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1B3D), Color(0xFF1E3C72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.waves_rounded, color: AppTheme.tertiary, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.all_inclusive_rounded,
                        color: AppTheme.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Singularity Stream',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Synthesizing 47 acoustic dimensional vectors',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighest,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.tertiary,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor ?? AppTheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$number. $title',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 14,
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
                fontSize: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 14,
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
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
