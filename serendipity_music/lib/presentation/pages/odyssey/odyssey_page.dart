import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphview/GraphView.dart';
import '../../providers/player_provider.dart';
import '../now_playing/now_playing_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/track_entity.dart';

// ============================================================
// ODYSSEY PAGE — BẢN ĐỒ HÀNH TRÌNH CHÒM SAO (CONSTELLATION HUD)
// ============================================================

class OdysseyPage extends ConsumerWidget {
  const OdysseyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(playerProvider.select((s) => s.historyVersion));
    final history = ref.watch(playerProvider.notifier).sessionHistory;
    final currentTrack = ref.watch(playerProvider.select((s) => s.currentTrack));

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'CONSTELLATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'NODE GRAPH',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.secondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'SONIC TRAJECTORY TELEMETRY',
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.textHint,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: history.isEmpty
          ? const _EmptyOdyssey()
          : Column(
              children: [
                _StatsBar(history: history),
                Expanded(
                  child: _OdysseyGraph(
                    history: history,
                    currentTrack: currentTrack,
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// Telemetry Stats Bar
// ============================================================

class _StatsBar extends StatelessWidget {
  final List<TrackEntity> history;
  const _StatsBar({required this.history});

  @override
  Widget build(BuildContext context) {
    final totalDuration = history.fold<Duration>(
      Duration.zero,
      (prev, t) => prev + t.duration,
    );

    final countries = history.map((t) => t.regionCode).whereType<String>().toSet();
    final genres = history.map((t) => t.genre).whereType<String>().toSet();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.graphic_eq_rounded,
            value: '${history.length}',
            label: 'NODES',
            accentColor: AppTheme.primary,
          ),
          Container(width: 1, height: 28, color: AppTheme.glassBorder),
          _StatItem(
            icon: Icons.timer_outlined,
            value: _formatDuration(totalDuration),
            label: 'ELAPSED',
            accentColor: AppTheme.secondary,
          ),
          Container(width: 1, height: 28, color: AppTheme.glassBorder),
          _StatItem(
            icon: Icons.radar_rounded,
            value: '${countries.isEmpty ? 1 : countries.length}',
            label: 'SECTORS',
            accentColor: AppTheme.tertiary,
          ),
          Container(width: 1, height: 28, color: AppTheme.glassBorder),
          _StatItem(
            icon: Icons.grain_rounded,
            value: '${genres.isEmpty ? 1 : genres.length}',
            label: 'GENRES',
            accentColor: const Color(0xFFE040FB),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accentColor, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.textHint,
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Odyssey Node Graph
// ============================================================

class _OdysseyGraph extends StatefulWidget {
  final List<TrackEntity> history;
  final TrackEntity? currentTrack;
  const _OdysseyGraph({required this.history, this.currentTrack});

  @override
  State<_OdysseyGraph> createState() => _OdysseyGraphState();
}

class _OdysseyGraphState extends State<_OdysseyGraph> {
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    _buildGraph();
    builder
      ..siblingSeparation = 40
      ..levelSeparation = 70
      ..subtreeSeparation = 40
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
  }

  @override
  void didUpdateWidget(_OdysseyGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history.length != oldWidget.history.length) {
      _buildGraph();
      setState(() {});
    }
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();
    if (widget.history.length < 2) return;

    final reversed = widget.history.reversed.toList();
    final nodes = <Node>[];
    for (int i = 0; i < reversed.length; i++) {
      final node = Node.Id(i);
      nodes.add(node);
      graph.addNode(node);
    }

    for (int i = 0; i < nodes.length - 1; i++) {
      graph.addEdge(nodes[i], nodes[i + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) return const SizedBox.shrink();

    if (widget.history.length == 1) {
      final single = widget.history.first;
      final isNowPlaying = widget.currentTrack?.id == single.id;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OdysseyNode(
              track: single,
              isCurrent: isNowPlaying,
              index: 1,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                children: [
                  Text(
                    'WARP ORIGIN INITIALIZED',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tiếp tục nghe để mở rộng bản đồ hành trình chòm sao.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final reversed = widget.history.reversed.toList();

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(120),
      minScale: 0.3,
      maxScale: 2.0,
      child: GraphView(
        graph: graph,
        algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
        paint: Paint()
          ..color = AppTheme.tertiary.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final idx = node.key?.value as int?;
          final track = (idx != null && idx >= 0 && idx < reversed.length)
              ? reversed[idx]
              : reversed.first;
          final isCurrent = widget.currentTrack?.id == track.id;
          return _OdysseyNode(
            track: track,
            isCurrent: isCurrent,
            index: (idx ?? 0) + 1,
          );
        },
      ),
    );
  }
}

class _OdysseyNode extends ConsumerWidget {
  final TrackEntity track;
  final bool isCurrent;
  final int index;

  const _OdysseyNode({
    required this.track,
    this.isCurrent = false,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(playerProvider.notifier).playSpecific(track);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NowPlayingPage()),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 86,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceLow.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? AppTheme.primary
                : AppTheme.tertiary.withValues(alpha: 0.3),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrent
                  ? AppTheme.primary.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: isCurrent ? 14 : 8,
              spreadRadius: isCurrent ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#$index',
                  style: GoogleFonts.jetBrainsMono(
                    color: isCurrent ? AppTheme.primary : AppTheme.textHint,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCurrent)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                track.mediumResThumbnail,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 64,
                  height: 64,
                  color: AppTheme.surfaceHigh,
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              track.title,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (track.artist.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                track.artist,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textHint,
                  fontSize: 7,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Empty State
// ============================================================

class _EmptyOdyssey extends StatelessWidget {
  const _EmptyOdyssey();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceLow.withValues(alpha: 0.6),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.blur_on_rounded,
              size: 56,
              color: AppTheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'BẢN ĐỒ CHÒM SAO ĐANG CHỜ TÍN HIỆU',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Khởi chạy bài hát bất kỳ từ Chaos Engine hoặc Search để hình thành các điểm nút du hành.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
