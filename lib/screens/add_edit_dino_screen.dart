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
import '../services/dino_scan_helper.dart';
import '../services/dino_ocr_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ark_color_picker.dart';
import '../widgets/dino_image_widget.dart';
import '../utils/dino_helpers.dart';

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
  late TextEditingController _vitesseCtrl;

  late TextEditingController _hpPtsCtrl;
  late TextEditingController _staminaPtsCtrl;
  late TextEditingController _oxygenePtsCtrl;
  late TextEditingController _nourriturePtsCtrl;
  late TextEditingController _poidsPtsCtrl;
  late TextEditingController _degatsPtsCtrl;
  late TextEditingController _vitessePtsCtrl;

  late String _espece;
  late String _sexe;
  late String _role;
  late String _tagVersion;
  late List<String> _tags;

  late List<({int id, String hex})> _couleurs;

  bool _isSaving = false;

  static const List<String> _regionNames = [
    'Corps',
    'Tête',
    'Dos',
    'Ventre',
    'Pattes',
    'Queue',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.dino;

    _nomCtrl = TextEditingController(
      text: widget.isDuplicate && d != null
          ? '${d.nom} (copie)'
          : (d?.nom ?? ''),
    );
    _niveauCtrl = TextEditingController(
      text: d != null ? d.niveau.toString() : '0',
    );
    _notesCtrl = TextEditingController(text: d?.notes ?? '');

    _hpCtrl = TextEditingController(text: d != null ? d.hp.toString() : '');
    _staminaCtrl =
        TextEditingController(text: d != null ? d.stamina.toString() : '');
    _oxygeneCtrl =
        TextEditingController(text: d != null ? d.oxygene.toString() : '');
    _nourritureCtrl =
        TextEditingController(text: d != null ? d.nourriture.toString() : '');
    _poidsCtrl =
        TextEditingController(text: d != null ? d.poids.toString() : '');
    _degatsCtrl =
        TextEditingController(text: d != null ? d.degats.toString() : '');
    _vitesseCtrl =
        TextEditingController(text: d != null ? d.vitesse.toString() : '');

    _hpPtsCtrl =
        TextEditingController(text: d != null ? d.hpPoints.toString() : '0');
    _staminaPtsCtrl = TextEditingController(
        text: d != null ? d.staminaPoints.toString() : '0');
    _oxygenePtsCtrl = TextEditingController(
        text: d != null ? d.oxygenePoints.toString() : '0');
    _nourriturePtsCtrl = TextEditingController(
        text: d != null ? d.nourriturePoints.toString() : '0');
    _poidsPtsCtrl = TextEditingController(
        text: d != null ? d.poidsPoints.toString() : '0');
    _degatsPtsCtrl = TextEditingController(
        text: d != null ? d.degatsPoints.toString() : '0');
    _vitessePtsCtrl = TextEditingController(
        text: d != null ? d.vitessePoints.toString() : '0');

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
    _vitesseCtrl.dispose();
    _hpPtsCtrl.dispose();
    _staminaPtsCtrl.dispose();
    _oxygenePtsCtrl.dispose();
    _nourriturePtsCtrl.dispose();
    _poidsPtsCtrl.dispose();
    _degatsPtsCtrl.dispose();
    _vitessePtsCtrl.dispose();
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

    return Dino(
      id: isNewDino ? null : widget.dino!.id,
      nom: _nomCtrl.text.trim(),
      espece: _espece,
      sexe: _sexe,
      role: roleFromTag,
      niveau: int.tryParse(_niveauCtrl.text.trim()) ?? 0,
      hp: int.tryParse(_hpCtrl.text.trim()) ?? 0,
      stamina: int.tryParse(_staminaCtrl.text.trim()) ?? 0,
      oxygene: int.tryParse(_oxygeneCtrl.text.trim()) ?? 0,
      nourriture: int.tryParse(_nourritureCtrl.text.trim()) ?? 0,
      poids: int.tryParse(_poidsCtrl.text.trim()) ?? 0,
      degats:
          double.tryParse(_degatsCtrl.text.trim().replaceAll(',', '.')) ?? 0.0,
      vitesse:
          double.tryParse(_vitesseCtrl.text.trim().replaceAll(',', '.')) ??
              100.0,
      hpPoints: _parsePtsTotal(_hpPtsCtrl.text),
      staminaPoints: _parsePtsTotal(_staminaPtsCtrl.text),
      oxygenePoints: _parsePtsTotal(_oxygenePtsCtrl.text),
      nourriturePoints: _parsePtsTotal(_nourriturePtsCtrl.text),
      poidsPoints: _parsePtsTotal(_poidsPtsCtrl.text),
      degatsPoints: _parsePtsTotal(_degatsPtsCtrl.text),
      vitessePoints: _parsePtsTotal(_vitessePtsCtrl.text),
      couleur0: Dino.encodeColor(_couleurs[0].id, _couleurs[0].hex),
      couleur1: Dino.encodeColor(_couleurs[1].id, _couleurs[1].hex),
      couleur2: Dino.encodeColor(_couleurs[2].id, _couleurs[2].hex),
      couleur3: Dino.encodeColor(_couleurs[3].id, _couleurs[3].hex),
      couleur4: Dino.encodeColor(_couleurs[4].id, _couleurs[4].hex),
      couleur5: Dino.encodeColor(_couleurs[5].id, _couleurs[5].hex),
      tagVersion: _tagVersion,
      tags: List<String>.from(_tags),
      notes: _notesCtrl.text.trim(),
      dateAjout: (widget.dino == null || widget.isDuplicate)
          ? DateTime.now()
          : widget.dino!.dateAjout,
    );
  }

  int _parsePtsTotal(String text) {
    final trimmed = text.trim();
    if (trimmed.contains('+')) {
      final parts = trimmed.split('+');
      int total = 0;
      for (final p in parts) {
        total += int.tryParse(p.trim()) ?? 0;
      }
      return total;
    }
    return int.tryParse(trimmed) ?? 0;
  }

  // ─────────────── SCANNER OCR ───────────────

  /// Lance le scan OCR et pré-remplit tous les champs avec le résultat
   Future<void> _launchScanner() async {
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

      // Stats corrigées à 0% imprint pour HP, Stamina, Weight, Melee
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
        // Oxygen PAS affecté par l'imprint
        _oxygeneCtrl.text = result.oxygen!.maxValue!.round().toString();
      }
      if (result.food?.maxValue != null) {
        // Food PAS affecté par l'imprint
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
      if (result.speed?.maxValue != null) {
        // Speed: l'imprint ajoute un bonus fixe, pas multiplicatif
        // En pratique on ne corrige pas la speed, elle est souvent 100%
        _vitesseCtrl.text = result.speed!.maxValue!.toStringAsFixed(1);
      }

      // Points (inchangés par l'imprint, ce sont les points bruts)
      if (result.hp != null) _hpPtsCtrl.text = result.pointsDisplayFor(result.hp);
      if (result.stamina != null) _staminaPtsCtrl.text = result.pointsDisplayFor(result.stamina);
      if (result.oxygen != null) _oxygenePtsCtrl.text = result.pointsDisplayFor(result.oxygen);
      if (result.food != null) _nourriturePtsCtrl.text = result.pointsDisplayFor(result.food);
      if (result.weight != null) _poidsPtsCtrl.text = result.pointsDisplayFor(result.weight);
      if (result.melee != null) _degatsPtsCtrl.text = result.pointsDisplayFor(result.melee);
      if (result.speed != null) _vitessePtsCtrl.text = result.pointsDisplayFor(result.speed);

      // Couleurs
      for (int i = 0; i < 6; i++) {
        final colorId = result.colorIds[i];
        if (colorId > 0) {
          final hex = DinoScanHelper.getColorHex(colorId);
          _couleurs[i] = (id: colorId, hex: hex);
        }
      }

      // Tags
      if (result.status != null) {
        if (result.status!.toLowerCase().contains('badass') && !_tags.contains('Badass')) {
          _tags.add('Badass');
        }
      }
      if ((result.mutationsMale ?? 0) > 0 || (result.mutationsFemale ?? 0) > 0) {
        if (!_tags.contains('Mutant')) _tags.add('Mutant');
      }

      // Notes
      final notesParts = <String>[];
      notesParts.add('Import OCR (${result.sourceType.label})');
      if (imprint > 0) {
        notesParts.add('Imprint: ${imprint.toStringAsFixed(1)}%${result.imprinter != null ? ' - ${result.imprinter}' : ''}');
        notesParts.add('⚠️ Stats HP/Stam/Weight/Melee corrigées à 0% imprint');
      }
      if (result.mutationsMale != null || result.mutationsFemale != null) {
        notesParts.add('Mutations: ♂${result.mutationsMale ?? '?'} ♀${result.mutationsFemale ?? '?'}');
      }
      _notesCtrl.text = notesParts.join('\n');
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Données importées (${result.sourceType.label})${(result.imprintPercent ?? 0) > 0 ? ' — stats corrigées imprint' : ''} — vérifiez et sauvegardez'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche le résumé du scan et retourne true si l'utilisateur confirme
  Future<bool?> _showScanResultDialog(DinoOcrResult result) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.sourceType == OcrSourceType.tekBinoculars
                  ? Icons.visibility
                  : Icons.ac_unit_rounded,
              color: const Color(0xFF00E5FF),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résultat du scan',
                      style: GoogleFonts.exo2(
                          color: Colors.white, fontSize: 16)),
                  Text('Source: ${result.sourceType.label}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _scanLine('Espèce', result.species ?? '?'),
                _scanLine('Niveau', '${result.level ?? '?'}'),
                _scanLine('Sexe', result.sex ?? '?'),
                if (result.status != null)
                  _scanLine('Statut', result.status!),
                const Divider(color: Colors.white24, height: 20),
                _scanStatLine('HP', result.hp),
                _scanStatLine('Stamina', result.stamina),
                _scanStatLine('Oxygen', result.oxygen),
                _scanStatLine('Food', result.food),
                _scanStatLine('Weight', result.weight),
                _scanStatLine('Melee', result.melee),
                _scanStatLine('Speed', result.speed),
                const Divider(color: Colors.white24, height: 20),
                _scanLine(
                  'Couleurs',
                  result.colorIds
                      .map((c) => c > 0 ? '$c' : '-')
                      .join(' | '),
                ),
                const SizedBox(height: 6),
                // Aperçu visuel couleurs
                Row(
                  children: List.generate(6, (i) {
                    final id = result.colorIds[i];
                    final hex =
                        id > 0 ? DinoScanHelper.getColorHex(id) : '#333333';
                    return Expanded(
                      child: Container(
                        height: 24,
                        margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                        decoration: BoxDecoration(
                          color: _parseHex(hex),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: id > 0
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          id > 0 ? '$id' : '-',
                          style: TextStyle(
                            color:
                                id > 0 ? Colors.white : Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            shadows: id > 0
                                ? [
                                    const Shadow(
                                        color: Colors.black, blurRadius: 3)
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (result.mutationsMale != null ||
                    result.mutationsFemale != null) ...[
                  const SizedBox(height: 8),
                  _scanLine('Mutations',
                      '♂ ${result.mutationsMale ?? '?'}  ♀ ${result.mutationsFemale ?? '?'}'),
                ],
                if (result.imprinter != null) ...[
                  const SizedBox(height: 4),
                  _scanLine('Imprint',
                      '${result.imprintPercent ?? '?'}% - ${result.imprinter}'),
                ],
                const SizedBox(height: 12),
                // Texte brut
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Texte brut OCR',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11)),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        result.rawText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text('APPLIQUER',
                style: GoogleFonts.exo2(
                    fontWeight: FontWeight.w800, fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _scanStatLine(String label, OcrStat? stat) {
    if (stat == null) return _scanLine(label, '—');

    final value = stat.isPercent
        ? '${stat.maxValue?.toStringAsFixed(1) ?? '?'}%'
        : '${stat.maxValue?.round() ?? '?'}';

    final hasPoints = stat.wildPoints != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (hasPoints) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              ),
              child: Text(
                stat.pointsDisplay,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
      'vitesse': _vitesseCtrl,
    };
    m.forEach((k, c) {
      final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
      if (v != null && v > 0) stats[k] = v;
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
          // Bouton scanner dans l'AppBar aussi
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.document_scanner_rounded,
                  color: Color(0xFF00E5FF)),
              tooltip: 'Scanner cryopod / jumelles Tek',
              onPressed: _launchScanner,
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

  Widget _buildVisualSection(List<String> hexColors, int niveau) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            _roleColor.withValues(alpha: 0.2),
            const Color(0xFF0F1115),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF5A5A5A), width: 2),
        ),
      ),
      child: Stack(
        children: [
          // Image dino — CLIQUABLE pour changer d'espèce
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _showSpeciesPickerDialog,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: DinoImageWidget(
                  species: _espece,
                  regionColors: hexColors,
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.contain,
                  showColorBand: false,
                ),
              ),
            ),
          ),

          // Niveau (cliquable)
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () =>
                  _editField('Niveau', _niveauCtrl, isNumber: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: DinoHelpers.getCardRarityColor(niveau),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: DinoHelpers.getCardRarityColor(niveau)
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LVL ${_niveauCtrl.text}',
                      style: GoogleFonts.exo2(
                        color: DinoHelpers.getCardRarityColor(niveau),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit,
                        size: 12,
                        color: DinoHelpers.getCardRarityColor(niveau)
                            .withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
          ),

          // Sexe (cliquable)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _cycleSexe,
              child: _buildSexBadge(),
            ),
          ),

          // Changer d'espèce (petit badge)
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _showSpeciesPickerDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _espece,
                      style: GoogleFonts.exo2(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        style: TextStyle(
            color: sexeColor, fontSize: 22, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent
          ],
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
                  shadows: [
                    const Shadow(
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

  Widget _buildEditableStatGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _editableStatCard('❤️', 'VIE', _hpCtrl, _hpPtsCtrl,
                      const Color(0xFF4CAF50))),
              const SizedBox(width: 10),
              Expanded(
                  child: _editableStatCard('⚡', 'STAM', _staminaCtrl,
                      _staminaPtsCtrl, const Color(0xFFFFD700))),
              const SizedBox(width: 10),
              Expanded(
                  child: _editableStatCard('⚔️', 'ATTAQUE', _degatsCtrl,
                      _degatsPtsCtrl, const Color(0xFFEF4444),
                      suffix: '%', isDouble: true)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _editableStatCard('⚖️', 'POIDS', _poidsCtrl,
                      _poidsPtsCtrl, const Color(0xFF3B82F6))),
              const SizedBox(width: 10),
              Expanded(
                  child: _editableStatCard('🍖', 'FOOD', _nourritureCtrl,
                      _nourriturePtsCtrl, const Color(0xFF8B5CF6))),
              const SizedBox(width: 10),
              Expanded(
                  child: _editableStatCard('🫧', 'OXYGENE', _oxygeneCtrl,
                      _oxygenePtsCtrl, const Color(0xFF10B981))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editableStatCard(String emoji, String label,
      TextEditingController valCtrl, TextEditingController ptsCtrl, Color color,
      {String? suffix, bool isDouble = false}) {
    final valText = valCtrl.text.isEmpty ? '0' : valCtrl.text;
    final displayVal = suffix != null ? '$valText$suffix' : valText;
    final pts = _parsePtsTotal(ptsCtrl.text);

    return GestureDetector(
      onTap: () => _editStatDialog(label, valCtrl, ptsCtrl,
          suffix: suffix, isDouble: isDouble),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(8),
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
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.exo2(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    displayVal,
                    style: GoogleFonts.exo2(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pts > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${pts}pts',
                    style: GoogleFonts.exo2(
                      color: const Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableColorStrip() {
    return Container(
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

          return Expanded(
            child: GestureDetector(
              onTap: () => _showArkColorPicker(i),
              onLongPress: () {
                setState(() => _couleurs[i] = (id: 0, hex: '#808080'));
              },
              child: Container(
                height: 50,
                margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 6)
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  isActive ? '${c.id}' : '-',
                  style: TextStyle(
                    color: isActive
                        ? (_isLight(color) ? Colors.black87 : Colors.white)
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 18,
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
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Boutons d'action en bas ──

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Scanner
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.document_scanner_rounded,
                label: 'SCANNER CRYOPOD / TEK',
                color: const Color(0xFF00E5FF),
                onPressed: _launchScanner,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sauvegarder la DinoCard
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
        // Stats et Couleurs vers tracker
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

  Future<void> _editStatDialog(
    String label,
    TextEditingController valCtrl,
    TextEditingController ptsCtrl, {
    String? suffix,
    bool isDouble = false,
  }) async {
    final tempVal = TextEditingController(text: valCtrl.text);
    final tempPts = TextEditingController(text: ptsCtrl.text);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(label,
            style: GoogleFonts.exo2(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tempVal,
              autofocus: true,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: isDouble),
              inputFormatters: isDouble
                  ? [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,]'))
                    ]
                  : [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText:
                    'Valeur${suffix != null ? ' ($suffix)' : ''}',
                labelStyle: GoogleFonts.exo2(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tempPts,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+]'))
              ],
              style: const TextStyle(color: Colors.cyanAccent),
              decoration: InputDecoration(
                labelText: 'Points (ex: 20+196)',
                labelStyle: GoogleFonts.exo2(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                helperText: 'Saisir le total ou une addition',
                helperStyle: GoogleFonts.exo2(
                    color: AppTheme.textMuted, fontSize: 10),
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
                valCtrl.text = tempVal.text;
                ptsCtrl.text = tempPts.text;
              });
              Navigator.pop(ctx);
            },
            child: Text('OK',
                style: GoogleFonts.exo2(color: AppTheme.accentPrimary)),
          ),
        ],
      ),
    );
    tempVal.dispose();
    tempPts.dispose();
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
                            color: AppTheme.accentGreen
                                .withValues(alpha: 0.4)),
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
                    Navigator.pop(ctx);
                  },
                  child: Text('Valider',
                      style: GoogleFonts.exo2(
                          color: AppTheme.accentPrimary)),
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
    if (result != null && result.trim().isNotEmpty) {
      await provider.addCustomTag(result.trim());
      return result.trim();
    }
    return null;
  }

  Future<void> _showArkColorPicker(int index) async {
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
              onColorSelected: (result) {
                if (!mounted) return;
                setState(() => _couleurs[index] = result);
              },
            ),
          ),
        );
      },
    );
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
                      style:
                          const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        hintStyle: TextStyle(
                            color:
                                Colors.white.withValues(alpha: 0.4)),
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
                                              const Icon(
                                                  Icons.help_outline,
                                                  color: Colors.white38,
                                                  size: 20),
                                        )
                                      : const Icon(
                                          Icons.help_outline,
                                          color: Colors.white38,
                                          size: 20),
                                  title: Text(species,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13)),
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
