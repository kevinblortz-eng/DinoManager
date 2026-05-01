import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/species_tracker.dart';

class TrackerProvider extends ChangeNotifier {
  static const String _storageKey = 'species_trackers';

  final List<SpeciesTracker> _trackers = [];

  List<SpeciesTracker> get trackers => List.unmodifiable(_trackers);

  Future<void> loadTrackers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];

      _trackers.clear();
      _trackers.addAll(
        rawList.map((raw) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return SpeciesTracker.fromMap(map);
        }),
      );

      _sortTrackers();
      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
  }

  Future<void> saveTrackers() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _trackers
        .map((tracker) => jsonEncode(tracker.toMap()))
        .toList();

    await prefs.setStringList(_storageKey, rawList);
  }

  SpeciesTracker? getTrackerById(String trackerId) {
    try {
      return _trackers.firstWhere((t) => t.id == trackerId);
    } catch (_) {
      return null;
    }
  }

  Future<void> createTracker(String species, String projectName) async {
    final existing = _trackers.where(
      (t) =>
          t.species.toLowerCase() == species.toLowerCase() &&
          (t.projectName ?? '').trim().toLowerCase() ==
              projectName.trim().toLowerCase(),
    );

    if (existing.isNotEmpty) {
      throw Exception('Un tracker similaire existe déjà');
    }

    final tracker = SpeciesTracker.empty(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      species: species,
      projectName: projectName.trim().isEmpty ? null : projectName.trim(),
    );

    _trackers.add(tracker);
    _sortTrackers();
    await saveTrackers();
    notifyListeners();
  }

  Future<void> deleteTracker(String trackerId) async {
    _trackers.removeWhere((t) => t.id == trackerId);
    await saveTrackers();
    notifyListeners();
  }

  Future<void> replaceAllTrackers(List<SpeciesTracker> trackers) async {
    _trackers
      ..clear()
      ..addAll(trackers);

    _sortTrackers();
    await saveTrackers();
    notifyListeners();
  }

  Future<void> updateBestStat({
    required String trackerId,
    required String statName,
    required double value,
    String? sourceName,
    int? points,
  }) async {
    final index = _trackers.indexWhere((t) => t.id == trackerId);
    if (index == -1) return;

    final tracker = _trackers[index];
    final updatedBestStats = Map<String, BestStatRecord>.from(tracker.bestStats);

    updatedBestStats[statName] = BestStatRecord(
      value: value,
      points: points,
      source: (sourceName == null || sourceName.trim().isEmpty)
          ? 'anonymous'
          : sourceName.trim(),
      recordedAt: DateTime.now(),
    );

    _trackers[index] = tracker.copyWith(
      bestStats: updatedBestStats,
      updatedAt: DateTime.now(),
    );

    await saveTrackers();
    notifyListeners();
  }

  Future<void> registerAnonymousStats({
    required String trackerId,
    required Map<String, double> stats,
    Map<String, int>? points,
    String? sourceName,
  }) async {
    final index = _trackers.indexWhere((t) => t.id == trackerId);
    if (index == -1) return;

    final tracker = _trackers[index];

    final newEntry = AnonymousStatEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      stats: stats,
      recordedAt: DateTime.now(),
    );

    final updatedEntries = List<AnonymousStatEntry>.from(
      tracker.anonymousStatEntries,
    )..add(newEntry);

    final updatedBestStats = Map<String, BestStatRecord>.from(tracker.bestStats);

    stats.forEach((statKey, value) {
      final current = updatedBestStats[statKey];
      if (current == null || value > current.value) {
        updatedBestStats[statKey] = BestStatRecord(
          value: value,
          points: points?[statKey],
          source: (sourceName == null || sourceName.trim().isEmpty)
              ? 'anonymous'
              : sourceName.trim(),
          recordedAt: DateTime.now(),
        );
      }
    });

    _trackers[index] = tracker.copyWith(
      anonymousStatEntries: updatedEntries,
      bestStats: updatedBestStats,
      updatedAt: DateTime.now(),
    );

    await saveTrackers();
    notifyListeners();
  }

  Future<void> deleteAnonymousStat({
    required String trackerId,
    required String entryId,
  }) async {
    final index = _trackers.indexWhere((t) => t.id == trackerId);
    if (index == -1) return;

    final tracker = _trackers[index];

    final updatedEntries = List<AnonymousStatEntry>.from(
      tracker.anonymousStatEntries,
    )..removeWhere((e) => e.id == entryId);

    _trackers[index] = tracker.copyWith(
      anonymousStatEntries: updatedEntries,
      updatedAt: DateTime.now(),
    );

    _rebuildBestStats(index);
    await saveTrackers();
    notifyListeners();
  }

  Future<void> deleteBestStat({
    required String trackerId,
    required String statKey,
  }) async {
    final index = _trackers.indexWhere((t) => t.id == trackerId);
    if (index == -1) return;

    final tracker = _trackers[index];
    final updatedBestStats =
        Map<String, BestStatRecord>.from(tracker.bestStats)
          ..remove(statKey);

    _trackers[index] = tracker.copyWith(
      bestStats: updatedBestStats,
      updatedAt: DateTime.now(),
    );

    await saveTrackers();
    notifyListeners();
  }

  Future<void> registerColorObservation({
    required String trackerId,
    required String sourceName,
    required List<int?> regionColors,
  }) async {
    final mapped = <int, int>{};

    for (int i = 0; i < regionColors.length && i < 6; i++) {
      final value = regionColors[i];
      if (value != null && value > 0) {
        mapped[i] = value;
      }
    }

    await saveAnonymousColorObservation(
      trackerId: trackerId,
      regionColors: mapped,
    );
  }

  Future<void> saveAnonymousColorObservation({
    required String trackerId,
    required Map<int, int> regionColors,
  }) async {
    final index = _trackers.indexWhere((t) => t.id == trackerId);
    if (index == -1) return;

    final tracker = _trackers[index];

    final newObservation = ColorObservation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      regionColors: regionColors,
      recordedAt: DateTime.now(),
    );

    final updatedObservations = List<ColorObservation>.from(
      tracker.colorObservations,
    )..add(newObservation);

    final updatedColorBank = Map<int, List<int>>.fromEntries(
      List.generate(6, (region) {
        final existing = List<int>.from(tracker.colorBank[region] ?? []);
        return MapEntry(region, existing);
      }),
    );

    regionColors.forEach((region, colorId) {
      if (colorId <= 0) return;

      final list = List<int>.from(updatedColorBank[region] ?? []);
      if (!list.contains(colorId)) {
        list.add(colorId);
        list.sort();
      }
      updatedColorBank[region] = list;
    });

    _trackers[index] = tracker.copyWith(
      colorObservations: updatedObservations,
      colorBank: updatedColorBank,
      updatedAt: DateTime.now(),
    );

    await saveTrackers();
    notifyListeners();
  }

  Future<void> deleteColorObservation({
    required String trackerId,
    required String observationId,
  }) async {
    final index = _trackers.indexWhere((t) => t.id == trackerId);
    if (index == -1) return;

    final tracker = _trackers[index];

    final updatedObservations = List<ColorObservation>.from(
      tracker.colorObservations,
    )..removeWhere((o) => o.id == observationId);

    _trackers[index] = tracker.copyWith(
      colorObservations: updatedObservations,
      updatedAt: DateTime.now(),
    );

    _rebuildColorBank(index);
    await saveTrackers();
    notifyListeners();
  }

  Future<void> removeColorFromBank({
    required String trackerId,
    required int region,
    required int colorId,
  }) async {
    final index = _trackers.indexWhere((t) => t.id == trackerId);
    if (index == -1) return;

    final tracker = _trackers[index];

    final updatedColorBank = Map<int, List<int>>.fromEntries(
      List.generate(6, (r) {
        return MapEntry(r, List<int>.from(tracker.colorBank[r] ?? []));
      }),
    );

    final list = List<int>.from(updatedColorBank[region] ?? []);
    list.remove(colorId);
    updatedColorBank[region] = list;

    _trackers[index] = tracker.copyWith(
      colorBank: updatedColorBank,
      updatedAt: DateTime.now(),
    );

    await saveTrackers();
    notifyListeners();
  }

  void _rebuildBestStats(int trackerIndex) {
    final tracker = _trackers[trackerIndex];
    final rebuilt = <String, BestStatRecord>{};

    for (final entry in tracker.anonymousStatEntries) {
      entry.stats.forEach((statKey, value) {
        final current = rebuilt[statKey];
        if (current == null || value > current.value) {
          rebuilt[statKey] = BestStatRecord(
            value: value,
            source: 'anonymous',
            recordedAt: entry.recordedAt,
          );
        }
      });
    }

    _trackers[trackerIndex] = tracker.copyWith(
      bestStats: rebuilt,
      updatedAt: DateTime.now(),
    );
  }

  void _rebuildColorBank(int trackerIndex) {
    final tracker = _trackers[trackerIndex];
    final rebuilt = <int, List<int>>{
      0: [],
      1: [],
      2: [],
      3: [],
      4: [],
      5: [],
    };

    for (final observation in tracker.colorObservations) {
      observation.regionColors.forEach((region, colorId) {
        if (colorId <= 0) return;

        final list = List<int>.from(rebuilt[region] ?? []);
        if (!list.contains(colorId)) {
          list.add(colorId);
          list.sort();
        }
        rebuilt[region] = list;
      });
    }

    _trackers[trackerIndex] = tracker.copyWith(
      colorBank: rebuilt,
      updatedAt: DateTime.now(),
    );
  }

  void _sortTrackers() {
    _trackers.sort((a, b) {
      final speciesCompare = a.species.toLowerCase().compareTo(
            b.species.toLowerCase(),
          );
      if (speciesCompare != 0) return speciesCompare;

      final aProject = (a.projectName ?? '').toLowerCase();
      final bProject = (b.projectName ?? '').toLowerCase();
      return aProject.compareTo(bProject);
    });
  }
}
