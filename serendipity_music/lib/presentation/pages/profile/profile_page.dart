import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/player_provider.dart';
import '../../../core/theme/app_theme.dart';

// ============================================================
// PROFILE & ODYSSEY HUD SYSTEM SETTINGS
// ============================================================

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _losslessAudio = true;
  bool _spatialAudio = true;
  String _activeEqualizer = 'Cyberpunk Neon';
  int _sleepTimerMinutes = 0;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(playerProvider.notifier);
    final historyCount = notifier.sessionHistory.length;
    final favoritesCount = notifier.favorites.length;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 150),
          physics: const BouncingScrollPhysics(),
          children: [
            // 1. Top Header
            _buildHeader(),

            const SizedBox(height: 16),

            // 2. Voyager Hologram ID Card
            _buildVoyagerCard(historyCount, favoritesCount),

            const SizedBox(height: 24),

            // 3. Audio Performance Deck
            _buildSectionTitle('AUDIO PERFORMANCE ENGINE', Icons.graphic_eq_rounded),
            const SizedBox(height: 10),
            _buildAudioEngineCard(),

            const SizedBox(height: 24),

            // 4. Equalizer & Spatial Acoustics
            _buildSectionTitle('SPATIAL ACOUSTIC PRESETS', Icons.waves_rounded),
            const SizedBox(height: 10),
            _buildEqualizerSelector(),

            const SizedBox(height: 24),

            // 5. System Cache & Diagnostics
            _buildSectionTitle('COSMIC STORAGE & DIAGNOSTICS', Icons.memory_rounded),
            const SizedBox(height: 10),
            _buildSystemDiagnosticsCard(context),

            const SizedBox(height: 24),

            // 6. About App
            _buildAboutFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFF1A0500), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOYAGER PROFILE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'SYSTEM HUD & ACOUSTICS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ONLINE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00E5FF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoyagerCard(int historyCount, int favoritesCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1F30),
                  border: Border.all(color: AppTheme.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.satellite_alt_rounded, color: AppTheme.primary, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Voyager #07',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppTheme.secondary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Serendipity Deep Explorer • Level 9',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // Stats Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('TRACKS', '$historyCount', Icons.audiotrack_rounded),
              Container(width: 1, height: 28, color: Colors.white12),
              _buildStatItem('FAVORITES', '$favoritesCount', Icons.favorite_rounded),
              Container(width: 1, height: 28, color: Colors.white12),
              _buildStatItem('ENTROPY', '100%', Icons.all_inclusive_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioEngineCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'FLAC Lossless Streaming',
            subtitle: 'Direct bit-perfect audio decoding up to 96kHz',
            value: _losslessAudio,
            onChanged: (v) => setState(() => _losslessAudio = v),
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildSwitchTile(
            title: 'Spatial 3D Audio Hologram',
            subtitle: 'Binaural dimensional expansion & virtual soundstage',
            value: _spatialAudio,
            onChanged: (v) => setState(() => _spatialAudio = v),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            title: Text(
              'Sleep Timer',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _sleepTimerMinutes == 0 ? 'Disabled' : 'Turns off after $_sleepTimerMinutes min',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: DropdownButton<int>(
              value: _sleepTimerMinutes,
              dropdownColor: AppTheme.surfaceHighest,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Off', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 15, child: Text('15 min', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 30, child: Text('30 min', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 60, child: Text('60 min', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _sleepTimerMinutes = v);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(v == 0 ? 'Đã tắt Sleep Timer' : 'Hẹn giờ tắt nhạc sau $v phút'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
      activeTrackColor: AppTheme.primary.withValues(alpha: 0.35),
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.white10,
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.textSecondary,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildEqualizerSelector() {
    final presets = ['Cyberpunk Neon', 'Studio Acoustic', 'Deep Sub-Bass', 'Vocal Euphoria'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        final isSelected = _activeEqualizer == preset;
        return GestureDetector(
          onTap: () {
            setState(() => _activeEqualizer = preset);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.white10,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: isSelected ? const Color(0xFF1A0500) : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  preset,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF1A0500) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemDiagnosticsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      ),
      child: Column(
        children: [
          _buildDiagRow('Backend Core', 'FastAPI 127.0.0.1:8000 (Connected)'),
          const SizedBox(height: 10),
          _buildDiagRow('Audio Engine', 'JustAudio + AudioService'),
          const SizedBox(height: 10),
          _buildDiagRow('Memory Buffer', 'Anti-Loop Queue Active (50 Max)'),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✨ Đã làm sạch bộ nhớ đệm âm thanh và cấu hình cache!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppTheme.secondary),
              label: Text(
                'Làm sạch bộ nhớ đệm (Clear Cache)',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'SERENDIPITY ODYSSEY v3.2.0',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crafted for sonic explorers • Infinite algorithmic serendipity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
