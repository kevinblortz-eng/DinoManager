// No Flutter framework dependency needed in this model

class SpeciesTracker {
  final String id;
  final String species;
  final String? projectName;
  final DateTime createdAt;
  final DateTime updatedAt;
final List<AnonymousStatEntry> anonymousStatEntries;
final List<ColorObservation> colorObservations;
  final Map<String, BestStatRecord> bestStats;
  final Map<int, List<int>> colorBank;

  SpeciesTracker({
    required this.id,
    required this.species,
    this.projectName,
    required this.createdAt,
    required this.updatedAt,
    required this.bestStats,
    required this.colorBank,
    required this.anonymousStatEntries,
    required this.colorObservations,
  });

  factory SpeciesTracker.empty({
    required String id,
    required String species,
    String? projectName,
  }) {
    return SpeciesTracker(
      id: id,
      species: species,
      projectName: projectName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      bestStats: {},
      colorBank: {
        0: [],
        1: [],
        2: [],
        3: [],
        4: [],
        5: [],
      },
      anonymousStatEntries: [],
      colorObservations: [],
    );
  }

  SpeciesTracker copyWith({
    String? id,
    String? species,
    String? projectName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, BestStatRecord>? bestStats,
    Map<int, List<int>>? colorBank,
    List<AnonymousStatEntry>? anonymousStatEntries,
    List<ColorObservation>? colorObservations,
  }) {
    return SpeciesTracker(
      id: id ?? this.id,
      species: species ?? this.species,
      projectName: projectName ?? this.projectName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bestStats: bestStats ?? this.bestStats,
      colorBank: colorBank ?? this.colorBank,
      anonymousStatEntries:
          anonymousStatEntries ?? this.anonymousStatEntries,
      colorObservations: colorObservations ?? this.colorObservations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'species': species,
      'projectName': projectName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bestStats': bestStats.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'colorBank': colorBank.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'anonymousStatEntries':
          anonymousStatEntries.map((e) => e.toMap()).toList(),
      'colorObservations': colorObservations.map((e) => e.toMap()).toList(),
    };
  }

  factory SpeciesTracker.fromMap(Map<String, dynamic> map) {
    return SpeciesTracker(
      id: map['id'] ?? '',
      species: map['species'] ?? '',
      projectName: map['projectName'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      bestStats: ((map['bestStats'] ?? {}) as Map).map(
        (key, value) => MapEntry(
          key.toString(),
          BestStatRecord.fromMap(Map<String, dynamic>.from(value)),
        ),
      ),
      colorBank: {
        0: _readColorList(map['colorBank'], 0),
        1: _readColorList(map['colorBank'], 1),
        2: _readColorList(map['colorBank'], 2),
        3: _readColorList(map['colorBank'], 3),
        4: _readColorList(map['colorBank'], 4),
        5: _readColorList(map['colorBank'], 5),
      },
      anonymousStatEntries: ((map['anonymousStatEntries'] ?? []) as List)
          .map((e) => AnonymousStatEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      colorObservations: ((map['colorObservations'] ?? []) as List)
          .map((e) => ColorObservation.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static List<int> _readColorList(dynamic rawBank, int region) {
    try {
      final bank = Map<String, dynamic>.from(rawBank ?? {});
      final raw = bank['$region'] ?? [];
      return List<int>.from(raw);
    } catch (_) {
      return [];
    }
  }
}

class BestStatRecord {
  final double value;
  final int? points;
  final String? source;
  final DateTime recordedAt;

  BestStatRecord({
    required this.value,
    this.points,
    this.source,
    required this.recordedAt,
  });

  BestStatRecord copyWith({
    double? value,
    int? points,
    String? source,
    DateTime? recordedAt,
  }) {
    return BestStatRecord(
      value: value ?? this.value,
      points: points ?? this.points,
      source: source ?? this.source,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'points': points,
      'source': source,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory BestStatRecord.fromMap(Map<String, dynamic> map) {
    return BestStatRecord(
      value: (map['value'] is int)
          ? (map['value'] as int).toDouble()
          : (map['value'] ?? 0).toDouble(),
      points: map['points'],
      source: map['source'],
      recordedAt:
          DateTime.tryParse(map['recordedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AnonymousStatEntry {
  final String id;
  final Map<String, double> stats;
  final DateTime recordedAt;

  AnonymousStatEntry({
    required this.id,
    required this.stats,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stats': stats,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory AnonymousStatEntry.fromMap(Map<String, dynamic> map) {
    return AnonymousStatEntry(
      id: map['id'] ?? '',
      stats: ((map['stats'] ?? {}) as Map).map(
        (key, value) => MapEntry(
          key.toString(),
          (value is int) ? value.toDouble() : (value ?? 0).toDouble(),
        ),
      ),
      recordedAt:
          DateTime.tryParse(map['recordedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ColorObservation {
  final String id;
  final Map<int, int> regionColors;
  final DateTime recordedAt;

  ColorObservation({
    required this.id,
    required this.regionColors,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'regionColors': regionColors.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory ColorObservation.fromMap(Map<String, dynamic> map) {
    return ColorObservation(
      id: map['id'] ?? '',
      regionColors: ((map['regionColors'] ?? {}) as Map).map(
        (key, value) => MapEntry(
          int.tryParse(key.toString()) ?? 0,
          value as int,
        ),
      ),
      recordedAt:
          DateTime.tryParse(map['recordedAt'] ?? '') ?? DateTime.now(),
    );
  }


}
