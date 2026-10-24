import '../../domain/entities/track_entity.dart';
import '../../domain/entities/chaos_filter.dart';

// ============================================================
// MUSIC SOURCE SERVICE INTERFACE
// Cho phép chuyển đổi linh hoạt giữa Jamendo và YouTube Backend
// ============================================================

abstract class MusicSourceService {
  Future<List<TrackEntity>> searchTracks(String query, {int limit = 20, int offset = 0});
  Future<TrackEntity> getRandomTrack({ChaosFilter? filter, Set<String>? excludeIds});
  Future<TrackEntity?> getTrackById(String id);
  Future<List<TrackEntity>> getRelatedTracks(TrackEntity track, {int limit = 15});
  Future<void> warmupCache({ChaosFilter? filter});
  void clearCache();
  void dispose();
}
