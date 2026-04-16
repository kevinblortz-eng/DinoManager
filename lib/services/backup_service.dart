import 'dart:convert';
import 'dart:io' ;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dino.dart';
import '../models/species_tracker.dart';

class BackupService {
  static const int _backupVersion = 3;
  static const String _appName = 'ARK Dino Manager';
  static const String _backupType = 'full_backup';

  static Future<String?> exportData({
    required List<Dino> dinos,
    required List<String> customTags,
    required List<SpeciesTracker> trackers,
  }) async {
    try {
      final backupData = {
        'version': _backupVersion,
        'type': _backupType,
        'exportDate': DateTime.now().toUtc().toIso8601String(),
        'appName': _appName,
        'dinoCount': dinos.length,
        'trackerCount': trackers.length,
        'dinos': dinos.map((d) => d.toMap()).toList(),
        'customTags': customTags,
        'trackers': trackers.map((t) => t.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      if (kIsWeb) {
        return 'Export non disponible sur le web — utilisez l\'application mobile.';
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);

      final fileName = 'ark_dino_full_backup_$timestamp.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '[$_appName] Sauvegarde complète — $timestamp',
        text: 'Sauvegarde complète ARK Dino Manager\n'
            '${dinos.length} dino(s)\n'
            '${trackers.length} tracker(s)\n'
            'Date : $timestamp',
      );

      return null;
    } catch (e) {
      return 'Erreur lors de l\'export : $e';
    }
  }

  static Future<BackupImportResult> importData() async {
    try {
      if (kIsWeb) {
        return BackupImportResult.error(
          'Import non disponible sur le web — utilisez l\'application mobile.',
        );
      }

     // ✅ APRÈS
final result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['json'],
);

      if (result == null || result.files.isEmpty) {
        return BackupImportResult.cancelled();
      }

      final pickedFile = result.files.first;

      // Priorité au path (Android / iOS / Desktop)
      final path = pickedFile.path;
      if (path != null) {
        final content = await File(path).readAsString(encoding: utf8);
        return _parseBackupJson(content);
      }

      // Fallback sur les bytes en mémoire
      final fileBytes = pickedFile.bytes;
      if (fileBytes != null) {
        final content = utf8.decode(fileBytes);
        return _parseBackupJson(content);
      }

      return BackupImportResult.error('Impossible de lire le fichier.');
    } catch (e) {
      return BackupImportResult.error('Erreur lors de l\'import : $e');
    }
  }

  static BackupImportResult _parseBackupJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (!data.containsKey('dinos')) {
        return BackupImportResult.error(
          'Format invalide : clé "dinos" manquante.',
        );
      }

      final version = data['version'] as int? ?? 1;
      final type = data['type'] as String? ?? 'legacy';

      final dinosRaw = data['dinos'] as List<dynamic>;
      final tagsRaw = data['customTags'] as List<dynamic>? ?? [];
      final trackersRaw = data['trackers'] as List<dynamic>? ?? [];

      final dinos = <Dino>[];
      final trackers = <SpeciesTracker>[];
      final warnings = <String>[];

      for (int i = 0; i < dinosRaw.length; i++) {
        try {
          final map = Map<String, dynamic>.from(dinosRaw[i] as Map);
          dinos.add(Dino.fromMap(map));
        } catch (e) {
          warnings.add('Dino #$i ignoré : $e');
        }
      }

      for (int i = 0; i < trackersRaw.length; i++) {
        try {
          final map = Map<String, dynamic>.from(trackersRaw[i] as Map);
          trackers.add(SpeciesTracker.fromMap(map));
        } catch (e) {
          warnings.add('Tracker #$i ignoré : $e');
        }
      }

      final tags = tagsRaw
          .map((t) => t.toString().trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
      tags.sort();

      return BackupImportResult.success(
        dinos: dinos,
        customTags: tags,
        trackers: trackers,
        version: version,
        backupType: type,
        warnings: warnings,
      );
    } on FormatException catch (e) {
      return BackupImportResult.error('JSON invalide : $e');
    } catch (e) {
      return BackupImportResult.error('Erreur d\'analyse : $e');
    }
  }
}

class BackupImportResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final List<Dino> dinos;
  final List<String> customTags;
  final List<SpeciesTracker> trackers;
  final int version;
  final String backupType;
  final List<String> warnings;

  const BackupImportResult._({
    required this.success,
    required this.cancelled,
    this.error,
    this.dinos = const [],
    this.customTags = const [],
    this.trackers = const [],
    this.version = 1,
    this.backupType = 'legacy',
    this.warnings = const [],
  });

  factory BackupImportResult.success({
    required List<Dino> dinos,
    required List<String> customTags,
    required List<SpeciesTracker> trackers,
    required int version,
    required String backupType,
    List<String> warnings = const [],
  }) {
    return BackupImportResult._(
      success: true,
      cancelled: false,
      dinos: dinos,
      customTags: customTags,
      trackers: trackers,
      version: version,
      backupType: backupType,
      warnings: warnings,
    );
  }

  factory BackupImportResult.error(String message) {
    return BackupImportResult._(
      success: false,
      cancelled: false,
      error: message,
    );
  }

  factory BackupImportResult.cancelled() {
    return BackupImportResult._(
      success: false,
      cancelled: true,
    );
  }
}
