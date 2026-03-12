import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/dino.dart';

/// Service de sauvegarde et restauration des données de l'application.
///
/// Fonctionnement :
///   - Export : sérialise tous les dinos en JSON et partage le fichier
///     via le système Android (partage vers Google Drive, Email, etc.)
///   - Import : permet de choisir un fichier .json sauvegardé et
///     restaure les données depuis ce fichier.
///
/// Format du fichier de sauvegarde :
/// {
///   "version": 2,
///   "exportDate": "2024-01-15T10:30:00Z",
///   "appName": "ARK Dino Manager",
///   "dinos": [ {...}, {...} ],
///   "customTags": [ "tag1", "tag2" ]
/// }
class BackupService {
  static const int _backupVersion = 2;
  static const String _appName = 'ARK Dino Manager';

  /// Exporte tous les dinos vers un fichier JSON et ouvre le menu
  /// de partage Android (Google Drive, Email, Bluetooth, etc.).
  ///
  /// Retourne null si succès, ou un message d'erreur.
  static Future<String?> exportDinos({
    required List<Dino> dinos,
    required List<String> customTags,
  }) async {
    try {
      // Construire l'objet de sauvegarde
      final backupData = {
        'version': _backupVersion,
        'exportDate': DateTime.now().toUtc().toIso8601String(),
        'appName': _appName,
        'dinoCount': dinos.length,
        'dinos': dinos.map((d) => d.toMap()).toList(),
        'customTags': customTags,
      };

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(backupData);

      if (kIsWeb) {
        // Sur le web, on ne peut pas accéder au système de fichiers
        return 'Export non disponible sur le web — utilisez l\'application mobile.';
      }

      // Écrire dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final fileName = 'ark_dino_backup_$timestamp.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString, encoding: utf8);

      // Partager via le système Android
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '[$_appName] Sauvegarde — $timestamp',
        text: 'Sauvegarde ARK Dino Manager\n'
            '${dinos.length} dino(s) exporté(s)\n'
            'Date : $timestamp',
      );

      return null; // succès
    } catch (e) {
      return 'Erreur lors de l\'export : $e';
    }
  }

  /// Importe des dinos depuis un fichier JSON choisi par l'utilisateur.
  ///
  /// Retourne un [BackupResult] avec la liste des dinos importés,
  /// les tags personnalisés et éventuellement un message d'erreur.
  static Future<BackupResult> importDinos() async {
    try {
      if (kIsWeb) {
        return BackupResult.error(
            'Import non disponible sur le web — utilisez l\'application mobile.');
      }

      // Ouvrir le sélecteur de fichiers
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult.cancelled();
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        // Essayer de lire depuis le chemin
        final path = result.files.first.path;
        if (path == null) {
          return BackupResult.error('Impossible de lire le fichier.');
        }
        final content = await File(path).readAsString(encoding: utf8);
        return _parseBackupJson(content);
      }

      final content = utf8.decode(fileBytes);
      return _parseBackupJson(content);
    } catch (e) {
      return BackupResult.error('Erreur lors de l\'import : $e');
    }
  }

  static BackupResult _parseBackupJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Vérifier la structure minimale
      if (!data.containsKey('dinos')) {
        return BackupResult.error(
            'Format de fichier invalide : clé "dinos" manquante.');
      }

      final version = data['version'] as int? ?? 1;
      final dinosRaw = data['dinos'] as List<dynamic>;
      final tagsRaw = data['customTags'] as List<dynamic>? ?? [];

      final dinos = <Dino>[];
      final errors = <String>[];

      for (int i = 0; i < dinosRaw.length; i++) {
        try {
          final map = dinosRaw[i] as Map<String, dynamic>;
          dinos.add(Dino.fromMap(map));
        } catch (e) {
          errors.add('Dino #$i ignoré (format invalide) : $e');
        }
      }

      final tags = tagsRaw.map((t) => t.toString()).toList();

      return BackupResult.success(
        dinos: dinos,
        customTags: tags,
        version: version,
        warnings: errors,
      );
    } on FormatException catch (e) {
      return BackupResult.error('JSON invalide : $e');
    } catch (e) {
      return BackupResult.error('Erreur d\'analyse : $e');
    }
  }
}

/// Résultat d'un import de sauvegarde
class BackupResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final List<Dino> dinos;
  final List<String> customTags;
  final int version;
  final List<String> warnings;

  const BackupResult._({
    required this.success,
    required this.cancelled,
    this.error,
    this.dinos = const [],
    this.customTags = const [],
    this.version = 1,
    this.warnings = const [],
  });

  factory BackupResult.success({
    required List<Dino> dinos,
    required List<String> customTags,
    required int version,
    List<String> warnings = const [],
  }) =>
      BackupResult._(
        success: true,
        cancelled: false,
        dinos: dinos,
        customTags: customTags,
        version: version,
        warnings: warnings,
      );

  factory BackupResult.error(String message) => BackupResult._(
        success: false,
        cancelled: false,
        error: message,
      );

  factory BackupResult.cancelled() => BackupResult._(
        success: false,
        cancelled: true,
      );
}
