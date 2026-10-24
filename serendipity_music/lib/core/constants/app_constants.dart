// ============================================================
// APP CONSTANTS
// ============================================================

enum MusicSource { jamendo, youtubeBackend }

class AppConstants {
  AppConstants._();

  // Chuyển đổi nguồn nhạc: MusicSource.youtubeBackend hoặc MusicSource.jamendo
  static const MusicSource activeMusicSource = MusicSource.youtubeBackend;

  // Địa chỉ Backend YouTube (10.0.2.2 là host máy tính nhìn từ máy ảo Android)
  static const String youtubeBackendBaseUrl = 'http://10.0.2.2:8000/api';

  // App Info
  static const String appName = 'Serendipity';
  static const String appVersion = '1.0.0';

  // Jamendo Music API v3
  static const String jamendoClientId = 'e236fe24';
  static const String jamendoBaseUrl = 'https://api.jamendo.com/v3.0';

  // Audio
  static const int crossfadeDurationMs = 2500; // 2.5 giây crossfade
  static const int preBufferThresholdSec = 30; // Pre-buffer khi còn 30s
  static const int maxHistorySession = 200; // Tối đa 200 bài trong 1 phiên

  // Anti-loop: Số bài gần nhất không được lặp lại
  static const int antiLoopBufferSize = 50;

  // Sleep Timer Options (phút)
  static const List<int> sleepTimerOptions = [15, 30, 45, 60, 90];

  // Isar DB
  static const String isarDbName = 'serendipity_db';
}
