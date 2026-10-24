// ============================================================
// CHAOS FILTER MODEL
// ============================================================

class ChaosFilter {
  final String? genre;
  final String? mood;
  final String? decade;
  final String? regionCode;
  final String? instrument;
  final String? soundtrack;
  final String? tempo;
  final String? language;

  const ChaosFilter({
    this.genre,
    this.mood,
    this.decade,
    this.regionCode,
    this.instrument,
    this.soundtrack,
    this.tempo,
    this.language,
  });

  bool get isEmpty =>
      genre == null &&
      mood == null &&
      decade == null &&
      regionCode == null &&
      instrument == null &&
      soundtrack == null &&
      tempo == null &&
      language == null;

  String get summary {
    if (isEmpty) return 'Tất cả (Random 100%)';
    final active = <String>[];
    if (genre != null) active.add('Genre: $genre');
    if (mood != null) active.add('Mood: $mood');
    if (decade != null) active.add('Decade: $decade');
    if (regionCode != null) active.add('Region: $regionCode');
    if (instrument != null) active.add('Instrument: $instrument');
    if (soundtrack != null) active.add('Soundtrack: $soundtrack');
    if (tempo != null) active.add('Tempo: $tempo');
    if (language != null) active.add('Language: $language');
    return active.join(', ');
  }

  ChaosFilter copyWith({
    String? genre,
    String? mood,
    String? decade,
    String? regionCode,
    String? instrument,
    String? soundtrack,
    String? tempo,
    String? language,
  }) {
    return ChaosFilter(
      genre: genre ?? this.genre,
      mood: mood ?? this.mood,
      decade: decade ?? this.decade,
      regionCode: regionCode ?? this.regionCode,
      instrument: instrument ?? this.instrument,
      soundtrack: soundtrack ?? this.soundtrack,
      tempo: tempo ?? this.tempo,
      language: language ?? this.language,
    );
  }

  ChaosFilter clearField(String field) {
    return ChaosFilter(
      genre: field == 'genre' ? null : genre,
      mood: field == 'mood' ? null : mood,
      decade: field == 'decade' ? null : decade,
      regionCode: field == 'regionCode' ? null : regionCode,
      instrument: field == 'instrument' ? null : instrument,
      soundtrack: field == 'soundtrack' ? null : soundtrack,
      tempo: field == 'tempo' ? null : tempo,
      language: field == 'language' ? null : language,
    );
  }

  static const ChaosFilter empty = ChaosFilter();
}
