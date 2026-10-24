// ============================================================
// CHAOS FILTER CONSTANTS
// Tất cả bộ lọc cho tính năng Anti-Algorithm Shuffle
// ============================================================

class ChaosConstants {
  ChaosConstants._();

  // --- TIME MACHINE (Thập niên) ---
  static const Map<String, String> decades = {
    '60s': '1960s music',
    '70s': '1970s hits',
    '80s': '1980s classic',
    '90s': '1990s pop',
    '2000s': '2000s hits',
    '2010s': '2010s popular songs',
    '2020s': '2024 new music',
  };

  // --- WORLD MUSIC (Quốc gia / Khu vực) ---
  static const Map<String, String> regions = {
    'VN': 'nhạc việt nam',
    'KR': 'k-pop korean music',
    'JP': 'j-pop japanese music',
    'US': 'american pop music',
    'GB': 'british music',
    'FR': 'french music chanson',
    'BR': 'brazilian music samba bossa nova',
    'IN': 'bollywood indian music',
    'MX': 'mexican latin music',
    'NG': 'afrobeats nigerian music',
    'EG': 'arabic music',
    'TH': 'thai music',
    'ID': 'indonesian music',
    'TW': 'taiwanese mandopop',
    'CN': 'chinese music cpop',
  };

  // --- GENRE ROULETTE (Thể loại) ---
  static const List<String> genres = [
    'pop music',
    'rock music',
    'jazz music',
    'classical music',
    'hip hop music',
    'r&b soul music',
    'electronic EDM music',
    'lo-fi chill music',
    'indie folk music',
    'metal music',
    'reggae music',
    'country music',
    'blues music',
    'punk music',
    'ambient music',
    'gospel music',
    'bossa nova music',
    'flamenco music',
    'opera music',
    'funk music',
  ];

  // --- MOOD MODE (Tâm trạng) ---
  static const Map<String, String> moods = {
    'happy': 'happy upbeat music',
    'sad': 'sad emotional music',
    'chill': 'chill relaxing music',
    'energetic': 'energetic workout music',
    'romantic': 'romantic love songs',
    'focus': 'focus concentration music',
    'sleep': 'sleep meditation calm music',
    'party': 'party dance music',
  };

  // --- INSTRUMENT FOCUS ---
  static const Map<String, String> instruments = {
    'guitar': 'guitar music instrumental',
    'piano': 'piano music instrumental',
    'violin': 'violin classical music',
    'saxophone': 'saxophone jazz music',
    'drums': 'drum percussion music',
    'synthesizer': 'synthesizer electronic music',
    'bass': 'bass guitar music',
    'harp': 'harp music',
  };

  // --- BPM / TEMPO ---
  static const Map<String, String> tempos = {
    'slow': 'slow ballad music 60 bpm',
    'medium': 'medium tempo music 100 bpm',
    'fast': 'fast upbeat music 140 bpm',
    'very_fast': 'very fast energetic music 180 bpm',
  };

  // --- LANGUAGE ROULETTE ---
  static const Map<String, String> languages = {
    'vi': 'tiếng việt',
    'en': 'english',
    'ko': '한국어 korean',
    'ja': '日本語 japanese',
    'fr': 'français french',
    'es': 'español spanish',
    'pt': 'português',
    'ar': 'arabic',
    'hi': 'hindi',
    'th': 'ภาษาไทย thai',
  };

  // --- SOUNDTRACK MODE ---
  static const Map<String, String> soundtracks = {
    'anime': 'anime OST soundtrack',
    'movie': 'movie film soundtrack',
    'game': 'video game OST music',
    'kdrama': 'korean drama OST',
    'disney': 'disney soundtrack music',
  };

  // --- DURATION FILTER ---
  static const Map<String, String> durations = {
    'short': 'short song under 3 minutes',
    'normal': 'normal length song',
    'long': 'long epic song over 7 minutes',
  };
}
