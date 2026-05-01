// lib/screens/add_edit_dino_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ark_species_data.dart';
import '../models/dino.dart';
import '../models/species_tracker.dart';
import '../providers/dino_provider.dart';
import '../providers/tracker_provider.dart';
import '../services/dino_scan_helper.dart';   // ✅ RÉACTIVÉ
import '../services/dino_ocr_service.dart';   // ✅ RÉACTIVÉ
import '../theme/app_theme.dart';
import '../widgets/ark_color_picker.dart';
import '../widgets/dino_image_widget.dart';
import '../utils/dino_helpers.dart';
import 'dart:io';
import 'dart:ui' as ui;

class AddEditDinoScreen extends StatefulWidget {
  final Dino? dino;
  final bool isDuplicate;

  const AddEditDinoScreen({
    super.key,
    this.dino,
    this.isDuplicate = false,
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
  bool _isScanning = false; // ✅ AJOUTÉ pour gérer l'état du bouton scanner

  int? _activeRegionIndex;

  static const List<String> _regionNames = [
    '0', '1', '2', '3', '4', '5',
  ];

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

    _espece = d?.espece ?? 'Rex';
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
      couleur0: Dino.encodeColor(_couleurs[0].id, _couleurs[0].hex),
      couleur1: Dino.encodeColor(_couleurs[1].id, _couleurs[1].hex),
      couleur2: Dino.encodeColor(_couleurs[2].id, _couleurs[2].hex),
      couleur3: Dino.encodeColor(_couleurs[3].id, _couleurs[3].hex),
      couleur4: Dino.encodeColor(_couleurs[4].id, _couleurs[4].hex),
      couleur5: Dino.encodeColor(_couleurs[5].id, _couleurs[5].hex),
      tagVersion: _tagVersion,
      tags: List<String>.from(_tags),
      notes: finalNotes,
      dateAjout: (widget.dino == null || widget.isDuplicate)
          ? DateTime.now()
          : widget.dino!.dateAjout,
    );
  }

  // ─────────────── SCANNER OCR — ✅ RÉACTIVÉ ───────────────

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
        // ── Espèce & niveau ──
        if (result.species != null) _espece = result.species!;
        if (result.level != null) _niveauCtrl.text = result.level.toString();

        // ── Sexe ──
        if (result.sex != null) {
          if (result.sex!.contains('♀')) {
            _sexe = 'Femelle';
          } else if (result.sex!.contains('♂')) {
            _sexe = 'Mâle';
          }
        }

        // ── Correction imprint ──
        final imprint = result.imprintPercent ?? 0;
        final imprintMultiplier = 1.0 + (0.2 * imprint / 100.0);

        // ── Stats principales (correction imprint si nécessaire) ──
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

        // ── Points sauvages (base) ──
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
        // ✅ BUG 3 CORRIGÉ : vitesse
if (result.speed?.maxValue != null) {
  // La vitesse n'a pas de champ dédié dans le formulaire
  // mais on l'ajoute dans les notes pour info
  final speedVal = result.speed!.maxValue!;
  final existing = _notesCtrl.text;
  if (!existing.contains('Vitesse')) {
    _notesCtrl.text = existing.isNotEmpty
        ? '$existing\nVitesse: ${speedVal.toStringAsFixed(1)}%'
        : 'Vitesse: ${speedVal.toStringAsFixed(1)}%';
  }
}


        // ── Couleurs (6 régions) ──
        for (int i = 0; i < 6; i++) {
          final colorId = result.colorIds[i];
          if (colorId > 0) {
            final hex = DinoScanHelper.getColorHex(colorId);
            _couleurs[i] = (id: colorId, hex: hex);
          }
        }

        // ── Tags automatiques ──
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

        // ── Notes automatiques ──
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

      // ── SnackBar succès (vert flottant) ──
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

      // ── SnackBar erreur (rouge flottant) ──
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

  /// Dialogue de confirmation avant d'appliquer les données OCR
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
              if (result.species != null)
                _scanRow('Espèce', result.species!),
              if (result.level != null)
                _scanRow('Niveau', '${result.level}'),
              if (result.sex != null)
                _scanRow('Sexe', result.sex!),
              if (result.status != null)
                _scanRow('Statut', result.status!),
              if (imprint > 0)
                _scanRow('Imprint', '${imprint.toStringAsFixed(1)}%',
                    warn: true),
              const Divider(color: Colors.white24, height: 16),
              if (result.hp?.maxValue != null)
                _scanRow('HP', '${result.hp!.maxValue!.round()}'
                    '${result.hp!.wildPoints != null ? '  [${result.hp!.wildPoints}pts]' : ''}'),
              if (result.stamina?.maxValue != null)
                _scanRow('Stamina', '${result.stamina!.maxValue!.round()}'
                    '${result.stamina!.wildPoints != null ? '  [${result.stamina!.wildPoints}pts]' : ''}'),
              if (result.oxygen?.maxValue != null)
                _scanRow('Oxygène', '${result.oxygen!.maxValue!.round()}'),
              if (result.food?.maxValue != null)
                _scanRow('Nourriture', '${result.food!.maxValue!.round()}'),
              if (result.weight?.maxValue != null)
                _scanRow('Poids', '${result.weight!.maxValue!.round()}'),
              if (result.melee?.maxValue != null)
                _scanRow('Attaque', '${result.melee!.maxValue!.toStringAsFixed(1)}%'),
              if (result.colorIds.any((id) => id > 0)) ...[
                const Divider(color: Colors.white24, height: 16),
                _scanRow('Couleurs',
                    result.colorIds.map((id) => id > 0 ? '#$id' : '-').join('  ')),
              ],
              if (result.mutationsMale != null || result.mutationsFemale != null) ...[
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
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le nom est obligatoire'),
            backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<DinoProvider>();
    final dino = _buildDinoFromForm();

    final bool success = dino.id == null
        ? await provider.addDino(dino)
        : await provider.updateDino(dino);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      final message = widget.isDuplicate
          ? '${dino.nom} dupliqué !'
          : widget.dino == null
              ? '${dino.nom} ajouté !'
              : '${dino.nom} mis à jour !';
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
          backgroundColor: AppTheme.warning));
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
          backgroundColor: AppTheme.warning));
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

  // ─────────────── BUILD ───────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hexColors = _couleurs.map((c) => c.hex).toList();
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
          // ✅ Bouton scanner — réactivé
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
                _buildArkCard(hexColors, niveau),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ARK CARD
  // ═══════════════════════════════════════════════

  Widget _buildArkCard(List<String> hexColors, int niveau) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _roleColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildVisualSection(hexColors, niveau),
          _buildTitleSection(),
          _buildEditableStatGrid(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildEditableColorStrip(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Zone visuelle principale de la carte ──
  Widget _buildVisualSection(List<String> hexColors, int niveau) {
    final assetPath =
        'assets/images/dinos/${_espece.replaceAll(' ', '_')}_ASA.png';
    final existingImage = widget.dino?.image;
    final hasCustomImage = existingImage != null && existingImage.isNotEmpty;

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // ── FOND FLOUTÉ ──
          Positioned.fill(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasCustomImage
                      ? Image.file(
                          File(existingImage),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackBg(),
                        )
                      : Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackBg(),
                        ),
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: const SizedBox.expand(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.50),
                          _roleColor.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BORDURE BASSE ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(height: 2, color: const Color(0xFF5A5A5A)),
          ),

          // ── IMAGE DINO cliquable → picker espèce ──
          Positioned.fill(
            child: GestureDetector(
              onTap: _showSpeciesPickerDialog,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    hasCustomImage
                        ? Image.file(
                            File(existingImage),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => DinoImageWidget(
                              species: _espece,
                              regionColors: hexColors,
                              width: double.infinity,
                              height: 240,
                              fit: BoxFit.contain,
                              showColorBand: false,
                              alignment: Alignment.center,
                            ),
                          )
                        : DinoImageWidget(
                            species: _espece,
                            regionColors: hexColors,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.contain,
                            showColorBand: false,
                            alignment: Alignment.center,
                          ),
                    // ── Hint "changer d'espèce" ──
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 11),
                            const SizedBox(width: 4),
                            Text(
                              'Changer d\'espèce',
                              style: GoogleFonts.exo2(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BADGE NIVEAU cliquable ──
          Positioned(
            top: 16, left: 16,
            child: GestureDetector(
              onTap: () => _inlineEdit(_niveauCtrl),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: DinoHelpers.getCardRarityColor(niveau), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: DinoHelpers.getCardRarityColor(niveau)
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'LVL $niveau',
                  style: GoogleFonts.exo2(
                    color: DinoHelpers.getCardRarityColor(niveau),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          // ── BADGE SEXE cliquable ──
          Positioned(
            top: 16, right: 16,
            child: GestureDetector(
              onTap: _cycleSexe,
              child: _buildSexBadge(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            _roleColor.withValues(alpha: 0.35),
            const Color(0xFF0F1115),
          ],
        ),
      ),
    );
  }

  Widget _buildSexBadge() {
    final isBoth = _sexe == 'Mâle+Femelle';

    if (isBoth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.purple, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('♂',
                style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Text('♀',
                style: TextStyle(
                    color: Colors.pink[300],
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    final sexeColor = _sexeColorValue();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: sexeColor, width: 2),
        boxShadow: [
          BoxShadow(color: sexeColor.withValues(alpha: 0.5), blurRadius: 8)
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _sexeDisplay(),
        style:
            TextStyle(color: sexeColor, fontSize: 22, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
        ),
        border: const Border(
            bottom: BorderSide(color: Color(0xFF5A5A5A), width: 1)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showSpeciesPickerDialog,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ).createShader(bounds),
              child: Text(
                DinoHelpers.toTitleCase(_espece),
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: const [
                    Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(2, 2))
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _editField('Nom du dinosaure', _nomCtrl),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _roleColor.withValues(alpha: 0.6), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _nomCtrl.text.isEmpty
                          ? 'Appuyer pour nommer'
                          : _nomCtrl.text,
                      style: GoogleFonts.exo2(
                        color: _nomCtrl.text.isEmpty
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _editTags,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _roleColor, width: 1),
                      ),
                      child: Text(
                        _role.toUpperCase(),
                        style: TextStyle(
                          color: _roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // GRILLE DE STATS EDITABLE
  // ═══════════════════════════════════════════════

  Widget _buildEditableStatGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _editableStatTile(
                  emoji: '❤️',
                  label: 'VIE',
                  valCtrl: _hpCtrl,
                  baseCtrl: _hpBaseCtrl,
                  mutaCtrl: _hpMutaCtrl,
                  persoCtrl: _hpPersoCtrl,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _editableStatTile(
                  emoji: '⚡',
                  label: 'STAM',
                  valCtrl: _staminaCtrl,
                  baseCtrl: _staminaBaseCtrl,
                  mutaCtrl: _staminaMutaCtrl,
                  persoCtrl: _staminaPersoCtrl,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _editableStatTile(
                  emoji: '⚔️',
                  label: 'ATTAQUE',
                  valCtrl: _degatsCtrl,
                  baseCtrl: _degatsBaseCtrl,
                  mutaCtrl: _degatsMutaCtrl,
                  persoCtrl: _degatsPersoCtrl,
                  color: const Color(0xFFEF4444),
                  suffix: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _editableStatTile(
                  emoji: '⚖️',
                  label: 'POIDS',
                  valCtrl: _poidsCtrl,
                  baseCtrl: _poidsBaseCtrl,
                  mutaCtrl: _poidsMutaCtrl,
                  persoCtrl: _poidsPersoCtrl,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _editableStatTile(
                  emoji: '🍖',
                  label: 'FOOD',
                  valCtrl: _nourritureCtrl,
                  baseCtrl: _nourritureBaseCtrl,
                  mutaCtrl: _nourritureMutaCtrl,
                  persoCtrl: _nourriturePersoCtrl,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _editableStatTile(
                  emoji: '🫧',
                  label: 'OXYGENE',
                  valCtrl: _oxygeneCtrl,
                  baseCtrl: _oxygeneBaseCtrl,
                  mutaCtrl: _oxygeneMutaCtrl,
                  persoCtrl: _oxygenePersoCtrl,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editableStatTile({
    required String emoji,
    required String label,
    required TextEditingController valCtrl,
    required TextEditingController baseCtrl,
    required TextEditingController mutaCtrl,
    required TextEditingController persoCtrl,
    required Color color,
    String? suffix,
  }) {
    final valText = valCtrl.text.trim();
    final double valNum = _parseDouble(valText);
    final bool hasValue = valNum > 0;
    final String displayVal;
    if (!hasValue) {
      displayVal = '';
    } else if (suffix != null) {
      displayVal = valNum == valNum.roundToDouble()
          ? '${valNum.round()}$suffix'
          : '${valNum.toStringAsFixed(1)}$suffix';
    } else {
      displayVal = valNum == valNum.roundToDouble()
          ? '${valNum.round()}'
          : valNum.toStringAsFixed(1);
    }

    final base = int.tryParse(baseCtrl.text.trim()) ?? 0;
    final muta = int.tryParse(mutaCtrl.text.trim()) ?? 0;
    final perso = int.tryParse(persoCtrl.text.trim()) ?? 0;
    final total = base + muta + perso;
    final hasPoints = total > 0;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF454545), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _inlineEdit(valCtrl, isStat: true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: hasValue
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasValue
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: hasValue
                  ? Text(
                      displayVal,
                      style: GoogleFonts.exo2(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      '—',
                      style: GoogleFonts.exo2(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            decoration: BoxDecoration(
              color: hasPoints
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: hasPoints
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: hasPoints
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${total}pts',
                          style: GoogleFonts.exo2(
                            color: const Color(0xFFFF6B00),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text('|',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  fontSize: 9)),
                        ),
                        _miniPtsBubble(
                            baseCtrl, base, 'B', const Color(0xFF00E5FF)),
                        Text(' - ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 8)),
                        _miniPtsBubble(
                            mutaCtrl, muta, 'M', const Color(0xFFFF6B00)),
                        Text(' - ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 8)),
                        _miniPtsBubble(
                            persoCtrl, perso, 'P', const Color(0xFF4CAF50)),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _miniPtsBubble(
                          baseCtrl, base, 'B', const Color(0xFF00E5FF)),
                      _miniPtsBubble(
                          mutaCtrl, muta, 'M', const Color(0xFFFF6B00)),
                      _miniPtsBubble(
                          persoCtrl, perso, 'P', const Color(0xFF4CAF50)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniPtsBubble(
      TextEditingController ctrl, int value, String hint, Color color) {
    final hasVal = value > 0;
    return GestureDetector(
      onTap: () => _inlineEdit(ctrl, hint: hint),
      child: Container(
        constraints: const BoxConstraints(minWidth: 18),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: hasVal
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: hasVal
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          hasVal ? '$value' : hint,
          style: GoogleFonts.exo2(
            color: hasVal ? color : Colors.white.withValues(alpha: 0.2),
            fontSize: 8,
            fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
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

  // ═══════════════════════════════════════════════
  // BANDE DE COULEURS ÉDITABLE + PREVIEW RÉGION
  // ═══════════════════════════════════════════════

  Widget _buildEditableColorStrip() {
    return Column(
      children: [
        if (_activeRegionIndex != null)
          _buildRegionPreview(_activeRegionIndex!),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: List.generate(6, (i) {
              final c = _couleurs[i];
              final isActive =
                  c.id > 0 && c.hex != '#808080' && c.hex != '#7F7F7F';
              final color =
                  isActive ? _parseHex(c.hex) : const Color(0xFF222222);
              final isSelected = _activeRegionIndex == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _showArkColorPicker(i),
                  onLongPress: () {
                    setState(() {
                      _couleurs[i] = (id: 0, hex: '#808080');
                      if (_activeRegionIndex == i) {
                        _activeRegionIndex = null;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.red
                            : isActive
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                  color: Colors.red,
                                  blurRadius: 8,
                                  spreadRadius: 1)
                            ]
                          : isActive
                              ? [
                                  BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 6)
                                ]
                              : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isActive ? '${c.id}' : '-',
                          style: TextStyle(
                            color: isActive
                                ? (_isLight(color)
                                    ? Colors.black87
                                    : Colors.white)
                                : Colors.white.withValues(alpha: 0.3),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            shadows: isActive
                                ? [
                                    Shadow(
                                      color: _isLight(color)
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        Text(
                          'R$i',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.red
                                : Colors.white.withValues(alpha: 0.3),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
      margin: const EdgeInsets.only(bottom: 8),
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
                Row(
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
                  ],
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        // ✅ Bouton scanner — réactivé, avec indicateur de chargement
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: _isScanning
                    ? Icons.hourglass_top_rounded
                    : Icons.document_scanner_rounded,
                label: _isScanning
                    ? 'SCAN EN COURS...'
                    : 'SCANNER CRYOPOD / TEK',
                color: Colors.greenAccent,
                onPressed: _isScanning ? () {} : _launchScanner,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
            child:
                Text('OK', style: GoogleFonts.exo2(color: AppTheme.accentPrimary)),
          ),
        ],
      ),
    );
    tempCtrl.dispose();
  }

  Future<void> _editTags() async {
    final provider = context.read<DinoProvider>();
    final availableTags = provider.allTags;

    await showDialog(
      context: context,
      builder: (ctx) {
        final tempTags = List<String>.from(_tags);
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title:
                  Text('Tags & Role', style: GoogleFonts.exo2(color: Colors.white)),
              content: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...availableTags.map((tag) {
                    final selected = tempTags.contains(tag);
                    return FilterChip(
                      label: Text(tag,
                          style: TextStyle(
                            color:
                                selected ? Colors.white : AppTheme.textSecondary,
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
                      final newTag = await _showAddTagDialog(provider);
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
                            color: AppTheme.accentGreen.withValues(alpha: 0.4)),
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
                      final roles = [
                        'Boss', 'Breed', 'Solid', 'Farm', 'Collection'
                      ];
                      final foundRole = tempTags.firstWhere(
                        (t) => roles.contains(t),
                        orElse: () => _role,
                      );
                      _role = foundRole;
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text('Valider',
                      style: GoogleFonts.exo2(color: AppTheme.accentPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showAddTagDialog(DinoProvider provider) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title:
            Text('Nouveau tag', style: GoogleFonts.exo2(color: Colors.white)),
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
            child:
                Text('Annuler', style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text('Ajouter',
                style: GoogleFonts.exo2(color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await provider.addCustomTag(result.trim());
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
                setState(() => _couleurs[index] = result);
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
                                      color:
                                          Colors.white.withValues(alpha: 0.5))))
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
                                  onTap: () => Navigator.pop(ctx, species),
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
                      style:
                          GoogleFonts.exo2(color: AppTheme.accentPrimary)),
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
        return AppTheme.textMuted;
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
