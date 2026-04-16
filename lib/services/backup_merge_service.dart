import '../models/dino.dart';
import '../models/species_tracker.dart';

class BackupMergeResult {
  final List<Dino> dinos;
  final List<String> customTags;
  final List<SpeciesTracker> trackers;

  const BackupMergeResult({
    required this.dinos,
    required this.customTags,
    required this.trackers,
  });
}

class BackupMergeService {
  static BackupMergeResult mergeAll({
    required List<Dino> existingDinos,
    required List<Dino> importedDinos,
    required List<String> existingTags,
    required List<String> importedTags,
    required List<SpeciesTracker> existingTrackers,
    required List<SpeciesTracker> importedTrackers,
  }) {
    return BackupMergeResult(
      dinos: mergeDinos(
        existing: existingDinos,
        imported: importedDinos,
      ),
      customTags: mergeCustomTags(
        existing: existingTags,
        imported: importedTags,
      ),
      trackers: mergeTrackers(
        existing: existingTrackers,
        imported: importedTrackers,
      ),
    );
  }

  static List<Dino> mergeDinos({
    required List<Dino> existing,
    required List<Dino> imported,
  }) {
    final byId = <int, Dino>{};
    final noId = <Dino>[];

    for (final dino in existing) {
      if (dino.id != null) {
        byId[dino.id!] = dino;
      } else {
        noId.add(dino);
      }
    }

    for (final dino in imported) {
      if (dino.id != null) {
        byId[dino.id!] = dino;
      } else {
        noId.add(dino);
      }
    }

    final merged = [
      ...byId.values,
      ...noId,
    ];

    merged.sort((a, b) {
      final speciesCompare = a.espece.compareTo(b.espece);
      if (speciesCompare != 0) return speciesCompare;
      return a.nom.compareTo(b.nom);
    });

    return merged;
  }

  static List<String> mergeCustomTags({
    required List<String> existing,
    required List<String> imported,
  }) {
    final set = <String>{};

    for (final tag in [...existing, ...imported]) {
      final clean = tag.trim();
      if (clean.isNotEmpty) {
        set.add(clean);
      }
    }

    final result = set.toList()..sort();
    return result;
  }

  static List<SpeciesTracker> mergeTrackers({
    required List<SpeciesTracker> existing,
    required List<SpeciesTracker> imported,
  }) {
    final byId = <String, SpeciesTracker>{};

    for (final tracker in existing) {
      byId[tracker.id] = tracker;
    }

    for (final tracker in imported) {
      final current = byId[tracker.id];
      if (current == null) {
        byId[tracker.id] = tracker;
      } else {
        byId[tracker.id] = mergeTwoTrackers(current, tracker);
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final speciesCompare = a.species.compareTo(b.species);
        if (speciesCompare != 0) return speciesCompare;
        return (a.projectName ?? '').compareTo(b.projectName ?? '');
      });

    return merged;
  }

  static SpeciesTracker mergeTwoTrackers(
    SpeciesTracker existing,
    SpeciesTracker imported,
  ) {
    return SpeciesTracker(
      id: existing.id,
      species: imported.species.trim().isNotEmpty
          ? imported.species
          : existing.species,
      projectName: _pickProjectName(existing.projectName, imported.projectName),
      createdAt: existing.createdAt.isBefore(imported.createdAt)
          ? existing.createdAt
          : imported.createdAt,
      updatedAt: existing.updatedAt.isAfter(imported.updatedAt)
          ? existing.updatedAt
          : imported.updatedAt,
      bestStats: mergeBestStats(existing.bestStats, imported.bestStats),
      colorBank: mergeColorBanks(existing.colorBank, imported.colorBank),
      anonymousStatEntries: mergeAnonymousEntries(
        existing.anonymousStatEntries,
        imported.anonymousStatEntries,
      ),
      colorObservations: mergeColorObservations(
        existing.colorObservations,
        imported.colorObservations,
      ),
    );
  }

  static String? _pickProjectName(String? a, String? b) {
    final aa = a?.trim();
    final bb = b?.trim();

    if (bb != null && bb.isNotEmpty) return bb;
    if (aa != null && aa.isNotEmpty) return aa;
    return null;
  }

  static Map<String, BestStatRecord> mergeBestStats(
    Map<String, BestStatRecord> existing,
    Map<String, BestStatRecord> imported,
  ) {
    final result = <String, BestStatRecord>{};

    for (final entry in existing.entries) {
      result[entry.key] = entry.value;
    }

    for (final entry in imported.entries) {
      final current = result[entry.key];
      if (current == null || entry.value.value > current.value) {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  static Map<int, List<int>> mergeColorBanks(
    Map<int, List<int>> existing,
    Map<int, List<int>> imported,
  ) {
    final result = <int, List<int>>{};

    for (int region = 0; region <= 5; region++) {
      final merged = <int>{
        ...List<int>.from(existing[region] ?? const []),
        ...List<int>.from(imported[region] ?? const []),
      }.where((id) => id > 0).toList()
        ..sort();

      result[region] = merged;
    }

    return result;
  }

  static List<AnonymousStatEntry> mergeAnonymousEntries(
    List<AnonymousStatEntry> existing,
    List<AnonymousStatEntry> imported,
  ) {
    final byId = <String, AnonymousStatEntry>{};

    for (final entry in existing) {
      byId[entry.id] = entry;
    }

    for (final entry in imported) {
      byId[entry.id] = entry;
    }

    final result = byId.values.toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return result;
  }

  static List<ColorObservation> mergeColorObservations(
    List<ColorObservation> existing,
    List<ColorObservation> imported,
  ) {
    final byId = <String, ColorObservation>{};

    for (final obs in existing) {
      byId[obs.id] = obs;
    }

    for (final obs in imported) {
      byId[obs.id] = obs;
    }

    final result = byId.values.toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return result;
  }
}
