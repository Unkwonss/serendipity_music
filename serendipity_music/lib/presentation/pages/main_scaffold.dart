import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/player_provider.dart';
import '../pages/search/search_page.dart';
import '../pages/library/library_page.dart';
import '../pages/history/history_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/chaos_filter/chaos_filter_page.dart';
import '../widgets/mini_player/mini_player_widget.dart';
import '../../core/theme/app_theme.dart';

// ============================================================
// MAIN SCAFFOLD — Serendipity Odyssey Floating HUD Navigation
// ============================================================

final _currentTabProvider = StateProvider<int>((ref) => 0);
final _loadedTabsProvider = StateProvider<Set<int>>((ref) => {0});

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PlayerState>(playerProvider, (previous, next) {
      if (next.status == PlayerStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceHigh,
            content: Text(
              'Lỗi: ${next.errorMessage}',
              style: const TextStyle(color: AppTheme.error),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final currentTab = ref.watch(_currentTabProvider);
    final loadedTabs = ref.watch(_loadedTabsProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main Content Stack (Lazy Loaded: Chỉ dựng các trang khi người dùng chuyển sang)
          Positioned.fill(
            child: IndexedStack(
              index: _getPageIndex(currentTab),
              children: [
                const SearchPage(), // 0: Discover
                loadedTabs.contains(1)
                    ? const LibraryPage() // 1: Library (Playlists, Liked, Constell)
                    : const SizedBox.shrink(),
                loadedTabs.contains(2)
                    ? const HistoryPage() // 2: Timeline
                    : const SizedBox.shrink(),
                loadedTabs.contains(3)
                    ? const ProfilePage() // 3: Profile & Settings HUD
                    : const SizedBox.shrink(),
              ],
            ),
          ),

          // Floating Bottom Deck: MiniPlayer + Floating HUD Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Docked Mini Player
                  if (playerState.currentTrack != null)
                    const MiniPlayerWidget(),

                  const SizedBox(height: 4),

                  // Floating Navigation HUD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildFloatingDock(context, ref, currentTab),
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

  int _getPageIndex(int tab) {
    switch (tab) {
      case 0:
        return 0; // Discover / Search
      case 1:
        return 1; // Library (Playlists, Liked, Constell)
      case 2:
        return 2; // Timeline / History
      case 3:
        return 3; // Profile & System Settings
      default:
        return 0;
    }
  }

  Widget _buildFloatingDock(
      BuildContext context, WidgetRef ref, int currentTab) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xF0151520),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 0: Discover
          _NavItem(
            icon: Icons.explore_rounded,
            label: 'Discover',
            index: 0,
            currentIndex: currentTab,
            onTap: () {
              ref.read(_currentTabProvider.notifier).state = 0;
            },
          ),

          // 1: Library (Playlists, Liked, Constell)
          _NavItem(
            icon: Icons.auto_stories_rounded,
            label: 'Library',
            index: 1,
            currentIndex: currentTab,
            onTap: () {
              ref.read(_currentTabProvider.notifier).state = 1;
              ref.read(_loadedTabsProvider.notifier).update((s) => {...s, 1});
            },
          ),

          // Center: ⚡ Raised Serendipity Warp Hero Button (Mở Chaos Filter Modal)
          _CenterChaosEngineButton(
            onTap: () => ChaosFilterPage.show(context),
          ),

          // 2: Timeline / History
          _NavItem(
            icon: Icons.history_rounded,
            label: 'Timeline',
            index: 2,
            currentIndex: currentTab,
            onTap: () {
              ref.read(_currentTabProvider.notifier).state = 2;
              ref.read(_loadedTabsProvider.notifier).update((s) => {...s, 2});
            },
          ),

          // 3: Profile & Settings
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            index: 3,
            currentIndex: currentTab,
            onTap: () {
              ref.read(_currentTabProvider.notifier).state = 3;
              ref.read(_loadedTabsProvider.notifier).update((s) => {...s, 3});
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HUD Navigation Item
// ============================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : const Color(0xFF8E8EA0),
              size: 23,
              shadows: isSelected
                  ? [
                      Shadow(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                color: isSelected ? AppTheme.primary : const Color(0xFF8E8EA0),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ⚡ Center Serendipity Warp Hero Button
// ============================================================

class _CenterChaosEngineButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _CenterChaosEngineButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isLoading = playerState.status == PlayerStatus.loading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B2C), Color(0xFFFF8533)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B2C).withValues(alpha: 0.65),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF380D00),
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}
