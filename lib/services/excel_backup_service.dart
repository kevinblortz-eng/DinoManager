// lib/services/excel_backup_service.dart
import 'dart:io' ;

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dino.dart';
import '../models/ark_color_palette.dart';
import '../models/species_tracker.dart';

class FullExcelImportResult {
  final bool success;
  final List<Dino> importedDinos;
  final List<String> customTags;
  final List<SpeciesTracker> importedTrackers;
  final List<String> warnings;
  final List<String> errors;

  const FullExcelImportResult({
    required this.success,
    required this.importedDinos,
    required this.customTags,
    required this.importedTrackers,
    required this.warnings,
    required this.errors,
  });

  factory FullExcelImportResult.success({
    required List<Dino> importedDinos,
    required List<String> customTags,
    required List<SpeciesTracker> importedTrackers,
    List<String> warnings = const [],
  }) {
    return FullExcelImportResult(
      success: true,
      importedDinos: importedDinos,
      customTags: customTags,
      importedTrackers: importedTrackers,
      warnings: warnings,
      errors: const [],
    );
  }

  factory FullExcelImportResult.failure({
    List<String> errors = const [],
    List<String> warnings = const [],
  }) {
    return FullExcelImportResult(
      success: false,
      importedDinos: const [],
      customTags: const [],
      importedTrackers: const [],
      warnings: warnings,
      errors: errors,
    );
  }
}

class ExcelBackupService {
  static const String metaSheetName = 'Meta';
  static const String dinosSheetName = 'Dinosaures';
  static const String tagsSheetName = 'Tags Personnalises';
  static const String trackersSheetName = 'Trackers';
  static const String observationsSheetName = 'Observations Couleurs';
  static const String speciesListSheetName = 'Especes Disponibles';
  static const String guideSheetName = 'Guide';

  // ═══════════════════════════ EXPORT ═══════════════════════════

  Future<File> exportAndShareFullBackup({
    required List<Dino> dinos,
    required List<String> customTags,
    required List<SpeciesTracker> trackers,
    String filePrefix = 'ark_full_backup',
  }) async {
    final file = await exportFullBackup(
      dinos: dinos,
      customTags: customTags,
      trackers: trackers,
      filePrefix: filePrefix,
    );

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'Sauvegarde Excel ARK complète',
      subject: 'Backup Excel ARK',
    ));

    return file;
  }

  Future<File> exportFullBackup({
    required List<Dino> dinos,
    required List<String> customTags,
    required List<SpeciesTracker> trackers,
    String filePrefix = 'ark_full_backup',
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    final metaSheet = excel[metaSheetName];
    final dinosSheet = excel[dinosSheetName];
    final tagsSheet = excel[tagsSheetName];
    final trackersSheet = excel[trackersSheetName];
    final obsSheet = excel[observationsSheetName];
    final speciesSheet = excel[speciesListSheetName];
    final guideSheet = excel[guideSheetName];

    // ── Meta ──
    _writeHeader(metaSheet, ['Key', 'Value']);
    _writeRow(metaSheet, 1, ['type', 'full_backup']);
    _writeRow(metaSheet, 2, ['version', '2']);
    _writeRow(metaSheet, 3, ['exportedAt', DateTime.now().toIso8601String()]);

    // ── Dinosaures ──
    _writeHeader(dinosSheet, [
      'ID', 'Nom', 'Espèce', 'Sexe', 'Rôle', 'Niveau',
      'HP', 'Endurance', 'Oxygène', 'Nourriture', 'Poids', 'Dégâts', 'Vitesse',
      'Couleur 0 ID', 'Couleur 1 ID', 'Couleur 2 ID',
      'Couleur 3 ID', 'Couleur 4 ID', 'Couleur 5 ID',
      'Tags', 'Notes', 'Date Ajout',
    ]);

    for (int i = 0; i < dinos.length; i++) {
      final d = dinos[i];
      _writeRow(dinosSheet, i + 1, [
        d.id, d.nom, d.espece, d.sexe, d.role, d.niveau,
        d.hp, d.stamina, d.oxygene, d.nourriture, d.poids, d.degats, d.vitesse,
        d.colorId0, d.colorId1, d.colorId2, d.colorId3, d.colorId4, d.colorId5,
        d.tags.join(', '), d.notes, d.dateAjout.toIso8601String(),
      ]);
    }

    // ── Tags ──
    _writeHeader(tagsSheet, ['Tag']);
    for (int i = 0; i < customTags.length; i++) {
      _writeRow(tagsSheet, i + 1, [customTags[i]]);
    }

    // ── Trackers ──
    _writeHeader(trackersSheet, [
      'Tracker ID', 'Species', 'Project Name', 'Created At', 'Updated At',
    ]);
    for (int i = 0; i < trackers.length; i++) {
      final t = trackers[i];
      _writeRow(trackersSheet, i + 1, [
        t.id, t.species, t.projectName ?? '',
        t.createdAt.toIso8601String(), t.updatedAt.toIso8601String(),
      ]);
    }

    // ── Observations Couleurs ──
    _writeHeader(obsSheet, [
      'Espèce', 'Sexe', 'Rôle', 'Niveau', 'Notes',
      'Couleur 0 ID', 'Couleur 1 ID', 'Couleur 2 ID',
      'Couleur 3 ID', 'Couleur 4 ID', 'Couleur 5 ID',
    ]);
    int obsRow = 1;
    for (final t in trackers) {
      for (final obs in t.colorObservations) {
        _writeRow(obsSheet, obsRow, [
          t.species, '', '', '', '',
          obs.regionColors[0] ?? 0, obs.regionColors[1] ?? 0,
          obs.regionColors[2] ?? 0, obs.regionColors[3] ?? 0,
          obs.regionColors[4] ?? 0, obs.regionColors[5] ?? 0,
        ]);
        obsRow++;
      }
    }

    // ── Espèces Disponibles ──
    _writeHeader(speciesSheet, ['Nom Espèce']);
    final allSpecies = Dino.especesDisponibles;
    for (int i = 0; i < allSpecies.length; i++) {
      _writeRow(speciesSheet, i + 1, [allSpecies[i]]);
    }

    // ── Guide ──
    _writeHeader(guideSheet, ['Guide']);
    final guideLines = [
      'Export Excel ARK Dino Manager v2',
      '',
      'FEUILLE "Dinosaures" :',
      '  Vos DinoCards sauvegardées. Les lignes AVEC un ID sont des cards.',
      '  Ne modifiez pas les ID existants.',
      '',
      'FEUILLE "Observations Couleurs" :',
      '  AJOUTEZ VOS RELEVES DE CHASSE ICI !',
      '  Colonne "Espèce" : nom EXACT depuis la feuille "Especes Disponibles".',
      '  Colonnes "Couleur X ID" : ID ARK (1-256), ou 0/vide si inconnue.',
      '  Colonnes Sexe, Rôle, Niveau, Notes : optionnelles.',
      '  Chaque ligne sera importée comme observation dans le tracker.',
      '',
      'FEUILLE "Especes Disponibles" :',
      '  Liste de tous les noms d\'espèces reconnus par l\'app.',
      '  Copiez-collez le nom exact dans vos observations.',
      '',
      'FEUILLE "Trackers" :',
      '  Trackers existants. Recréés automatiquement si besoin.',
      '',
      'A L\'IMPORT :',
      '  - DinoCards (avec ID) remplacent les données existantes.',
      '  - Observations de "Observations Couleurs" ajoutées aux trackers.',
      '  - Lignes SANS ID dans "Dinosaures" traitées comme observations.',
    ];
    for (int i = 0; i < guideLines.length; i++) {
      _writeRow(guideSheet, i + 1, [guideLines[i]]);
    }

    // Supprimer la feuille par défaut
    if (defaultSheet != null &&
        defaultSheet != metaSheetName &&
        excel.tables.containsKey(defaultSheet)) {
      excel.delete(defaultSheet);
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final file = File('${tempDir.path}/${filePrefix}_$timestamp.xlsx');
    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Impossible de générer le fichier Excel.');
    }

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // ═══════════════════════════ IMPORT ═══════════════════════════

  Future<FullExcelImportResult> importFullBackupFromPicker({
    List<Dino> existingDinos = const [],
  }) async {
    try {
      // ✅ withData supprimé — obsolète en file_picker v11
     // ✅ APRÈS
final result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['xlsx', 'xls'],
);


      if (result == null || result.files.isEmpty) {
        return FullExcelImportResult.failure(
          errors: ['Aucun fichier sélectionné.'],
        );
      }

      final picked = result.files.first;

      // ✅ Priorité au path (Android / iOS / Desktop)
      Uint8List? bytes;
      final path = picked.path;
      if (path != null) {
        bytes = await File(path).readAsBytes();
      }

      // ✅ Fallback sur les bytes en mémoire
      bytes ??= picked.bytes;

      if (bytes == null) {
        return FullExcelImportResult.failure(
          errors: ['Impossible de lire le fichier sélectionné.'],
        );
      }

      final excel = Excel.decodeBytes(bytes);
      final warnings = <String>[];

      // ── 1. Lire les DinoCards (lignes avec ID et Nom valides) ──
      final importedDinos = excel.tables.containsKey(dinosSheetName)
          ? _parseDinosSheet(excel[dinosSheetName], warnings)
          : <Dino>[];

      // ── 2. Lire les Tags ──
      final customTags = excel.tables.containsKey(tagsSheetName)
          ? _parseTagsSheet(excel[tagsSheetName])
          : <String>[];

      // ── 3. Lire les Trackers existants ──
      final importedTrackers = excel.tables.containsKey(trackersSheetName)
          ? _parseTrackersSheet(excel[trackersSheetName], warnings)
          : <SpeciesTracker>[];

      // ── 4. Lire la feuille "Observations Couleurs" ──
      if (excel.tables.containsKey(observationsSheetName)) {
        _parseObservationsSheet(
          excel[observationsSheetName],
          importedTrackers,
          warnings,
        );
      }

      // ── 5. Convertir les lignes sans ID de "Dinosaures" en observations ──
      if (excel.tables.containsKey(dinosSheetName)) {
        _parseOrphanDinoRowsAsObservations(
          excel[dinosSheetName],
          importedTrackers,
          warnings,
        );
      }

      return FullExcelImportResult.success(
        importedDinos: importedDinos,
        customTags: customTags,
        importedTrackers: importedTrackers,
        warnings: warnings,
      );
    } catch (e, st) {
      debugPrint('Excel import error: $e');
      debugPrint('$st');
      return FullExcelImportResult.failure(
        errors: ['Erreur lors de l\'import Excel : $e'],
      );
    }
  }

  // ─────────── Parse DinoCards (lignes AVEC ID et Nom) ───────────

  List<Dino> _parseDinosSheet(Sheet sheet, List<String> warnings) {
    final rows = sheet.rows;
    if (rows.isEmpty) return [];

    final headers = _headerMap(rows.first);
    final result = <Dino>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final idVal = _safeInt(_get(row, headers, 'ID'));
        final nom = _get(row, headers, 'Nom');
        final espece = _get(row, headers, 'Espèce');

        if (espece.isEmpty) continue;
        if (idVal == null || idVal == 0 || nom.isEmpty) continue;

        final color0 = _buildImportedColor(_safeInt(_get(row, headers, 'Couleur 0 ID')) ?? 0);
        final color1 = _buildImportedColor(_safeInt(_get(row, headers, 'Couleur 1 ID')) ?? 0);
        final color2 = _buildImportedColor(_safeInt(_get(row, headers, 'Couleur 2 ID')) ?? 0);
        final color3 = _buildImportedColor(_safeInt(_get(row, headers, 'Couleur 3 ID')) ?? 0);
        final color4 = _buildImportedColor(_safeInt(_get(row, headers, 'Couleur 4 ID')) ?? 0);
        final color5 = _buildImportedColor(_safeInt(_get(row, headers, 'Couleur 5 ID')) ?? 0);

        final tags = _get(row, headers, 'Tags')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        result.add(
          Dino(
            id: idVal,
            nom: nom,
            espece: espece,
            sexe: _get(row, headers, 'Sexe').isEmpty
                ? 'Inconnu'
                : _get(row, headers, 'Sexe'),
            role: _get(row, headers, 'Rôle').isEmpty
                ? 'Breed'
                : _get(row, headers, 'Rôle'),
            niveau: _safeInt(_get(row, headers, 'Niveau')) ?? 0,
            hp: _safeInt(_get(row, headers, 'HP')) ?? 0,
            stamina: _safeInt(_get(row, headers, 'Endurance')) ?? 0,
            oxygene: _safeInt(_get(row, headers, 'Oxygène')) ?? 0,
            nourriture: _safeInt(_get(row, headers, 'Nourriture')) ?? 0,
            poids: _safeInt(_get(row, headers, 'Poids')) ?? 0,
            degats: _safeDouble(_get(row, headers, 'Dégâts')) ?? 0,
            vitesse: _safeDouble(_get(row, headers, 'Vitesse')) ?? 0,
            couleur0: color0,
            couleur1: color1,
            couleur2: color2,
            couleur3: color3,
            couleur4: color4,
            couleur5: color5,
            tags: tags,
            notes: _get(row, headers, 'Notes'),
            dateAjout: DateTime.tryParse(_get(row, headers, 'Date Ajout')) ?? DateTime.now(),
          ),
        );
      } catch (e) {
        warnings.add('DinoCard ligne ${i + 1} ignorée : $e');
      }
    }

    return result;
  }

  // ─────────── Parse lignes orphelines de "Dinosaures" → observations ───────────

  void _parseOrphanDinoRowsAsObservations(
    Sheet sheet,
    List<SpeciesTracker> trackers,
    List<String> warnings,
  ) {
    final rows = sheet.rows;
    if (rows.isEmpty) return;

    final headers = _headerMap(rows.first);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final idVal = _safeInt(_get(row, headers, 'ID'));
        final nom = _get(row, headers, 'Nom');
        final espece = _get(row, headers, 'Espèce');

        if (espece.isEmpty) continue;
        if (idVal != null && idVal > 0 && nom.isNotEmpty) continue;

        final regionColors = <int, int>{};
        final c0 = _safeInt(_get(row, headers, 'Couleur 0 ID')) ?? 0;
        final c1 = _safeInt(_get(row, headers, 'Couleur 1 ID')) ?? 0;
        final c2 = _safeInt(_get(row, headers, 'Couleur 2 ID')) ?? 0;
        final c3 = _safeInt(_get(row, headers, 'Couleur 3 ID')) ?? 0;
        final c4 = _safeInt(_get(row, headers, 'Couleur 4 ID')) ?? 0;
        final c5 = _safeInt(_get(row, headers, 'Couleur 5 ID')) ?? 0;

        if (c0 > 0) regionColors[0] = c0;
        if (c1 > 0) regionColors[1] = c1;
        if (c2 > 0) regionColors[2] = c2;
        if (c3 > 0) regionColors[3] = c3;
        if (c4 > 0) regionColors[4] = c4;
        if (c5 > 0) regionColors[5] = c5;

        if (regionColors.isEmpty) continue;

        _addObservationToTracker(
          trackers: trackers,
          species: espece,
          regionColors: regionColors,
        );
      } catch (e) {
        warnings.add('Relevé ligne ${i + 1} (Dinosaures) ignoré : $e');
      }
    }
  }

  // ─────────── Parse feuille "Observations Couleurs" ───────────

  void _parseObservationsSheet(
    Sheet sheet,
    List<SpeciesTracker> trackers,
    List<String> warnings,
  ) {
    final rows = sheet.rows;
    if (rows.isEmpty) return;

    final headers = _headerMap(rows.first);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final espece = _get(row, headers, 'Espèce');
        if (espece.isEmpty) continue;

        final regionColors = <int, int>{};
        final c0 = _safeInt(_get(row, headers, 'Couleur 0 ID')) ?? 0;
        final c1 = _safeInt(_get(row, headers, 'Couleur 1 ID')) ?? 0;
        final c2 = _safeInt(_get(row, headers, 'Couleur 2 ID')) ?? 0;
        final c3 = _safeInt(_get(row, headers, 'Couleur 3 ID')) ?? 0;
        final c4 = _safeInt(_get(row, headers, 'Couleur 4 ID')) ?? 0;
        final c5 = _safeInt(_get(row, headers, 'Couleur 5 ID')) ?? 0;

        if (c0 > 0) regionColors[0] = c0;
        if (c1 > 0) regionColors[1] = c1;
        if (c2 > 0) regionColors[2] = c2;
        if (c3 > 0) regionColors[3] = c3;
        if (c4 > 0) regionColors[4] = c4;
        if (c5 > 0) regionColors[5] = c5;

        if (regionColors.isEmpty) continue;

        _addObservationToTracker(
          trackers: trackers,
          species: espece,
          regionColors: regionColors,
        );
      } catch (e) {
        warnings.add('Observation ligne ${i + 1} ignorée : $e');
      }
    }
  }

  // ─────────── Ajouter une observation à un tracker ───────────

  void _addObservationToTracker({
    required List<SpeciesTracker> trackers,
    required String species,
    required Map<int, int> regionColors,
  }) {
    var tracker = trackers.cast<SpeciesTracker?>().firstWhere(
          (t) => t?.species.toLowerCase() == species.toLowerCase(),
          orElse: () => null,
        );

    if (tracker == null) {
      tracker = SpeciesTracker(
        id: '${DateTime.now().microsecondsSinceEpoch}${trackers.length}',
        species: species,
        projectName: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bestStats: {},
        colorBank: {0: [], 1: [], 2: [], 3: [], 4: [], 5: []},
        anonymousStatEntries: [],
        colorObservations: [],
      );
      trackers.add(tracker);
    }

    tracker.colorObservations.add(ColorObservation(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      regionColors: regionColors,
      recordedAt: DateTime.now(),
    ));

    regionColors.forEach((region, colorId) {
      if (colorId > 0) {
        tracker!.colorBank.putIfAbsent(region, () => []);
        if (!tracker.colorBank[region]!.contains(colorId)) {
          tracker.colorBank[region]!.add(colorId);
        }
      }
    });
  }

  // ─────────── Parse Tags ───────────

  List<String> _parseTagsSheet(Sheet sheet) {
    final rows = sheet.rows;
    if (rows.isEmpty) return [];

    final result = <String>[];
    for (int i = 1; i < rows.length; i++) {
      if (rows[i].isEmpty) continue;
      final value = _cellToString(rows[i][0]).trim();
      if (value.isNotEmpty && !result.contains(value)) {
        result.add(value);
      }
    }
    return result;
  }

  // ─────────── Parse Trackers ───────────

  List<SpeciesTracker> _parseTrackersSheet(Sheet sheet, List<String> warnings) {
    final rows = sheet.rows;
    if (rows.isEmpty) return [];

    final headers = _headerMap(rows.first);
    final result = <SpeciesTracker>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final species = _get(row, headers, 'Species');
        if (species.isEmpty) continue;

        final idStr = _get(row, headers, 'Tracker ID');
        final id = idStr.isNotEmpty
            ? idStr
            : '${DateTime.now().microsecondsSinceEpoch}$i';

        result.add(
          SpeciesTracker(
            id: id,
            species: species,
            projectName: _emptyToNull(_get(row, headers, 'Project Name')),
            createdAt: DateTime.tryParse(_get(row, headers, 'Created At')) ?? DateTime.now(),
            updatedAt: DateTime.tryParse(_get(row, headers, 'Updated At')) ?? DateTime.now(),
            bestStats: {},
            colorBank: {0: [], 1: [], 2: [], 3: [], 4: [], 5: []},
            anonymousStatEntries: [],
            colorObservations: [],
          ),
        );
      } catch (e) {
        warnings.add('Tracker ligne ${i + 1} ignoré : $e');
      }
    }

    return result;
  }

  // ═══════════════════════════ HELPERS ═══════════════════════════

  void _writeHeader(Sheet sheet, List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
    }
  }

  void _writeRow(Sheet sheet, int rowIndex, List<dynamic> values) {
    for (int i = 0; i < values.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
      );
      cell.value = _toCellValue(values[i]);
    }
  }

  CellValue _toCellValue(dynamic value) {
    if (value == null) return TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is num) return DoubleCellValue(value.toDouble());
    return TextCellValue(value.toString());
  }

  Map<String, int> _headerMap(List<Data?> row) {
    final map = <String, int>{};
    for (int i = 0; i < row.length; i++) {
      final key = _cellToString(row[i]).trim();
      if (key.isNotEmpty) {
        map[key] = i;
      }
    }
    return map;
  }

  String _get(List<Data?> row, Map<String, int> headers, String key) {
    final index = headers[key];
    if (index == null || index >= row.length) return '';
    return _cellToString(row[index]);
  }

  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final v = cell.value.toString().trim();
    if (v == 'null' || v == 'nan' || v == 'NaN') return '';
    return v;
  }

  bool _isRowEmpty(List<Data?> row) {
    for (final cell in row) {
      if (_cellToString(cell).isNotEmpty) return false;
    }
    return true;
  }

  int? _safeInt(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim().replaceAll(',', '.');
    if (s.isEmpty || s == 'nan' || s == 'NaN' || s == 'null') return null;
    return int.tryParse(s) ?? double.tryParse(s)?.round();
  }

  double? _safeDouble(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim().replaceAll(',', '.');
    if (s.isEmpty || s == 'nan' || s == 'NaN' || s == 'null') return null;
    return double.tryParse(s);
  }

  String? _emptyToNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  String _buildImportedColor(int arkId) {
    if (arkId <= 0 || !ArkColorPalette.contains(arkId)) {
      return '0:#808080';
    }
    final hex = ArkColorPalette.idToHex(arkId) ?? '#808080';
    return '$arkId:$hex';
  }
}
