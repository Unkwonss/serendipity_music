import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/main_scaffold.dart';
import 'presentation/providers/player_provider.dart';
import 'services/audio/audio_handler.dart';
import 'data/datasources/local_history_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ----------------------------------------------------------
  // Bắt mọi lỗi UI Widget và in chi tiết ra Terminal
  // ----------------------------------------------------------
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('\n❌ [FLUTTER UI ERROR] ========================');
    debugPrint('${details.exception}');
    if (details.stack != null) {
      debugPrint('📋 Stack:\n${details.stack}');
    }
    debugPrint('===============================================\n');
  };

  // ----------------------------------------------------------
  // Bắt mọi lỗi bất đồng bộ (Async / Future) và in ra Terminal
  // ----------------------------------------------------------
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('\n❌ [ASYNC UNCAUGHT ERROR] ====================');
    debugPrint('Lỗi: $error');
    debugPrint('📋 Stack:\n$stack');
    debugPrint('===============================================\n');
    return true;
  };

  debugPrint('🚀 [App] Khởi động ứng dụng Serendipity...');

  // Gọi runApp() ngay lập tức để Android mount và vẽ Frame 0 tức thì
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  SerendipityAudioHandler? _audioHandler;
  LocalHistoryStorage? _historyStorage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final historyStorage = LocalHistoryStorage();
      await Hive.initFlutter();
      await historyStorage.init();
      debugPrint('📦 [Hive Storage] Đã khởi tạo thành công');

      final SerendipityAudioHandler audioHandler = await AudioService.init(
        builder: () => SerendipityAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.serendipity.music.audio',
          androidNotificationChannelName: 'Serendipity Music',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          notificationColor: AppTheme.primary,
        ),
      );
      debugPrint('🎧 [AudioService] Đã khởi tạo dịch vụ phát nhạc ngầm');

      if (mounted) {
        setState(() {
          _historyStorage = historyStorage;
          _audioHandler = audioHandler;
        });
      }
    } catch (e, stack) {
      debugPrint('❌ [Init Error] Lỗi khởi động ứng dụng: $e');
      debugPrint('📋 Stack:\n$stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.bgDeep,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Lỗi khởi động: $_error',
                style: const TextStyle(color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (_audioHandler == null || _historyStorage == null) {
      // Màn hình khởi động Odyssey tức thì (vẽ ngay tại mili-giây 0, triệt tiêu hoàn toàn màn hình đen)
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.bgDeep,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SERENDIPITY ODYSSEY',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CONNECTING TO RADAR...',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.primary,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(_audioHandler!),
        historyStorageProvider.overrideWithValue(_historyStorage!),
      ],
      child: const SerendipityApp(),
    );
  }
}

class SerendipityApp extends StatelessWidget {
  const SerendipityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serendipity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScaffold(),
    );
  }
}
