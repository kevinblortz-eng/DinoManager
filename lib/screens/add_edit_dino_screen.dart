// lib/screens/add_edit_dino_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ark_species_data.dart';
import '../models/ark_species_color_regions.dart';
import '../models/ark_species_group.dart';
import '../models/dino.dart';
import '../models/species_tracker.dart';
import '../providers/dino_provider.dart';
import '../providers/tracker_provider.dart';
import '../services/dino_scan_helper.dart';
import '../services/dino_ocr_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ark_color_picker.dart';
import '../widgets/dino_image_widget.dart';
import '../utils/dino_helpers.dart';

class AddEditDinoScreen extends StatefulWidget {
  final Dino? dino;
  final bool isDuplicate;
  final String? initialSpecies;

  const AddEditDinoScreen({
    super.key,
    this.dino,
    this.isDuplicate = false,
    this.initialSpecies,
  });

  @override
  State<AddEditDinoScreen> createState() => _AddEditDinoScreenState();
}

class _AddEditDinoScreenState extends State<AddEditDinoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomCtrl;
  late TextEditingController _niveauCtrl;
  late TextEditingController _notesCtrl;

  late TextEditingController _hpCtrl;
  late TextEditingController _staminaCtrl;
  late TextEditingController _oxygeneCtrl;
  late TextEditingController _nourritureCtrl;
  late TextEditingController _poidsCtrl;
  late TextEditingController _degatsCtrl;

  late TextEditingController _hpBaseCtrl;
  late TextEditingController _hpMutaCtrl;
  late TextEditingController _hpPersoCtrl;
  late TextEditingController _staminaBaseCtrl;
  late TextEditingController _staminaMutaCtrl;
  late TextEditingController _staminaPersoCtrl;
  late TextEditingController _oxygeneBaseCtrl;
  late TextEditingController _oxygeneMutaCtrl;
  late TextEditingController _oxygenePersoCtrl;
  late TextEditingController _nourritureBaseCtrl;
  late TextEditingController _nourritureMutaCtrl;
  late TextEditingController _nourriturePersoCtrl;
  late TextEditingController _poidsBaseCtrl;
  late TextEditingController _poidsMutaCtrl;
  late TextEditingController _poidsPersoCtrl;
  late TextEditingController _degatsBaseCtrl;
  late TextEditingController _degatsMutaCtrl;
  late TextEditingController _degatsPersoCtrl;

  late String _espece;
  late String _sexe;
  late String _role;
  late String _tagVersion;
  late List<String> _tags;

  late List<({int id, String hex})> _couleurs;

  bool _isSaving = false;
  bool _isScanning = false;

  int? _activeRegionIndex;

  // ───────────────────────────────────────────────────────────────────────
  // COLOR REPLICATION — Solid / SolidVisual
  // ───────────────────────────────────────────────────────────────────────

  /// Tags normalisés (lowercase, sans vides).
  List<String> get _normalizedTags =>
      _tags.map((t) => t.toLowerCase().trim()).where((t) => t.isNotEmpty).toList();

  /// Tag "solid" → la couleur choisie est répétée sur les 6 cases.
  bool get _isSolidTag => _normalizedTags.contains('solid');

  /// Tag "solidvisual" → la couleur est appliquée à toutes les cases visibles.
  /// Les cases invisibles seront remises à neutre à la sauvegarde.
  bool get _isSolidVisualTag =>
      _normalizedTags.contains('solidvisual') ||
      _normalizedTags.contains('visualsolid');

  /// Visibilité par défaut des 6 régions pour l'espèce courante.
  List<bool> get _speciesVisibility {
    try {
      final v = ArkSpeciesColorRegions.visibilityFor(_espece);
      if (v.length == 6) return v;
      // Pad / truncate à 6 si la source en renvoie autre chose.
      final out = List<bool>.filled(6, true);
      for (var i = 0; i < 6 && i < v.length; i++) {
        out[i] = v[i];
      }
      return out;
    } catch (_) {
      return const [true, true, true, true, true, true];
    }
  }

  /// Garantit 6 entrées dans `_couleurs`.
  void _ensureSixColorSlots() {
    while (_couleurs.length < 6) {
      _couleurs.add((id: 0, hex: '#808080'));
    }
    if (_couleurs.length > 6) {
      _couleurs = _couleurs.sublist(0, 6);
    }
  }

  /// Applique une couleur à l'index donné en respectant le tag actif.
  /// [value] = (id, hex). Pour "neutre", passer (id: 0, hex: '#808080').
  void _applyColor(int index, ({int id, String hex}) value) {
    setState(() {
      _ensureSixColorSlots();

      if (_isSolidTag) {
        for (var i = 0; i < 6; i++) {
          _couleurs[i] = value;
        }
        return;
      }

      if (_isSolidVisualTag) {
        final visible = _speciesVisibility;
        for (var i = 0; i < 6; i++) {
          if (visible[i]) {
            _couleurs[i] = value;
          }
        }
        // Si l'utilisateur tape DIRECTEMENT une case invisible, on respecte
        // son geste : on pose la couleur dessus. Elle sera nettoyée à la
        // sauvegarde par _finalizeColorsForSave() (sauf si la case est
        // redevenue visible entre‑temps).
        if (index >= 0 && index < 6 && !visible[index]) {
          _couleurs[index] = value;
        }
        return;
      }

      if (index >= 0 && index < 6) {
        _couleurs[index] = value;
      }
    });
  }

  /// Pose une couleur sans appliquer la règle solid/solidvisual.
  /// Utilisé par l'import OCR pour préserver la détection.
  void _applyColorForced(int index, ({int id, String hex}) value) {
    setState(() {
      _ensureSixColorSlots();
      if (index >= 0 && index < 6) {
        _couleurs[index] = value;
      }
    });
  }

  /// À appeler dans _buildDinoFromForm() avant d'écrire le Dino.
  /// SolidVisual : cases invisibles repassent à neutre.
  List<({int id, String hex})> _finalizeColorsForSave() {
    _ensureSixColorSlots();
    final out = List<({int id, String hex})>.from(_couleurs);

    if (_isSolidVisualTag) {
      final visible = _speciesVisibility;
      for (var i = 0; i < 6; i++) {
        if (!visible[i]) {
          out[i] = (id: 0, hex: '#808080');
        }
      }
    }
    return out;
  }

  /// Recalcule l'état couleur lorsque le tag change.
  void _onTagsChanged() {
    if (!mounted) return;
    _ensureSixColorSlots();

    if (_isSolidTag) {
      final base = _couleurs.firstWhere(
        (c) => c.id > 0 && c.hex != '#808080' && c.hex != '#7F7F7F',
        orElse: () => (id: 0, hex: '#808080'),
      );
      _applyColor(0, base);
      return;
    }

    if (_isSolidVisualTag) {
      final visible = _speciesVisibility;
      ({int id, String hex})? base;
      for (var i = 0; i < 6; i++) {
        final c = _couleurs[i];
        if (visible[i] &&
            c.id > 0 &&
            c.hex != '#808080' &&
            c.hex != '#7F7F7F') {
          base = c;
          break;
        }
      }
      if (base != null) _applyColor(0, base);
      return;
    }

    setState(() {}); // refresh affichage
  }

  // ─── Référentiel design (IDENTIQUE à ArkDinoCard) ──────────────────────
  static const double _refW = 242;
  static const double _refH = 428;

  static const List<String> _regionNames = ['0', '1', '2', '3', '4', '5'];

  // ═══════════════════════════════════════════════════════════════════════
  // FOND DYNAMIQUE — même logique que ArkDinoCard
  // ═══════════════════════════════════════════════════════════════════════
  String get _backgroundAssetPath {
    final group = ArkSpeciesGroupData.groupFor(_espece);
    switch (group) {
      case ArkSpeciesGroup.terrestre:
        return 'assets/images/ui/share_card_portrait_bg_terrestre.png';
      case ArkSpeciesGroup.aquatic:
        return 'assets/images/ui/share_card_portrait_bg_aqua.png';
      case ArkSpeciesGroup.volant:
        return 'assets/images/ui/share_card_portrait_bg_air.png';
      case ArkSpeciesGroup.fantastic:
        return 'assets/images/ui/share_card_portrait_bg_fantastic.png';
      case ArkSpeciesGroup.compagnon:
        return 'assets/images/ui/share_card_portrait_bg_compagnon.png';
    }
  }

  static const String _fallbackAssetPath =
      'assets/images/ui/share_card_portrait_bg.png';

  double _parseDouble(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.')) ?? 0.0;
  }

  Map<String, List<int>> _parsePointsFromNotes(String? notes) {
    final result = <String, List<int>>{};
    if (notes == null) return result;
    final regex = RegExp(r'\[PTS:(.+?)\]');
    final match = regex.firstMatch(notes);
    if (match == null) return result;

    final content = match.group(1)!;
    for (final part in content.split(',')) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final key = kv[0].trim();
      final values = kv[1].trim().split('/');
      if (values.length == 3) {
        result[key] = [
          int.tryParse(values[0]) ?? 0,
          int.tryParse(values[1]) ?? 0,
          int.tryParse(values[2]) ?? 0,
        ];
      }
    }
    return result;
  }

  String _buildPointsBlock() {
    final entries = <String>[];
    void add(String key, TextEditingController b, TextEditingController m,
        TextEditingController p) {
      final bv = int.tryParse(b.text.trim()) ?? 0;
      final mv = int.tryParse(m.text.trim()) ?? 0;
      final pv = int.tryParse(p.text.trim()) ?? 0;
      if (bv > 0 || mv > 0 || pv > 0) {
        entries.add('$key=$bv/$mv/$pv');
      }
    }

    add('hp', _hpBaseCtrl, _hpMutaCtrl, _hpPersoCtrl);
    add('stamina', _staminaBaseCtrl, _staminaMutaCtrl, _staminaPersoCtrl);
    add('oxygene', _oxygeneBaseCtrl, _oxygeneMutaCtrl, _oxygenePersoCtrl);
    add('nourriture', _nourritureBaseCtrl, _nourritureMutaCtrl,
        _nourriturePersoCtrl);
    add('poids', _poidsBaseCtrl, _poidsMutaCtrl, _poidsPersoCtrl);
    add('degats', _degatsBaseCtrl, _degatsMutaCtrl, _degatsPersoCtrl);

    if (entries.isEmpty) return '';
    return '[PTS:${entries.join(',')}]';
  }

  @override
  void initState() {
    super.initState();
    final d = widget.dino;
    final pts = _parsePointsFromNotes(d?.notes);

    _nomCtrl = TextEditingController(
      text: widget.isDuplicate && d != null
          ? '${d.nom} (copie)'
          : (d?.nom ?? ''),
    );
    _niveauCtrl = TextEditingController(
      text: d != null ? d.niveau.toString() : '0',
    );

    final rawNotes = d?.notes ?? '';
    final cleanNotes = rawNotes.replaceAll(RegExp(r'\[PTS:.+?\]'), '').trim();
    _notesCtrl = TextEditingController(text: cleanNotes);

    _hpCtrl = TextEditingController(text: d != null ? '${d.hp}' : '');
    _staminaCtrl = TextEditingController(text: d != null ? '${d.stamina}' : '');
    _oxygeneCtrl = TextEditingController(text: d != null ? '${d.oxygene}' : '');
    _nourritureCtrl =
        TextEditingController(text: d != null ? '${d.nourriture}' : '');
    _poidsCtrl = TextEditingController(text: d != null ? '${d.poids}' : '');
    _degatsCtrl = TextEditingController(text: d != null ? '${d.degats}' : '');

    _hpBaseCtrl = TextEditingController(text: '${pts['hp']?[0] ?? 0}');
    _hpMutaCtrl = TextEditingController(text: '${pts['hp']?[1] ?? 0}');
    _hpPersoCtrl = TextEditingController(text: '${pts['hp']?[2] ?? 0}');

    _staminaBaseCtrl =
        TextEditingController(text: '${pts['stamina']?[0] ?? 0}');
    _staminaMutaCtrl =
        TextEditingController(text: '${pts['stamina']?[1] ?? 0}');
    _staminaPersoCtrl =
        TextEditingController(text: '${pts['stamina']?[2] ?? 0}');

    _oxygeneBaseCtrl =
        TextEditingController(text: '${pts['oxygene']?[0] ?? 0}');
    _oxygeneMutaCtrl =
        TextEditingController(text: '${pts['oxygene']?[1] ?? 0}');
    _oxygenePersoCtrl =
        TextEditingController(text: '${pts['oxygene']?[2] ?? 0}');

    _nourritureBaseCtrl =
        TextEditingController(text: '${pts['nourriture']?[0] ?? 0}');
    _nourritureMutaCtrl =
        TextEditingController(text: '${pts['nourriture']?[1] ?? 0}');
    _nourriturePersoCtrl =
        TextEditingController(text: '${pts['nourriture']?[2] ?? 0}');

    _poidsBaseCtrl = TextEditingController(text: '${pts['poids']?[0] ?? 0}');
    _poidsMutaCtrl = TextEditingController(text: '${pts['poids']?[1] ?? 0}');
    _poidsPersoCtrl = TextEditingController(text: '${pts['poids']?[2] ?? 0}');

    _degatsBaseCtrl =
        TextEditingController(text: '${pts['degats']?[0] ?? 0}');
    _degatsMutaCtrl =
        TextEditingController(text: '${pts['degats']?[1] ?? 0}');
    _degatsPersoCtrl =
        TextEditingController(text: '${pts['degats']?[2] ?? 0}');

    _espece = d?.espece ?? widget.initialSpecies ?? 'Rex';
    _sexe = d?.sexe ?? 'Inconnu';
    _role = d?.role ?? 'Breed';
    _tagVersion = d?.tagVersion ?? '';
    _tags = List<String>.from(d?.tags ?? []);

    if (d != null) {
      _couleurs = [
        (id: d.colorId0, hex: d.colorHex0),
        (id: d.colorId1, hex: d.colorHex1),
        (id: d.colorId2, hex: d.colorHex2),
        (id: d.colorId3, hex: d.colorHex3),
        (id: d.colorId4, hex: d.colorHex4),
        (id: d.colorId5, hex: d.colorHex5),
      ];
    } else {
      _couleurs = List.generate(6, (_) => (id: 0, hex: '#808080'));
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _niveauCtrl.dispose();
    _notesCtrl.dispose();
    _hpCtrl.dispose();
    _staminaCtrl.dispose();
    _oxygeneCtrl.dispose();
    _nourritureCtrl.dispose();
    _poidsCtrl.dispose();
    _degatsCtrl.dispose();
    _hpBaseCtrl.dispose();
    _hpMutaCtrl.dispose();
    _hpPersoCtrl.dispose();
    _staminaBaseCtrl.dispose();
    _staminaMutaCtrl.dispose();
    _staminaPersoCtrl.dispose();
    _oxygeneBaseCtrl.dispose();
    _oxygeneMutaCtrl.dispose();
    _oxygenePersoCtrl.dispose();
    _nourritureBaseCtrl.dispose();
    _nourritureMutaCtrl.dispose();
    _nourriturePersoCtrl.dispose();
    _poidsBaseCtrl.dispose();
    _poidsMutaCtrl.dispose();
    _poidsPersoCtrl.dispose();
    _degatsBaseCtrl.dispose();
    _degatsMutaCtrl.dispose();
    _degatsPersoCtrl.dispose();
    super.dispose();
  }

  Color get _roleColor {
    switch (_role.toLowerCase()) {
      case 'boss':
        return Colors.redAccent;
      case 'solid':
        return Colors.purpleAccent;
      case 'breed':
        return Colors.cyanAccent;
      case 'farm':
        return Colors.greenAccent;
      case 'collection':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  Dino _buildDinoFromForm() {
    final rolesCompatibles = ['Boss', 'Breed', 'Solid', 'Farm', 'Collection'];
    final roleFromTag = _tags.firstWhere(
      (t) => rolesCompatibles.contains(t),
      orElse: () => _role,
    );

    final bool isNewDino = widget.dino == null || widget.isDuplicate;

    final userNotes = _notesCtrl.text.trim();
    final ptsBlock = _buildPointsBlock();
    final finalNotes =
        ptsBlock.isNotEmpty ? '$userNotes\n$ptsBlock' : userNotes;

    int totalPts(TextEditingController b, TextEditingController m,
        TextEditingController p) {
      return (int.tryParse(b.text.trim()) ?? 0) +
          (int.tryParse(m.text.trim()) ?? 0) +
          (int.tryParse(p.text.trim()) ?? 0);
    }

    // Application de la règle Solid / SolidVisual au moment de sauver.
    final finalColors = _finalizeColorsForSave();

    return Dino(
      id: isNewDino ? null : widget.dino!.id,
      nom: _nomCtrl.text.trim(),
      espece: _espece,
      sexe: _sexe,
      role: roleFromTag,
      niveau: int.tryParse(_niveauCtrl.text.trim()) ?? 0,
      hp: _parseDouble(_hpCtrl.text).round(),
      stamina: _parseDouble(_staminaCtrl.text).round(),
      oxygene: _parseDouble(_oxygeneCtrl.text).round(),
      nourriture: _parseDouble(_nourritureCtrl.text).round(),
      poids: _parseDouble(_poidsCtrl.text).round(),
      degats: _parseDouble(_degatsCtrl.text),
      vitesse: 100.0,
      hpPoints: totalPts(_hpBaseCtrl, _hpMutaCtrl, _hpPersoCtrl),
      staminaPoints:
          totalPts(_staminaBaseCtrl, _staminaMutaCtrl, _staminaPersoCtrl),
      oxygenePoints:
          totalPts(_oxygeneBaseCtrl, _oxygeneMutaCtrl, _oxygenePersoCtrl),
      nourriturePoints: totalPts(
          _nourritureBaseCtrl, _nourritureMutaCtrl, _nourriturePersoCtrl),
      poidsPoints: totalPts(_poidsBaseCtrl, _poidsMutaCtrl, _poidsPersoCtrl),
      degatsPoints:
          totalPts(_degatsBaseCtrl, _degatsMutaCtrl, _degatsPersoCtrl),
      vitessePoints: 0,
      couleur0: Dino.encodeColor(finalColors[0].id, finalColors[0].hex),
      couleur1: Dino.encodeColor(finalColors[1].id, finalColors[1].hex),
      couleur2: Dino.encodeColor(finalColors[2].id, finalColors[2].hex),
      couleur3: Dino.encodeColor(finalColors[3].id, finalColors[3].hex),
      couleur4: Dino.encodeColor(finalColors[4].id, finalColors[4].hex),
      couleur5: Dino.encodeColor(finalColors[5].id, finalColors[5].hex),
      tagVersion: _tagVersion,
      tags: List<String>.from(_tags),
      notes: finalNotes,
      dateAjout: (widget.dino == null || widget.isDuplicate)
          ? DateTime.now()
          : widget.dino!.dateAjout,
    );
  }

  // ─────────────── SCANNER OCR ───────────────

  Future<void> _launchScanner() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final result = await DinoScanHelper.launchScan(context);
      if (result == null) return;
      if (!mounted) return;

      final confirmed = await _showScanResultDialog(result);
      if (confirmed != true) return;
      if (!mounted) return;

      setState(() {
        if (result.species != null) _espece = result.species!;
        if (result.level != null) _niveauCtrl.text = result.level.toString();

        if (result.sex != null) {
          if (result.sex!.contains('♀')) {
            _sexe = 'Femelle';
          } else if (result.sex!.contains('♂')) {
            _sexe = 'Mâle';
          }
        }

        final imprint = result.imprintPercent ?? 0;
        final imprintMultiplier = 1.0 + (0.2 * imprint / 100.0);

        if (result.hp?.maxValue != null) {
          final raw = result.hp!.maxValue!;
          final corrected = imprint > 0 ? raw / imprintMultiplier : raw;
          _hpCtrl.text = corrected.round().toString();
        }
        if (result.stamina?.maxValue != null) {
          final raw = result.stamina!.maxValue!;
          final corrected = imprint > 0 ? raw / imprintMultiplier : raw;
          _staminaCtrl.text = corrected.round().toString();
        }
        if (result.oxygen?.maxValue != null) {
          _oxygeneCtrl.text = result.oxygen!.maxValue!.round().toString();
        }
        if (result.food?.maxValue != null) {
          _nourritureCtrl.text = result.food!.maxValue!.round().toString();
        }
        if (result.weight?.maxValue != null) {
          final raw = result.weight!.maxValue!;
          final corrected = imprint > 0 ? raw / imprintMultiplier : raw;
          _poidsCtrl.text = corrected.round().toString();
        }
        if (result.melee?.maxValue != null) {
          final raw = result.melee!.maxValue!;
          final corrected = imprint > 0 ? raw / imprintMultiplier : raw;
          _degatsCtrl.text = corrected.toStringAsFixed(1);
        }

        if (result.hp != null) {
          _hpBaseCtrl.text = '${result.hp!.wildPoints ?? 0}';
        }
        if (result.stamina != null) {
          _staminaBaseCtrl.text = '${result.stamina!.wildPoints ?? 0}';
        }
        if (result.oxygen != null) {
          _oxygeneBaseCtrl.text = '${result.oxygen!.wildPoints ?? 0}';
        }
        if (result.food != null) {
          _nourritureBaseCtrl.text = '${result.food!.wildPoints ?? 0}';
        }
        if (result.weight != null) {
          _poidsBaseCtrl.text = '${result.weight!.wildPoints ?? 0}';
        }
        if (result.melee != null) {
          _degatsBaseCtrl.text = '${result.melee!.wildPoints ?? 0}';
        }

        if (result.speed?.maxValue != null) {
          final speedVal = result.speed!.maxValue!;
          final existing = _notesCtrl.text;
          if (!existing.contains('Vitesse')) {
            _notesCtrl.text = existing.isNotEmpty
                ? '$existing\nVitesse: ${speedVal.toStringAsFixed(1)}%'
                : 'Vitesse: ${speedVal.toStringAsFixed(1)}%';
          }
        }

        // Import OCR : on conserve EXACTEMENT ce qui a été détecté,
        // sans appliquer la règle solid/solidvisual.
        for (int i = 0; i < 6; i++) {
          final colorId = result.colorIds[i];
          if (colorId > 0) {
            final hex = DinoScanHelper.getColorHex(colorId);
            _applyColorForced(i, (id: colorId, hex: hex));
          }
        }

        if (result.status != null) {
          if (result.status!.toLowerCase().contains('badass') &&
              !_tags.contains('Badass')) {
            _tags.add('Badass');
          }
        }
        if ((result.mutationsMale ?? 0) > 0 ||
            (result.mutationsFemale ?? 0) > 0) {
          if (!_tags.contains('Mutant')) _tags.add('Mutant');
        }

        final notesParts = <String>[];
        notesParts.add('Import OCR (${result.sourceType.label})');
        if (imprint > 0) {
          notesParts.add(
            'Imprint: ${imprint.toStringAsFixed(1)}%'
            '${result.imprinter != null ? ' - ${result.imprinter}' : ''}',
          );
          notesParts
              .add('⚠️ Stats HP/Stam/Weight/Melee corrigées à 0% imprint');
        }
        if (result.mutationsMale != null || result.mutationsFemale != null) {
          notesParts.add(
              'Mutations: ♂${result.mutationsMale ?? '?'} ♀${result.mutationsFemale ?? '?'}');
        }
        _notesCtrl.text = notesParts.join('\n');
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Données importées (${result.sourceType.label})'
            '${(result.imprintPercent ?? 0) > 0 ? ' — stats corrigées imprint' : ''}'
            ' — vérifiez et sauvegardez',
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur scanner : $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<bool?> _showScanResultDialog(DinoOcrResult result) {
    final imprint = result.imprintPercent ?? 0;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.document_scanner_rounded,
                color: Colors.greenAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Scan détecté — ${result.sourceType.label}',
                style: GoogleFonts.exo2(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.species != null) _scanRow('Espèce', result.species!),
              if (result.level != null) _scanRow('Niveau', '${result.level}'),
              if (result.sex != null) _scanRow('Sexe', result.sex!),
              if (result.status != null) _scanRow('Statut', result.status!),
              if (imprint > 0)
                _scanRow('Imprint', '${imprint.toStringAsFixed(1)}%',
                    warn: true),
              const Divider(color: Colors.white24, height: 16),
              if (result.hp?.maxValue != null)
                _scanRow(
                    'HP',
                    '${result.hp!.maxValue!.round()}'
                    '${result.hp!.wildPoints != null ? '  [${result.hp!.wildPoints}pts]' : ''}'),
              if (result.stamina?.maxValue != null)
                _scanRow(
                    'Stamina',
                    '${result.stamina!.maxValue!.round()}'
                    '${result.stamina!.wildPoints != null ? '  [${result.stamina!.wildPoints}pts]' : ''}'),
              if (result.oxygen?.maxValue != null)
                _scanRow('Oxygène', '${result.oxygen!.maxValue!.round()}'),
              if (result.food?.maxValue != null)
                _scanRow('Nourriture', '${result.food!.maxValue!.round()}'),
              if (result.weight?.maxValue != null)
                _scanRow('Poids', '${result.weight!.maxValue!.round()}'),
              if (result.melee?.maxValue != null)
                _scanRow('Attaque',
                    '${result.melee!.maxValue!.toStringAsFixed(1)}%'),
              if (result.colorIds.any((id) => id > 0)) ...[
                const Divider(color: Colors.white24, height: 16),
                _scanRow(
                    'Couleurs',
                    result.colorIds
                        .map((id) => id > 0 ? '#$id' : '-')
                        .join('  ')),
              ],
              if (result.mutationsMale != null ||
                  result.mutationsFemale != null) ...[
                const Divider(color: Colors.white24, height: 16),
                _scanRow('Mutations',
                    '♂${result.mutationsMale ?? '?'}  ♀${result.mutationsFemale ?? '?'}'),
              ],
              if (imprint > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '⚠️ Imprint détecté : HP, Stam, Poids et Attaque '
                    'seront automatiquement corrigés à 0% imprint.',
                    style: GoogleFonts.exo2(
                      color: Colors.orange,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Appliquer',
                style: GoogleFonts.exo2(
                    fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _scanRow(String label, String value, {bool warn = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.exo2(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.exo2(
                color: warn ? Colors.orange : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── SAUVEGARDE ───────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final provider = context.read<DinoProvider>();
    final dino = _buildDinoFromForm();

    final bool success = dino.id == null
        ? await provider.addDino(dino)
        : await provider.updateDino(dino);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      await provider.loadDinos();
      if (!mounted) return;

      final dinoName = dino.nom.isNotEmpty ? dino.nom : dino.espece;
      final message = widget.isDuplicate
          ? '$dinoName dupliqué !'
          : widget.dino == null
              ? '$dinoName ajouté !'
              : '$dinoName mis à jour !';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context, dino);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _registerStatsToTracker() async {
    final tp = context.read<TrackerProvider>();
    SpeciesTracker? tracker = tp.trackers.cast<SpeciesTracker?>().firstWhere(
          (t) => t?.species.toLowerCase() == _espece.toLowerCase(),
          orElse: () => null,
        );
    if (tracker == null) {
      try {
        await tp.createTracker(_espece, '');
        tracker = tp.trackers.cast<SpeciesTracker?>().firstWhere(
              (t) => t?.species.toLowerCase() == _espece.toLowerCase(),
              orElse: () => null,
            );
      } catch (_) {}
    }
    if (tracker == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de créer le tracker'),
          backgroundColor: AppTheme.danger));
      return;
    }
    final stats = <String, double>{};
    final m = {
      'hp': _hpCtrl,
      'stamina': _staminaCtrl,
      'oxygene': _oxygeneCtrl,
      'nourriture': _nourritureCtrl,
      'poids': _poidsCtrl,
      'degats': _degatsCtrl,
    };
    m.forEach((k, c) {
      final v = _parseDouble(c.text);
      if (v > 0) stats[k] = v;
    });
    if (stats.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucune stat à enregistrer'),
          backgroundColor: ui.Color.fromARGB(255, 0, 0, 0)));
      return;
    }
    await tp.registerAnonymousStats(trackerId: tracker.id, stats: stats);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${stats.length} stats → tracker'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _registerColorsToTracker() async {
    final tp = context.read<TrackerProvider>();
    final hasAny = _couleurs.any((c) => c.id > 0);
    if (!hasAny) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucune couleur à enregistrer'),
          backgroundColor: ui.Color.fromARGB(255, 0, 0, 0)));
      return;
    }
    SpeciesTracker? tracker = tp.trackers.cast<SpeciesTracker?>().firstWhere(
          (t) => t?.species.toLowerCase() == _espece.toLowerCase(),
          orElse: () => null,
        );
    if (tracker == null) {
      try {
        await tp.createTracker(_espece, '');
        tracker = tp.trackers.cast<SpeciesTracker?>().firstWhere(
              (t) => t?.species.toLowerCase() == _espece.toLowerCase(),
              orElse: () => null,
            );
      } catch (_) {}
    }
    if (tracker == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de créer le tracker'),
          backgroundColor: AppTheme.danger));
      return;
    }
    final regionColors = <int, int>{};
    for (int i = 0; i < 6; i++) {
      if (_couleurs[i].id > 0) regionColors[i] = _couleurs[i].id;
    }
    await tp.saveAnonymousColorObservation(
        trackerId: tracker.id, regionColors: regionColors);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Couleurs → tracker $_espece'),
      backgroundColor: AppTheme.success,
    ));
  }

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final niveau = int.tryParse(_niveauCtrl.text) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isScanning
                    ? Colors.greenAccent.withValues(alpha: 0.6)
                    : Colors.greenAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.greenAccent,
                      ),
                    )
                  : const Icon(Icons.document_scanner_rounded,
                      color: Colors.greenAccent),
              tooltip: 'Scanner Cryopod / Tek Jumelles',
              onPressed: _isScanning ? null : _launchScanner,
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
            child: Column(
              children: [
                _buildWysiwygPreview(niveau),
                const SizedBox(height: 16),
                if (_activeRegionIndex != null) ...[
                  _buildRegionPreview(_activeRegionIndex!),
                  const SizedBox(height: 12),
                ],
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PREVIEW WYSIWYG ÉDITABLE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWysiwygPreview(int niveau) {
    return AspectRatio(
      aspectRatio: _refW / _refH,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final scale = w / _refW;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  _backgroundAssetPath,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => Image.asset(
                    _fallbackAssetPath,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => _fallbackBackground(),
                  ),
                ),
              ),
              _posCentered(
                cx: 123, cy: 115, w: 169, h: 202, scale: scale,
                child: GestureDetector(
                  onTap: _showSpeciesPickerDialog,
                  child: _buildEggImage(),
                ),
              ),
              _posCentered(
                cx: 30, cy: 35, w: 32, h: 32, scale: scale,
                child: GestureDetector(
                  onTap: () => _inlineEdit(_niveauCtrl),
                  child: _buildLvlBadge(niveau, scale),
                ),
              ),
              _posCentered(
                cx: 215, cy: 36, w: 32, h: 32, scale: scale,
                child: GestureDetector(
                  onTap: _cycleSexe,
                  child: _buildSexBadgePreview(scale),
                ),
              ),
              _posCentered(
                cx: 123, cy: 218, w: 170, h: 32, scale: scale,
                child: GestureDetector(
                  onTap: _showSpeciesPickerDialog,
                  child: _buildSpeciesText(scale),
                ),
              ),
              _posCentered(
                cx: 123, cy: 243, w: 130, h: 18, scale: scale,
                child: _buildNameAndTag(scale),
              ),
              ..._buildAllStatCells(scale),
              ..._buildAllColorSquares(scale),
            ],
          );
        },
      ),
    );
  }

  Widget _posCentered({
    required double cx,
    required double cy,
    required double w,
    required double h,
    required double scale,
    required Widget child,
  }) {
    return Positioned(
      left: (cx - w / 2) * scale,
      top: (cy - h / 2) * scale,
      width: w * scale,
      height: h * scale,
      child: child,
    );
  }

  Widget _fallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1A4A), Color(0xFF1A1230)],
        ),
      ),
    );
  }

  Widget _buildEggImage() {
    final existingImage = widget.dino?.image;
    final hasCustomImage =
        existingImage != null && existingImage.isNotEmpty;
    final hexColors = _couleurs.map((c) => c.hex).toList();

    Widget speciesImg() => DinoImageWidget(
          species: _espece,
          regionColors: hexColors,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          showColorBand: false,
          alignment: Alignment.center,
        );

    Widget blurredCopy() {
      Widget img = hasCustomImage
          ? Image.file(
              File(existingImage),
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => speciesImg(),
            )
          : speciesImg();

      return IgnorePointer(
        child: Opacity(
          opacity: 0.10,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
              tileMode: TileMode.decal,
            ),
            child: Transform.scale(scale: 1.10, child: img),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _OvalGlowPainter(
                glowColor: Colors.black.withValues(alpha: 0.45),
                edgeColor: Colors.transparent,
              ),
            ),
          ),
        ),
        Positioned.fill(child: blurredCopy()),
        Positioned.fill(
          child: hasCustomImage
              ? Image.file(
                  File(existingImage),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => speciesImg(),
                )
              : speciesImg(),
        ),
      ],
    );
  }

  Widget _buildLvlBadge(int niveau, double scale) {
    final c = DinoHelpers.getCardRarityColor(niveau);
    final clamped = scale.clamp(1.0, 3.5);
    final fontLvl = 6.0 * clamped;
    final fontNum = (niveau >= 1000 ? 9.0 : 11.0) * clamped;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: c, width: 1.5 * scale.clamp(1.0, 2.5)),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.6),
            blurRadius: 6 * scale.clamp(1.0, 3.0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LVL',
            style: GoogleFonts.exo2(
              color: c.withValues(alpha: 0.85),
              fontSize: fontLvl,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            '$niveau',
            style: GoogleFonts.exo2(
              color: c,
              fontSize: fontNum,
              fontWeight: FontWeight.w900,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexBadgePreview(double scale) {
    final sexeColor = _sexeColorValue();
    final symbol = _sexeDisplay();
    final clamped = scale.clamp(1.0, 3.5);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sexeColor.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(
          color: sexeColor.withValues(alpha: 0.75),
          width: 1.5 * scale.clamp(1.0, 2.5),
        ),
        boxShadow: [
          BoxShadow(
            color: sexeColor.withValues(alpha: 0.45),
            blurRadius: 6 * scale.clamp(1.0, 3.0),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            symbol,
            style: TextStyle(
              color: sexeColor,
              fontSize: 14 * clamped,
              fontWeight: FontWeight.w900,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeciesText(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = DinoHelpers.toTitleCase(_espece);
          const double maxFont = 22.0;
          const double minFont = 11.0;
          final style = GoogleFonts.cinzelDecorative(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            height: 1.0,
          );
          double fontSize = maxFont;
          while (fontSize > minFont) {
            final tp = TextPainter(
              text: TextSpan(
                text: text,
                style: style.copyWith(fontSize: fontSize),
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout();
            if (tp.width <= constraints.maxWidth &&
                tp.height <= constraints.maxHeight) {
              break;
            }
            fontSize -= 0.5;
          }
          return Center(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style.copyWith(
                fontSize: fontSize,
                color: const Color.fromARGB(255, 0, 0, 0),
                decoration: TextDecoration.none,
                shadows: const [
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 1.5,
                    offset: Offset(0, 0.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNameAndTag(double scale) {
    final hasTag = _tags.isNotEmpty;
    final tagLbl = hasTag ? _tags.first : 'TAG';
    final tagCol =
        hasTag ? _tagColor(tagLbl) : Colors.white.withValues(alpha: 0.5);
    final hasName = _nomCtrl.text.trim().isNotEmpty;
    final displayName = hasName ? _nomCtrl.text : 'Tap pour nommer';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _editField('Nom du dinosaure', _nomCtrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  displayName,
                  style: GoogleFonts.exo2(
                    color: hasName
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1.0,
                    letterSpacing: 0.3,
                    fontStyle:
                        hasName ? FontStyle.normal : FontStyle.italic,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: _editTags,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: tagCol.withValues(alpha: hasTag ? 0.25 : 0.10),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: tagCol.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  tagLbl.toUpperCase(),
                  style: TextStyle(
                    color: tagCol,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.0,
                    fontStyle:
                        hasTag ? FontStyle.normal : FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'boss':
        return const Color(0xFFEF4444);
      case 'breeding':
      case 'breed':
        return const Color(0xFFF48FB1);
      case 'solid':
        return const Color(0xFFFFD700);
      case 'solidvisual':
        return const Color(0xFFFFD700);
      case 'farm':
        return const Color(0xFF4CAF50);
      case 'collection':
        return const Color(0xFF8B5CF6);
      case 'combat':
        return const Color(0xFFFF6B00);
      case 'jokermut':
      case 'monstermut':
        return const Color(0xFF22D3EE);
      default:
        return _roleColor;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllStatCells(double scale) {
    final cells = <_EditableStatCellData>[
      _EditableStatCellData(
        cx: 48, cy: 291,
        emoji: '❤️', label: 'VIE',
        color: const Color(0xFF4CAF50),
        valCtrl: _hpCtrl,
        baseCtrl: _hpBaseCtrl,
        mutaCtrl: _hpMutaCtrl,
        persoCtrl: _hpPersoCtrl,
      ),
      _EditableStatCellData(
        cx: 123, cy: 291,
        emoji: '⚡', label: 'STAM',
        color: const Color(0xFFFFD700),
        valCtrl: _staminaCtrl,
        baseCtrl: _staminaBaseCtrl,
        mutaCtrl: _staminaMutaCtrl,
        persoCtrl: _staminaPersoCtrl,
      ),
      _EditableStatCellData(
        cx: 200, cy: 291,
        emoji: '⚔️', label: 'ATTACK',
        color: const Color(0xFFEF4444),
        valCtrl: _degatsCtrl,
        baseCtrl: _degatsBaseCtrl,
        mutaCtrl: _degatsMutaCtrl,
        persoCtrl: _degatsPersoCtrl,
        suffix: '%',
      ),
      _EditableStatCellData(
        cx: 48, cy: 351,
        emoji: '⚖️', label: 'POIDS',
        color: const Color(0xFF3B82F6),
        valCtrl: _poidsCtrl,
        baseCtrl: _poidsBaseCtrl,
        mutaCtrl: _poidsMutaCtrl,
        persoCtrl: _poidsPersoCtrl,
      ),
      _EditableStatCellData(
        cx: 125, cy: 351,
        emoji: '🍖', label: 'FOOD',
        color: const Color(0xFF8B5CF6),
        valCtrl: _nourritureCtrl,
        baseCtrl: _nourritureBaseCtrl,
        mutaCtrl: _nourritureMutaCtrl,
        persoCtrl: _nourriturePersoCtrl,
      ),
      _EditableStatCellData(
        cx: 200, cy: 351,
        emoji: '🫧', label: 'OXY',
        color: const Color(0xFF10B981),
        valCtrl: _oxygeneCtrl,
        baseCtrl: _oxygeneBaseCtrl,
        mutaCtrl: _oxygeneMutaCtrl,
        persoCtrl: _oxygenePersoCtrl,
      ),
    ];

    return cells.map((c) {
      return _posCentered(
        cx: c.cx, cy: c.cy, w: 50, h: 47, scale: scale,
        child: _buildEditableStatCell(c, scale),
      );
    }).toList();
  }

  Widget _buildEditableStatCell(_EditableStatCellData c, double scale) {
    const double rowLabel = 13.0;
    const double rowValue = 18.0;
    const double rowPoints = 12.0;

    final valNum = _parseDouble(c.valCtrl.text);
    final hasValue = valNum > 0;
    final String displayVal;
    if (!hasValue) {
      displayVal = '  x  ';
    } else if (c.suffix != null) {
      displayVal = valNum == valNum.roundToDouble()
          ? '${valNum.round()}${c.suffix}'
          : '${valNum.toStringAsFixed(1)}${c.suffix}';
    } else {
      displayVal = valNum == valNum.roundToDouble()
          ? DinoHelpers.formatNumber(valNum.round())
          : valNum.toStringAsFixed(1);
    }
    final effColor = hasValue ? c.color : c.color.withValues(alpha: 0.50);

    final base = int.tryParse(c.baseCtrl.text.trim()) ?? 0;
    final muta = int.tryParse(c.mutaCtrl.text.trim()) ?? 0;
    final perso = int.tryParse(c.persoCtrl.text.trim()) ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 2 * scale,
        vertical: 1 * scale,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: rowLabel * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.emoji,
                      style: const TextStyle(fontSize: 15, height: 1.0)),
                  const SizedBox(width: 2),
                  Text(
                    c.label,
                    style: GoogleFonts.exo2(
                      color: Colors.white
                          .withValues(alpha: hasValue ? 0.85 : 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: rowValue * scale,
            child: GestureDetector(
              onTap: () => _inlineEdit(c.valCtrl, isStat: true),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2 * scale),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.6,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    displayVal,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(
                      color: effColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      decoration: TextDecoration.none,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: rowPoints * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniPtsCell(c.baseCtrl, base, 'B',
                      const Color(0xFF00E5FF)),
                  const SizedBox(width: 2),
                  _miniPtsCell(c.mutaCtrl, muta, 'M',
                      const Color(0xFFFF6B00)),
                  const SizedBox(width: 2),
                  _miniPtsCell(c.persoCtrl, perso, 'P',
                      const Color(0xFF4CAF50)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPtsCell(
    TextEditingController ctrl,
    int value,
    String hint,
    Color color,
  ) {
    final hasVal = value > 0;
    return GestureDetector(
      onTap: () => _inlineEdit(ctrl, hint: hint),
      child: Container(
        constraints: const BoxConstraints(minWidth: 14, minHeight: 11),
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
        decoration: BoxDecoration(
          color: hasVal
              ? color.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: hasVal
                ? color.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          hasVal ? '$value' : hint,
          style: GoogleFonts.exo2(
            color: hasVal ? color : Colors.white.withValues(alpha: 0.55),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            height: 1.0,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Future<void> _inlineEdit(
    TextEditingController ctrl, {
    String? hint,
    bool isStat = false,
  }) async {
    final tempCtrl =
        TextEditingController(text: ctrl.text == '0' ? '' : ctrl.text);
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1E28),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 80),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    hint == 'B'
                        ? 'Points Base'
                        : hint == 'M'
                            ? 'Points Muta'
                            : hint == 'P'
                                ? 'Points Perso'
                                : hint,
                    style: GoogleFonts.exo2(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              TextField(
                controller: tempCtrl,
                autofocus: true,
                keyboardType: isStat
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                inputFormatters: isStat
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]
                    : [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0A0E1A),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Annuler',
                        style: GoogleFonts.exo2(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, tempCtrl.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('OK',
                        style: GoogleFonts.exo2(
                            fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    tempCtrl.dispose();

    if (result != null) {
      setState(() {
        ctrl.text = result.isEmpty ? '0' : result;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CARRÉS DE COULEUR
  // ═══════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllColorSquares(double scale) {
    final visibility = _speciesVisibility;
    final xs = [34.0, 69.0, 105.0, 140.0, 176.0, 211.0];

    return List.generate(6, (i) {
      final isZoneActive = i < visibility.length ? visibility[i] : true;
      final c = _couleurs[i];
      final isNeutral =
          c.id <= 0 || c.hex == '#808080' || c.hex == '#7F7F7F';
      final parsed = isNeutral ? null : _parseHex(c.hex);

      return _posCentered(
        cx: xs[i], cy: 400, w: 22, h: 22, scale: scale,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showArkColorPicker(i),
          onLongPress: () {
            _applyColor(i, (id: 0, hex: '#808080'));
            if (_activeRegionIndex == i) {
              setState(() => _activeRegionIndex = null);
            }
          },
          child: _buildColorSquarePreview(
            color: parsed,
            colorId: c.id,
            isZoneActive: isZoneActive,
            isNeutral: isNeutral,
            isSelected: _activeRegionIndex == i,
          ),
        ),
      );
    });
  }

  Widget _buildColorSquarePreview({
    required Color? color,
    required int colorId,
    required bool isZoneActive,
    required bool isNeutral,
    required bool isSelected,
  }) {
    const double radius = 6.0;

   
    // ─── Indicateur "+" : case vide, peu importe que la région soit
    //     active ou non. Disparaît dès qu'une couleur réelle est posée.
    Widget plusIndicator() {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Text(
              '+',
              style: GoogleFonts.exo2(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.0,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ─── Case neutre + zone INACTIVE : fond rayé + "+" + badge Ø ───
    if (!isZoneActive && isNeutral) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: CustomPaint(
              painter: _DiagonalStripesPainter(
                background: const Color(0xFF4A4A4A),
                stripeColor: Colors.black.withValues(alpha: 0.65),
                stripeWidth: 1.5,
                gap: 3.0,
                cornerRadius: radius,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: isSelected
                        ? Colors.red
                        : Colors.black.withValues(alpha: 0.6),
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ─── Case neutre + zone ACTIVE : fond gris uni + "+" ───
    if (isNeutral) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6B6B6B),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isSelected
                    ? Colors.red
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
          ),
          Positioned.fill(child: plusIndicator()),
        ],
      );
    }

    // ─── Case avec couleur posée ───
    final fill = color!;
    final textColor = _isLight(fill) ? Colors.black87 : Colors.white;
    final shadowColor = _isLight(fill)
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.8);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isSelected
                  ? Colors.red
                  : !isZoneActive
                      ? Colors.orange.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.35),
              width: isSelected ? 1.5 : (!isZoneActive ? 1.2 : 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: fill.withValues(alpha: 0.55),
                blurRadius: 3,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: Text(
                '$colorId',
                style: GoogleFonts.exo2(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  decoration: TextDecoration.none,
                  shadows: [Shadow(color: shadowColor, blurRadius: 1.5)],
                ),
              ),
            ),
          ),
        ),
        
      ],
    );
  }

  Widget _buildRegionPreview(int regionIndex) {
    final previewColors = List<String?>.generate(6, (i) {
      if (i == regionIndex) {
        final c = _couleurs[i];
        final hasColor =
            c.id > 0 && c.hex != '#808080' && c.hex != '#7F7F7F';
        return hasColor ? c.hex : '#FF2222';
      }
      return '#808080';
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withValues(alpha: 0.15), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 90,
            child: DinoImageWidget(
              species: _espece,
              regionColors: previewColors,
              width: 120,
              height: 90,
              fit: BoxFit.contain,
              showColorBand: false,
              alignment: Alignment.center,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'RÉGION $regionIndex',
                    style: GoogleFonts.exo2(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: () {
                          final c = _couleurs[regionIndex];
                          final hasColor = c.id > 0 &&
                              c.hex != '#808080' &&
                              c.hex != '#7F7F7F';
                          return hasColor
                              ? _parseHex(c.hex)
                              : const Color(0xFF333333);
                        }(),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _couleurs[regionIndex].id > 0
                              ? 'ID ${_couleurs[regionIndex].id}'
                              : 'Sans couleur',
                          style: GoogleFonts.exo2(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _couleurs[regionIndex].hex.toUpperCase(),
                          style: GoogleFonts.exo2(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Appui long sur la case → réinitialiser',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _activeRegionIndex = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // BOUTONS D'ACTION
  // ═══════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.save_rounded,
                label: _isSaving
                    ? 'SAUVEGARDE...'
                    : widget.dino == null || widget.isDuplicate
                        ? 'CRÉER DINOCARD'
                        : 'SAUVEGARDER',
                color: AppTheme.accentPrimary,
                onPressed: _isSaving ? () {} : _save,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.science_rounded,
                label: 'Sauver les stats',
                color: Colors.cyanAccent,
                onPressed: _registerStatsToTracker,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.palette_rounded,
                label: 'Sauver les couleurs',
                color: Colors.cyanAccent,
                onPressed: _registerColorsToTracker,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.exo2(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════

  Future<void> _editField(String title, TextEditingController ctrl,
      {bool isNumber = false, bool multiline = false}) async {
    final tempCtrl = TextEditingController(text: ctrl.text);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.exo2(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: tempCtrl,
          autofocus: true,
          keyboardType: isNumber
              ? TextInputType.number
              : (multiline ? TextInputType.multiline : TextInputType.text),
          maxLines: multiline ? 5 : 1,
          inputFormatters:
              isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          textCapitalization: multiline
              ? TextCapitalization.sentences
              : TextCapitalization.words,
          onSubmitted: multiline ? null : (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              setState(() => ctrl.text = tempCtrl.text);
              Navigator.pop(ctx);
            },
            child: Text('OK',
                style: GoogleFonts.exo2(color: AppTheme.accentPrimary)),
          ),
        ],
      ),
    );
    tempCtrl.dispose();
  }

  Future<void> _editTags() async {
    final provider = context.read<DinoProvider>();

    await showDialog(
      context: context,
      builder: (ctx) {
        final tempTags = List<String>.from(_tags);

        return StatefulBuilder(
          builder: (context, setLocalState) {
            final availableTags = context.watch<DinoProvider>().allTags;

            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Tags & Role',
                  style: GoogleFonts.exo2(color: Colors.white)),
              content: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...availableTags.map((tag) {
                    final selected = tempTags.contains(tag);
                    return FilterChip(
                      label: Text(tag,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: 12,
                          )),
                      selected: selected,
                      onSelected: (val) {
                        setLocalState(() {
                          if (val) {
                            tempTags.add(tag);
                          } else {
                            tempTags.remove(tag);
                          }
                        });
                      },
                      backgroundColor: AppTheme.bgSecondary,
                      selectedColor:
                          AppTheme.accentPrimary.withValues(alpha: 0.8),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? AppTheme.accentPrimary
                            : AppTheme.borderColor,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    );
                  }),
                  GestureDetector(
                    onTap: () async {
                      final newTag =
                          await _showAddTagDialog(provider, setLocalState);
                      if (newTag != null) {
                        setLocalState(() {
                          if (!tempTags.contains(newTag)) {
                            tempTags.add(newTag);
                          }
                        });
                      }
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.bgSecondary,
                        border: Border.all(
                            color:
                                AppTheme.accentGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.add,
                          size: 18, color: AppTheme.accentGreen),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Annuler',
                      style: GoogleFonts.exo2(color: AppTheme.textMuted)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tags = tempTags;
                      const roles = [
                        'Boss',
                        'Breed',
                        'Solid',
                        'Farm',
                        'Collection'
                      ];
                      final foundRole = tempTags.firstWhere(
                        (t) => roles.contains(t),
                        orElse: () => _role,
                      );
                      _role = foundRole;
                    });
                    // Si le tag solid/solidvisual vient d'être ajouté ou retiré,
                    // on répercute immédiatement sur les couleurs.
                    _onTagsChanged();
                    Navigator.pop(ctx);
                  },
                  child: Text('Valider',
                      style:
                          GoogleFonts.exo2(color: AppTheme.accentPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showAddTagDialog(
    DinoProvider provider,
    StateSetter setLocalState,
  ) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Nouveau tag',
            style: GoogleFonts.exo2(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ex: Alpha, Mutant...',
            filled: true,
            fillColor: AppTheme.bgPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text('Ajouter',
                style: GoogleFonts.exo2(color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );

    ctrl.dispose();

    if (result != null && result.trim().isNotEmpty) {
      await provider.addCustomTag(result.trim());
      setLocalState(() {});
      return result.trim();
    }
    return null;
  }

  Future<void> _showArkColorPicker(int index) async {
    setState(() => _activeRegionIndex = index);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).padding.bottom,
            ),
            child: ArkColorPicker(
              selectedId: _couleurs[index].id,
              selectedHex: _couleurs[index].hex,
              regionName: _regionNames[index],
              regionIndex: index,
              species: _espece,
              currentColors: _couleurs.map((c) => c.hex).toList(),
              onColorSelected: (result) {
                if (!mounted) return;
                // Passage par _applyColor pour respecter solid / solidvisual.
                _applyColor(index, result);
              },
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _activeRegionIndex = null);
    }
  }

  Future<void> _showSpeciesPickerDialog() async {
    final allSpecies = Dino.especesDisponibles;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        List<String> filtered = List<String>.from(allSpecies);
        return StatefulBuilder(
          builder: (context, setLocalState) {
            void applyFilter(String query) {
              final q = query.toLowerCase().trim();
              setLocalState(() {
                filtered = allSpecies
                    .where((s) => s.toLowerCase().contains(q))
                    .toList();
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Choisir une espèce',
                  style: TextStyle(color: AppTheme.textPrimary)),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      onChanged: applyFilter,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4)),
                        prefixIcon: const Icon(Icons.search,
                            color: AppTheme.accentPrimary),
                        filled: true,
                        fillColor: AppTheme.bgPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('Aucune espèce',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.5))))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final species = filtered[index];
                                final hasImg =
                                    ArkSpeciesData.hasImage(species);
                                return ListTile(
                                  dense: true,
                                  leading: hasImg
                                      ? Image.asset(
                                          'assets/images/dinos/${species.replaceAll(' ', '_')}_ASA.png',
                                          width: 40,
                                          height: 32,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.help_outline,
                                                  color: Colors.white38,
                                                  size: 20),
                                        )
                                      : const Icon(Icons.help_outline,
                                          color: Colors.white38, size: 20),
                                  title: Text(species,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                  onTap: () =>
                                      Navigator.pop(ctx, species),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Annuler',
                      style: GoogleFonts.exo2(
                          color: AppTheme.accentPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _espece = result);
    }
  }

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════

  void _cycleSexe() {
    setState(() {
      const cycle = ['Inconnu', 'Mâle', 'Femelle', 'Mâle+Femelle'];
      final i = cycle.indexOf(_sexe);
      _sexe = cycle[(i + 1) % cycle.length];
    });
  }

  String _sexeDisplay() {
    switch (_sexe) {
      case 'Mâle':
        return '♂';
      case 'Femelle':
        return '♀';
      case 'Mâle+Femelle':
        return '♂♀';
      default:
        return '?';
    }
  }

  Color _sexeColorValue() {
    switch (_sexe) {
      case 'Mâle':
        return Colors.blueAccent;
      case 'Femelle':
        return Colors.pinkAccent;
      case 'Mâle+Femelle':
        return Colors.purpleAccent;
      default:
        return Colors.white.withValues(alpha: 0.7);
    }
  }

  Color _parseHex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return Colors.grey;
  }

  bool _isLight(Color c) => c.computeLuminance() > 0.5;
}

// ─────────────────────────────────────────────────────────────────────────────
// Données d'une case stat éditable
// ─────────────────────────────────────────────────────────────────────────────
class _EditableStatCellData {
  final double cx, cy;
  final String emoji;
  final String label;
  final Color color;
  final TextEditingController valCtrl;
  final TextEditingController baseCtrl;
  final TextEditingController mutaCtrl;
  final TextEditingController persoCtrl;
  final String? suffix;

  _EditableStatCellData({
    required this.cx,
    required this.cy,
    required this.emoji,
    required this.label,
    required this.color,
    required this.valCtrl,
    required this.baseCtrl,
    required this.mutaCtrl,
    required this.persoCtrl,
    this.suffix,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters partagés
// ─────────────────────────────────────────────────────────────────────────────
class _DiagonalStripesPainter extends CustomPainter {
  final Color background;
  final Color stripeColor;
  final double stripeWidth;
  final double gap;
  final double cornerRadius;

  _DiagonalStripesPainter({
    required this.background,
    required this.stripeColor,
    required this.stripeWidth,
    required this.gap,
    this.cornerRadius = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = background;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, bgPaint);

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    final step = stripeWidth + gap;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        stripePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter old) =>
      old.background != background ||
      old.stripeColor != stripeColor ||
      old.stripeWidth != stripeWidth ||
      old.gap != gap ||
      old.cornerRadius != cornerRadius;
}

class _OvalGlowPainter extends CustomPainter {
  final Color glowColor;
  final Color edgeColor;

  _OvalGlowPainter({
    required this.glowColor,
    required this.edgeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.7,
        colors: [
          glowColor,
          glowColor.withValues(alpha: glowColor.a * 0.4),
          edgeColor,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.95,
      height: size.height * 0.98,
    );
    canvas.drawOval(ovalRect, paint);
  }

  @override
  bool shouldRepaint(covariant _OvalGlowPainter old) =>
      old.glowColor != glowColor || old.edgeColor != edgeColor;
}
