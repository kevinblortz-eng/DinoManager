// lib/services/dino_ocr_service.dart
//
// ─── FORMATS SUPPORTÉS ────────────────────────────────────────────────────────
//
// FORMAT A — CRYOPOD (popup inventaire)
//   En-tête : "BABY REX - LVL 363 (REX)"  ou  "BABY TEK GIGA - LVL 362 (TEK GIGA)"
//   Marqueurs : "Cryopod Charge", "Lancez-le", "Peut être rechargé"
//   Couleurs  : ligne de 2 à 6 entiers séparés par espaces (ex: "1 0 2 0 3 2")
//   Mutations : "51035520Mut." ou "-1153432344Mutations (Mat.)"
//   Stats     : "valeur / max" sans (wild|tame|mut)
//   Melee/Spd : pourcentage "1454.7%" ou "100.0%"
//   Imprint   : "100.0%" + ligne suivante "0.0% - NomImprinter"
//
// FORMAT B — JUMELLES TEK / INVENTAIRE VIVANT (creature ciblée)
//   En-tête : "NomDino - Niv. 362"  ou  "NomDino - Niv 419"
//   Marqueurs : "Tamed", "Niv.", "Jujutsu kaisen" (ou tout nom de tribu)
//   Stats     : "15,360.1 / 15,360.1 fr (59 | 0 | 0)"  → wild=59 tame=0 mut=0
//               "523.3 % fr (53 | 0 | 0)"              → Melee
//               "100%" ou "50%"                          → Speed / Imprint
//   Couleurs  : cases numérotées en BAS de la fiche (ex: "79 68 79 79 79 68")
//               → ce sont des niveaux individuels, PAS des couleurs ARK
//               → dans ce format, les couleurs ne sont pas disponibles directement
//   Mutations : "Mutations: ♂ 759,578 ♀ 759,578"  (toujours en BAS)
//
// FORMAT C — INVENTAIRE COMPACT (Acrocanthosaurus cryopod plein écran)
//   Mélange des deux, se comporte comme FORMAT A
//
// ─── COMPORTEMENT IMPRINT ────────────────────────────────────────────────────
// L'imprint +20% affecte HP, Stamina, Weight, Melee.
// Food et Oxygen ne sont PAS affectés.
// Formule : baseVal = displayedVal / (1 + 0.2 * imprint/100)
//
// ─── ORDRE DES STATS DANS ARK ────────────────────────────────────────────────
// 0=HP  1=Stamina  2=Torpor  3=Oxygen  4=Food  5=Water  6=Temp  7=Weight
// 8=Melee%  9=Speed%  10=Fortitude  11=Crafting
//
// ─── MAPPING ICÔNE → STAT ────────────────────────────────────────────────────
// + ou ✚     → HP
// ⚡ ou éclair → Stamina
// ★ étoile   → Torpor (ignoré pour la DinoCard)
// 🍖 viande  → Food
// 🎒 sac     → Weight
// 💉 seringue → Oxygen (parfois)
// 👊 poing   → Melee%
// 🐾 patte   → Speed% (affiché "100%" quasi toujours, ignoré)
// ↓ empreinte → Imprint%
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/dino.dart';
import '../models/ark_color_palette.dart';
import '../models/ark_species_data.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MODÈLE RÉSULTAT OCR
// ═════════════════════════════════════════════════════════════════════════════

class DinoOcrResult {
  final String? species;
  final int? level;
  final String? name;
  final String? sex;
  final String? status;

  final OcrStat? hp;
  final OcrStat? stamina;
  final OcrStat? oxygen;
  final OcrStat? food;
  final OcrStat? weight;
  final OcrStat? melee;
  final OcrStat? speed;
  final OcrStat? torpor;

  final int? mutationsMale;
  final int? mutationsFemale;
  final List<int> colorIds;
  final String? imprinter;
  final double? imprintPercent;
  final String rawText;
  final OcrSourceType sourceType;

  DinoOcrResult({
    this.species,
    this.level,
    this.name,
    this.sex,
    this.status,
    this.hp,
    this.stamina,
    this.oxygen,
    this.food,
    this.weight,
    this.melee,
    this.speed,
    this.torpor,
    this.mutationsMale,
    this.mutationsFemale,
    this.colorIds = const [0, 0, 0, 0, 0, 0],
    this.imprinter,
    this.imprintPercent,
    this.rawText = '',
    this.sourceType = OcrSourceType.unknown,
  });

  bool get hasData =>
      species != null || level != null || hp != null || melee != null;

  double _removeImprintBonus(double value) {
    final imprint = imprintPercent ?? 0;
    if (imprint <= 0) return value;
    return value / (1.0 + 0.2 * imprint / 100.0);
  }

  Dino toDino({bool removeImprint = true}) {
    final ids = List<int>.from(colorIds);
    while (ids.length < 6) {
      ids.add(0);
    }

    final hexes = ids.map((id) {
      if (id > 0) {
        final entry = ArkColorPalette.allColors
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (c) => c?['id'] == id,
              orElse: () => null,
            );
        return (entry?['hex'] as String?) ?? '#808080';
      }
      return '#808080';
    }).toList();

    String dinoSex = 'Inconnu';
    if (sex != null) {
      if (sex!.contains('♀') ||
          sex!.toLowerCase().contains('female') ||
          sex!.toLowerCase().contains('femelle')) {
        dinoSex = 'Femelle';
      } else if (sex!.contains('♂') ||
          sex!.toLowerCase().contains('male') ||
          sex!.toLowerCase().contains('mâle')) {
        dinoSex = 'Mâle';
      }
    }

    double hpVal    = hp?.maxValue ?? 0;
    double stamVal  = stamina?.maxValue ?? 0;
    double oxyVal   = oxygen?.maxValue ?? 0;
    double foodVal  = food?.maxValue ?? 0;
    double weightVal = weight?.maxValue ?? 0;
    double meleeVal = melee?.maxValue ?? 0;

    if (removeImprint && (imprintPercent ?? 0) > 0) {
      hpVal     = _removeImprintBonus(hpVal);
      stamVal   = _removeImprintBonus(stamVal);
      weightVal = _removeImprintBonus(weightVal);
      meleeVal  = _removeImprintBonus(meleeVal);
      // Food et Oxygen ne sont PAS affectés par l'imprint
    }

    final ptsBlock  = _buildPointsBlock();
    final notesText = _buildNotes();
    final finalNotes = ptsBlock.isNotEmpty ? '$notesText\n$ptsBlock' : notesText;

    int totalPts(OcrStat? stat) => stat?.totalPoints ?? 0;

    return Dino(
      nom: name ?? '',
      espece: species ?? 'Rex',
      sexe: dinoSex,
      role: 'Breed',
      niveau: level ?? 0,
      hp: hpVal.round(),
      stamina: stamVal.round(),
      oxygene: oxyVal.round(),
      nourriture: foodVal.round(),
      poids: weightVal.round(),
      degats: meleeVal,
      vitesse: 100.0,
      hpPoints: totalPts(hp),
      staminaPoints: totalPts(stamina),
      oxygenePoints: totalPts(oxygen),
      nourriturePoints: totalPts(food),
      poidsPoints: totalPts(weight),
      degatsPoints: totalPts(melee),
      vitessePoints: 0,
      couleur0: Dino.encodeColor(ids[0], hexes[0]),
      couleur1: Dino.encodeColor(ids[1], hexes[1]),
      couleur2: Dino.encodeColor(ids[2], hexes[2]),
      couleur3: Dino.encodeColor(ids[3], hexes[3]),
      couleur4: Dino.encodeColor(ids[4], hexes[4]),
      couleur5: Dino.encodeColor(ids[5], hexes[5]),
      tagVersion: '',
      tags: _buildAutoTags(),
      notes: finalNotes,
      dateAjout: DateTime.now(),
    );
  }

  String pointsDisplayFor(OcrStat? stat) {
    if (stat == null) return '0';
    if (stat.wildPoints != null && stat.tamePoints != null) {
      if (stat.mutPoints != null && stat.mutPoints! > 0) {
        return '${stat.wildPoints}+${stat.tamePoints}+${stat.mutPoints}';
      }
      return '${stat.wildPoints}+${stat.tamePoints}';
    }
    return '${stat.totalPoints}';
  }

  ({int base, int muta, int perso}) pointsBreakdownFor(OcrStat? stat) {
    if (stat == null) return (base: 0, muta: 0, perso: 0);
    return (
      base: stat.wildPoints ?? 0,
      muta: stat.mutPoints ?? 0,
      perso: stat.tamePoints ?? 0,
    );
  }

  String _buildPointsBlock() {
    final entries = <String>[];
    void addStat(String key, OcrStat? stat) {
      if (stat == null) return;
      final b = stat.wildPoints ?? 0;
      final m = stat.mutPoints ?? 0;
      final p = stat.tamePoints ?? 0;
      if (b > 0 || m > 0 || p > 0) entries.add('$key=$b/$m/$p');
    }
    addStat('hp', hp);
    addStat('stamina', stamina);
    addStat('oxygene', oxygen);
    addStat('nourriture', food);
    addStat('poids', weight);
    addStat('degats', melee);
    if (entries.isEmpty) return '';
    return '[PTS:${entries.join(',')}]';
  }

  List<String> _buildAutoTags() {
    final tags = <String>[];
    if (status != null) {
      if (status!.toLowerCase().contains('badass')) tags.add('Badass');
      if (status!.toLowerCase().contains('wild')) tags.add('Wild');
      if (status!.toLowerCase().contains('tamed')) tags.add('Tamed');
    }
    if ((mutationsMale != null && mutationsMale! > 0) ||
        (mutationsFemale != null && mutationsFemale! > 0)) {
      tags.add('Mutant');
    }
    return tags;
  }

  String _buildNotes() {
    final parts = <String>[];
    parts.add('Import OCR (${sourceType.label})');
    if ((imprintPercent ?? 0) > 0) {
      parts.add(
          'Imprint: ${imprintPercent!.toStringAsFixed(1)}%'
          '${imprinter != null ? ' - $imprinter' : ''}');
      parts.add('⚠️ Stats HP/Stam/Weight/Melee corrigées à 0% imprint');
    }
    if (mutationsMale != null || mutationsFemale != null) {
      parts.add('Mutations: ♂${mutationsMale ?? '?'} ♀${mutationsFemale ?? '?'}');
    }
    return parts.join('\n');
  }
}

// ─── Stat individuelle ───────────────────────────────────────────────────────
class OcrStat {
  final double? currentValue;
  final double? maxValue;
  final int? wildPoints;
  final int? tamePoints;
  final int? mutPoints;
  final bool isPercent;

  OcrStat({
    this.currentValue,
    this.maxValue,
    this.wildPoints,
    this.tamePoints,
    this.mutPoints,
    this.isPercent = false,
  });

  int get totalPoints =>
      (wildPoints ?? 0) + (tamePoints ?? 0) + (mutPoints ?? 0);

  String get pointsDisplay {
    if (wildPoints != null && tamePoints != null) {
      if (mutPoints != null && mutPoints! > 0) {
        return '$wildPoints+$tamePoints+$mutPoints';
      }
      return '$wildPoints+$tamePoints';
    }
    return '$totalPoints';
  }
}

enum OcrSourceType {
  tekBinoculars,
  cryopodTooltip,
  unknown;

  String get label {
    switch (this) {
      case tekBinoculars:
        return 'Jumelles Tek';
      case cryopodTooltip:
        return 'Cryopod';
      case unknown:
        return 'Scan';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DONNÉES DE LIGNE RAW
// ═════════════════════════════════════════════════════════════════════════════

class _RawStatLine {
  final double? current;
  final double? max;
  final int? wild;
  final int? tame;
  final int? mut;
  final bool isPercent;
  final String rawLine;

  _RawStatLine({
    this.current,
    this.max,
    this.wild,
    this.tame,
    this.mut,
    this.isPercent = false,
    this.rawLine = '',
  });

  @override
  String toString() =>
      'RawStat(cur=$current max=$max wild=$wild tame=$tame mut=$mut '
      'pct=$isPercent | "$rawLine")';
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICE OCR PRINCIPAL
// ═════════════════════════════════════════════════════════════════════════════

class DinoOcrService {
  static final DinoOcrService _instance = DinoOcrService._();
  factory DinoOcrService() => _instance;
  DinoOcrService._();

  // Espèces triées par longueur décroissante pour le matching
  static final List<String> _allSpeciesSorted = () {
    final list = List<String>.from(ArkSpeciesData.speciesWithImages);
    list.sort((a, b) => b.length.compareTo(a.length));
    return list;
  }();

  // ── Regex globaux partagés ──────────────────────────────────────────────

  /// Format Tek/Inventaire vivant : "15,360.1 / 15,360.1 fr (59 | 0 | 0)"
  /// Le "fr" est optionnel (suffixe serveur francophone)
  static final _rStatFull = RegExp(
    r'([\d,]+(?:\.\d+)?)\s*/\s*([\d,]+(?:\.\d+)?)\s*(?:fr\s*)?\(\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\)',
  );

  /// Format Tek/Inventaire : "523.3 % fr (53 | 0 | 0)"
  static final _rPctFull = RegExp(
    r'([\d,]+(?:\.\d+)?)\s*%\s*(?:fr\s*)?\(\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\)',
  );

  /// Format Cryopod : "17774.5 / 17774.5"  (sans parenthèses)
  static final _rStatSimple = RegExp(
    r'([\d,]+(?:\.\d+)?)\s*/\s*([\d,]+(?:\.\d+)?)',
  );

  /// Pourcentage seul : "1454.7%"  ou  "100.0%"
  static final _rPctAlone = RegExp(
    r'^[^\d]*([\d,]+(?:\.\d+)?)\s*%(?:\s*[-–]\s*(\S+))?\s*$',
  );

  // ─────────────────────────────────────────────────────────────────────────

  Future<DinoOcrResult> scanImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await textRecognizer.processImage(inputImage);
      final rawText   = recognized.text;
      final lines     = _cleanLines(rawText);

      if (kDebugMode) {
        debugPrint('═══ OCR RAW TEXT ═══\n$rawText\n═══════════════════');
      }

      final sourceType = _detectSourceType(lines, rawText);

      if (kDebugMode) {
        debugPrint('→ Format détecté : ${sourceType.label}');
      }

      switch (sourceType) {
        case OcrSourceType.cryopodTooltip:
          return _parseCryopod(lines, rawText);
        case OcrSourceType.tekBinoculars:
          return _parseTekOrInventory(lines, rawText);
        default:
          // Tente les deux et garde le meilleur
          final cryo = _parseCryopod(lines, rawText);
          final tek  = _parseTekOrInventory(lines, rawText);
          return _score(tek) >= _score(cryo) ? tek : cryo;
      }
    } finally {
      textRecognizer.close();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DÉTECTION DU FORMAT
  // ═══════════════════════════════════════════════════════════════════════════

  OcrSourceType _detectSourceType(List<String> lines, String rawText) {
    final lower = rawText.toLowerCase();

    // Marqueurs forts Cryopod
    if (lower.contains('cryopod charge') ||
        lower.contains('cryopod:') ||
        lower.contains('lancez-le') ||
        lower.contains('déployer la créature') ||
        lower.contains('cryofrigo') ||
        lower.contains('poids : 0,5') ||
        lower.contains('poids: 0.5')) {
      return OcrSourceType.cryopodTooltip;
    }

    // Marqueurs forts Jumelles / Inventaire vivant
    if (_rStatFull.hasMatch(rawText) ||
        _rPctFull.hasMatch(rawText)) {
      return OcrSourceType.tekBinoculars;
    }

    // "Niv." est exclusif au format Tek/inventaire vivant
    if (RegExp(r'[Nn]iv\.?\s*\d').hasMatch(rawText)) {
      return OcrSourceType.tekBinoculars;
    }

    // "Mutations:" (avec deux-points) → format Tek/inventaire
    if (RegExp(r'[Mm]utations\s*:', caseSensitive: false).hasMatch(rawText)) {
      return OcrSourceType.tekBinoculars;
    }

    // "Tamed" sans cryopod → Tek/inventaire
    if (lower.contains('tamed') && !lower.contains('cryopod')) {
      return OcrSourceType.tekBinoculars;
    }

    // "LVL" en majuscules + "(ESPÈCE)" → Cryopod
    if (RegExp(r'LVL\s+\d+\s*\(').hasMatch(rawText)) {
      return OcrSourceType.cryopodTooltip;
    }

    return OcrSourceType.unknown;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSER FORMAT A — CRYOPOD
  // ═══════════════════════════════════════════════════════════════════════════

  DinoOcrResult _parseCryopod(List<String> lines, String rawText) {
    String? species;
    int? level;
    String? sex;
    int? mutMale, mutFemale;
    List<int> colorIds = List.filled(6, 0);
    String? imprinter;
    double? imprintPercent;
    OcrStat? hp, stamina, oxygen, food, weight, melee, speed;

    // ── 1. Sexe (priorité au carré de couleur en haut à gauche) ──
    sex = _extractSex(rawText);

    // ── 2. Titre : "BABY REX - LVL 362 (REX)"
    //              "BABY AUTUMN DRAKELING - LVL 362 (AUTUMN DRAKELING)" ──
    final titleMatch = RegExp(
      r'(?:BABY\s+)?(.+?)\s*[-–]\s*(?:LVL|LEVEL)\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(rawText);

    if (titleMatch != null) {
      // Préférer le nom entre parenthèses en fin de titre s'il existe
      // "BABY GRIFFIN - LVL 363 (GRIFFIN)" → groupe parenthèses = "GRIFFIN"
      final parenMatch = RegExp(
        r'\(([^)]+)\)\s*$',
        caseSensitive: false,
      ).firstMatch(titleMatch.group(0) ?? '');
      final rawSpecies = parenMatch != null
          ? parenMatch.group(1)!
          : titleMatch.group(1)!;
      species = _normalizeSpecies(rawSpecies.trim());
      level   = int.tryParse(titleMatch.group(2)!);
    }

    if (species == null || level == null) {
      species ??= _findSpeciesInText(rawText);
      level   ??= _extractLevel(rawText);
    }

    // ── 3. Lignes de stats (filtrage des parasites) ──
    final statLines = _filterStatLines(lines, OcrSourceType.cryopodTooltip);

    // ── 4. Parse chaque ligne ──
    final nonPct = <_RawStatLine>[];
    final pcts   = <_RawStatLine>[];
    final imprints = <_RawStatLine>[];

    for (final line in statLines) {
      final raw = _parseStatLine(line);
      if (raw == null) continue;

      if (_isImprintPercent(line, raw)) {
        imprints.add(raw);
        // Tenter d'extraire le nom de l'imprinter : "100.0% - Maxime"
        final nameM = RegExp(r'%\s*[-–]\s*(\S+)').firstMatch(line);
        if (nameM != null && imprinter == null) imprinter = nameM.group(1);
      } else if (raw.isPercent) {
        pcts.add(raw);
      } else {
        nonPct.add(raw);
      }
    }

    // ── 5. Attribution des stats ──
    // Ordre ARK Cryopod (affiché) : HP, Stamina, Weight, Food, Oxygen, Torpor
    // On distingue par les valeurs typiques :
    //   HP      : la plus grande valeur non-% (rarement < 100)
    //   Stamina : 2ème valeur /max
    //   Weight  : valeur intermédiaire
    //   Food    : peut être très grande sur un dino élevé
    //   Torpor  : toujours la dernière, très grande
    // On utilise l'ordre d'apparition car ARK affiche toujours dans le même ordre
    final assignedNP = List<bool>.filled(nonPct.length, false);

    // HP = 1er non-% non-torpeur (valeur > 0)
    hp      = _pickStat(nonPct, assignedNP, idx: 0);
    stamina = _pickStat(nonPct, assignedNP, idx: 1);
    weight  = _pickStat(nonPct, assignedNP, idx: 2);
    food    = _pickStat(nonPct, assignedNP, idx: 3);
    oxygen  = _pickStat(nonPct, assignedNP, idx: 4);

    // Melee = 1er %  > 100  (ex: 1454.7%, 882.0%)
    // Speed = % proche de 100 (ex: 100.0%)
    // Imprint = % ≤ 100 sur une ligne d'imprint
    for (final raw in pcts) {
      final v = raw.max ?? 0;
      if (v > 105 && melee == null) {
        melee = _toStat(raw);
      } else if (v <= 105 && speed == null) {
        speed = _toStat(raw);
      }
    }

    // L'imprint peut être une ligne "100.0% fr (0|0|0)" avec v=100
    // → distingué par _isImprintPercent
    if (imprintPercent == null && imprints.isNotEmpty) {
      imprintPercent = imprints.first.max;
    }

    // Fallback imprint dans les pcts si aucune trouvée
    if (imprintPercent == null) {
      for (final raw in pcts) {
        final v = raw.max ?? 0;
        if (v <= 100) {
          imprintPercent = v;
          break;
        }
      }
    }

    // ── 6. Couleurs ──
    colorIds = _extractColorsCryopod(lines);

    // ── 7. Mutations ──
    _parseMutations(lines, rawText, (m, f) {
      mutMale   = m;
      mutFemale = f;
    });

    return DinoOcrResult(
      species: species,
      level: level,
      sex: sex,
      hp: hp,
      stamina: stamina,
      oxygen: oxygen,
      food: food,
      weight: weight,
      melee: melee,
      speed: speed,
      mutationsMale: mutMale,
      mutationsFemale: mutFemale,
      colorIds: colorIds,
      imprinter: imprinter,
      imprintPercent: imprintPercent,
      rawText: rawText,
      sourceType: OcrSourceType.cryopodTooltip,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSER FORMAT B — JUMELLES TEK / INVENTAIRE VIVANT
  // ═══════════════════════════════════════════════════════════════════════════

  DinoOcrResult _parseTekOrInventory(List<String> lines, String rawText) {
    String? species;
    int? level;
    String? sex;
    String? status;
    int? mutMale, mutFemale;
    List<int> colorIds = List.filled(6, 0);
    String? imprinter;
    double? imprintPercent;
    OcrStat? hp, stamina, oxygen, food, weight, melee, speed;

    // ── 1. Sexe ──
    sex = _extractSex(rawText);

    // ── 2. Titre : "Maeguana - Niv. 362" ou "Nihael - Niv. 419" ──
    final titleMatch = RegExp(
      r'([A-Za-z][A-Za-z0-9 -]+?)\s*-\s*(?:Niv[.]?|LVL|Lvl)\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(rawText);

    if (titleMatch != null) {
      species = _normalizeSpecies(titleMatch.group(1)!.trim());
      level   = int.tryParse(titleMatch.group(2)!);
    }

    if (species == null || level == null) {
      species ??= _findSpeciesInText(rawText);
      level   ??= _extractLevel(rawText);
    }

    // ── 3. Statut ──
    final lower = rawText.toLowerCase();
    final statusParts = <String>[];
    if (lower.contains('tamed')) statusParts.add('Tamed');
    if (lower.contains('wild') && !lower.contains('wildlevel')) statusParts.add('Wild');
    if (lower.contains('badass')) statusParts.add('Badass');
    if (statusParts.isNotEmpty) status = statusParts.join(' ');

    // ── 4. Lignes de stats ──
    final statLines = _filterStatLines(lines, OcrSourceType.tekBinoculars);
    final nonPct  = <_RawStatLine>[];
    final pcts    = <_RawStatLine>[];
    final imprints = <_RawStatLine>[];

    for (final line in statLines) {
      final raw = _parseStatLine(line);
      if (raw == null) continue;

      if (_isImprintPercent(line, raw)) {
        imprints.add(raw);
        final nameM = RegExp(r'%\s*[-–]\s*(\S+)').firstMatch(line);
        if (nameM != null && imprinter == null) imprinter = nameM.group(1);
      } else if (raw.isPercent) {
        pcts.add(raw);
      } else {
        nonPct.add(raw);
      }
    }

    // ── 5. Attribution Tek/Inventaire ──
    // Ordre d'affichage ARK (jumelles/inventaire) :
    // HP, Stamina, Torpor, Food, Weight, Oxygen, Melee%, Speed%, Imprint%
    //
    // DIFFÉRENCE avec Cryopod : ici on a les points (wild|tame|mut)
    // ET Torpor apparaît → il faut l'ignorer pour la DinoCard
    // La Torpeur se reconnaît : très grande valeur max, current=0, wild=0 souvent

    final assignedNP = List<bool>.filled(nonPct.length, false);

    // HP = 1er
    hp = _pickStat(nonPct, assignedNP, idx: 0);
    // Stamina = 2ème
    stamina = _pickStat(nonPct, assignedNP, idx: 1);
    // 3ème = Torpor (à détecter et ignorer si énorme)
    // On cherche la torpeur : c'est celle avec current=0 et max très grande
    int torpIdx = -1;
    for (int i = 2; i < nonPct.length; i++) {
      if (!assignedNP[i]) {
        final v = nonPct[i];
        // Torpeur : current=0 ou très faible, max souvent > 1000
        if ((v.current ?? 0) == 0 && (v.max ?? 0) > 500) {
          torpIdx = i;
          assignedNP[i] = true;
          break;
        }
        // Si pas de points du tout → probablement Torpeur aussi
        if (v.wild == null || v.wild == 0) {
          final maxVal = v.max ?? 0;
          if (maxVal > 5000) {
            torpIdx = i;
            assignedNP[i] = true;
            break;
          }
        }
        break; // Si rien de concluant, on continue normalement
      }
    }
    if (kDebugMode && torpIdx >= 0) {
      debugPrint('→ Torpeur détectée à index $torpIdx, ignorée');
    }

    // Food, Weight, Oxygen (ordre ARK après torpeur)
    food   = _pickStat(nonPct, assignedNP, idx: -1); // prochaine dispo
    weight = _pickStat(nonPct, assignedNP, idx: -1);
    oxygen = _pickStat(nonPct, assignedNP, idx: -1);

    // Melee et Speed depuis les %
    for (final raw in pcts) {
      final v = raw.max ?? 0;
      if (v > 105 && melee == null) {
        melee = _toStat(raw);
      } else if (v <= 105 && speed == null) {
        speed = _toStat(raw);
      }
    }

    if (imprintPercent == null && imprints.isNotEmpty) {
      imprintPercent = imprints.first.max;
    }

    // ── 6. Couleurs ──
    // Dans le format Tek/Inventaire, les couleurs ne sont pas affichées
    // (les cases numériques en bas = niveaux par stat, pas couleurs ARK)
    // → on retourne [0,0,0,0,0,0] pour signaler "non disponible"
    colorIds = List.filled(6, 0);

    // ── 7. Mutations ──
    _parseMutations(lines, rawText, (m, f) {
      mutMale   = m;
      mutFemale = f;
    });

    return DinoOcrResult(
      species: species,
      level: level,
      sex: sex,
      status: status,
      hp: hp,
      stamina: stamina,
      oxygen: oxygen,
      food: food,
      weight: weight,
      melee: melee,
      speed: speed,
      mutationsMale: mutMale,
      mutationsFemale: mutFemale,
      colorIds: colorIds,
      imprinter: imprinter,
      imprintPercent: imprintPercent,
      rawText: rawText,
      sourceType: OcrSourceType.tekBinoculars,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSING D'UNE LIGNE DE STAT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tente de parser une ligne de stat dans tous les formats connus.
  /// Retourne null si la ligne ne contient pas de stat valide.
  _RawStatLine? _parseStatLine(String line) {
    // FORMAT TEK COMPLET : "15,360.1 / 15,360.1 fr (59 | 0 | 0)"
    final mFull = _rStatFull.firstMatch(line);
    if (mFull != null) {
      return _RawStatLine(
        current: _parseNum(mFull.group(1)!),
        max:     _parseNum(mFull.group(2)!),
        wild:    int.tryParse(mFull.group(3)!) ?? 0,
        tame:    int.tryParse(mFull.group(4)!) ?? 0,
        mut:     int.tryParse(mFull.group(5)!) ?? 0,
        isPercent: false,
        rawLine: line,
      );
    }

    // FORMAT TEK % COMPLET : "523.3 % fr (53 | 0 | 0)"
    final mPctFull = _rPctFull.firstMatch(line);
    if (mPctFull != null) {
      return _RawStatLine(
        current: _parseNum(mPctFull.group(1)!),
        max:     _parseNum(mPctFull.group(1)!),
        wild:    int.tryParse(mPctFull.group(2)!) ?? 0,
        tame:    int.tryParse(mPctFull.group(3)!) ?? 0,
        mut:     int.tryParse(mPctFull.group(4)!) ?? 0,
        isPercent: true,
        rawLine: line,
      );
    }

    // FORMAT CRYOPOD SIMPLE : "17774.5 / 17774.5"
    // Attention : doit avoir au moins un chiffre côté max
    final mSimple = _rStatSimple.firstMatch(line);
    if (mSimple != null) {
      final cur = _parseNum(mSimple.group(1)!);
      final max = _parseNum(mSimple.group(2)!);
      if (max != null && max > 0) {
        return _RawStatLine(
          current: cur,
          max: max,
          isPercent: false,
          rawLine: line,
        );
      }
    }

    // POURCENTAGE SEUL : "1454.7%"  ou  "100.0% - Maxime"
    final mPct = _rPctAlone.firstMatch(line);
    if (mPct != null) {
      final val = _parseNum(mPct.group(1)!);
      if (val != null) {
        return _RawStatLine(
          current: val,
          max: val,
          isPercent: true,
          rawLine: line,
        );
      }
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTRAGE DES LIGNES (élimination des parasites)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Retourne uniquement les lignes susceptibles de contenir des stats.
  List<String> _filterStatLines(List<String> lines, OcrSourceType type) {
    final result = <String>[];

    // Mots-clés à exclure dans tous les formats
    const globalExclusions = [
      'cryopod charge',
      'lancez-le',
      'peut être rechargé',
      'cryofrigo',
      'poids : 0',  // "Poids : 0,5" → poids du cryopod objet
      'weight: 0.5',
      'deploy',
      'throw to deploy',
      'can be recharged',
      'stockez',
      'recharger',
      'garder en vie',
      'toujours',
    ];

    // Mots-clés à exclure uniquement en Tek/Inventaire
    const tekExclusions = [
      // Les lignes de titre (déjà parsées)
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Exclure lignes vides / trop courtes
      if (line.length < 3) continue;

      // Exclure si contient un mot-clé global parasitaire
      if (globalExclusions.any((k) => lower.contains(k))) continue;

      // Exclure les lignes de mutations (parsées séparément)
      if (lower.contains('mutation')) continue;

      // Exclure les lignes de titre (niveau + espèce)
      // "BABY ... - LVL ..." ou "Nihael - Niv. 362"
      if (RegExp(r'[-–]\s*(?:LVL|LEVEL|Niv\.?)\s*\d', caseSensitive: false)
          .hasMatch(line)) continue;

      // Exclure "Tamed", "Wild", "Badass" seuls sur une ligne
      if (RegExp(r'^(?:Tamed|Wild|Badass)\s*$', caseSensitive: false)
          .hasMatch(line)) continue;

      // Exclure noms de tribu / imprinter seuls (pas de chiffres stats)
      // Ces lignes n'ont pas de '/' ni '%' ni chiffres suivis d'unités
      final hasStatPattern = line.contains('/') ||
          line.contains('%') ||
          RegExp(r'\d+\.\d').hasMatch(line);
      if (!hasStatPattern) continue;

      // Exclure "N/A"
      if (lower.trim() == 'n/a') continue;

      if (type == OcrSourceType.tekBinoculars) {
        for (final k in tekExclusions) {
          if (lower.contains(k)) continue;
        }
      }

      result.add(line);
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTRACTION DES COULEURS — FORMAT CRYOPOD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dans le Cryopod, les couleurs sont affichées comme une ligne de 2 à 6
  /// entiers entre 0 et 100, placée entre le header et les stats de mutations.
  ///
  /// Exemple : "1 0 2 0 3 2"  →  [1,0,2,0,3,2]
  /// Exemple : "2 4 2 1 3"    →  [2,4,2,1,3,0]
  /// Exemple : "4 1 4"        →  [4,1,4,0,0,0]
  ///
  /// Ces entiers sont les ColorSetIndices ARK (IDs dans ArkColorPalette).
  List<int> _extractColorsCryopod(List<String> lines) {
    final result = List<int>.filled(6, 0);

    // Stratégie 1 : chercher une ligne contenant UNIQUEMENT des entiers 0-100
    // séparés par espaces (c'est la ligne de couleurs ARK)
    for (final line in lines) {
      // Exclure les lignes avec des stats ou des textes parasites
      if (line.contains('/') ||
          line.contains('%') ||
          line.contains('|') ||
          line.contains('.') ||
          line.toLowerCase().contains('mutation') ||
          line.toLowerCase().contains('lvl') ||
          line.toLowerCase().contains('niv') ||
          line.toLowerCase().contains('cryopod') ||
          line.toLowerCase().contains('baby') ||
          line.toLowerCase().contains('tamed')) {
        continue;
      }

      final nums = RegExp(r'\b(\d{1,3})\b')
          .allMatches(line)
          .map((m) => int.parse(m.group(1)!))
          .where((n) => n >= 0 && n <= 100)
          .toList();

      // Entre 2 et 6 entiers → ligne de couleurs très probable
      if (nums.length >= 2 && nums.length <= 6) {
        for (int i = 0; i < nums.length && i < 6; i++) {
          result[i] = nums[i];
        }
        if (kDebugMode) {
          debugPrint('→ Couleurs extraites (méthode 1) : $result depuis "$line"');
        }
        return result;
      }
    }

    // Stratégie 2 : chercher dans toutes les lignes, mais en ignorant celles
    // qui ont visiblement des stats (les lignes de couleurs viennent AVANT
    // les stats dans le Cryopod)
    bool reachedStats = false;
    for (final line in lines) {
      // Les stats commencent quand on trouve "/ " + chiffres
      if (_rStatSimple.hasMatch(line) || _rStatFull.hasMatch(line)) {
        reachedStats = true;
        break;
      }
      if (reachedStats) break;

      if (line.contains('/') || line.contains('%') || line.contains('|')) {
        continue;
      }

      final lower = line.toLowerCase();
      if (lower.contains('mutation') || lower.contains('lvl') ||
          lower.contains('niv') || lower.contains('cryopod') ||
          lower.contains('baby') || lower.contains('poids') ||
          lower.contains('weight') || lower.contains('tamed') ||
          lower.contains('lancez') || lower.contains('deploy')) {
        continue;
      }

      final nums = RegExp(r'\b(\d{1,3})\b')
          .allMatches(line)
          .map((m) => int.parse(m.group(1)!))
          .where((n) => n >= 0 && n <= 100)
          .toList();

      if (nums.length >= 2 && nums.length <= 6) {
        for (int i = 0; i < nums.length && i < 6; i++) {
          result[i] = nums[i];
        }
        if (kDebugMode) {
          debugPrint('→ Couleurs extraites (méthode 2) : $result depuis "$line"');
        }
        return result;
      }
    }

    // Stratégie 3 : chercher la ligne la plus probable globalement
    // (hors stats connues, hors mutations, entiers petits)
    final candidates = <List<int>>[];
    for (final line in lines) {
      if (line.contains('/') || line.contains('|') || line.contains('%') ||
          line.contains('.') || line.length > 30) continue;
      final lower = line.toLowerCase();
      if (lower.contains('mutation') || lower.contains('baby') ||
          lower.contains('cryopod') || lower.contains('poids') ||
          lower.contains('weight') || lower.contains('tamed') ||
          lower.contains('lvl') || lower.contains('niv')) continue;

      final nums = RegExp(r'\b(\d{1,2})\b')
          .allMatches(line)
          .map((m) => int.parse(m.group(1)!))
          .where((n) => n >= 0 && n <= 60)
          .toList();

      if (nums.length >= 2 && nums.length <= 6) {
        candidates.add(nums);
      }
    }

    if (candidates.isNotEmpty) {
      // Préférer celle avec le plus d'éléments
      candidates.sort((a, b) => b.length.compareTo(a.length));
      final best = candidates.first;
      for (int i = 0; i < best.length && i < 6; i++) {
        result[i] = best[i];
      }
      if (kDebugMode) {
        debugPrint('→ Couleurs extraites (méthode 3) : $result');
      }
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSING DES MUTATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gère tous les formats de mutations observés :
  ///
  /// FORMAT A Cryopod : "51035520Mut."          → male=51035520
  ///                    "-1153432344Mutations (Mat.)"  → female=-1153432344
  ///                    "-166048494Mutations (Mat.)"   → female=-166048494
  ///                    "-830242470Mutations (Pat.)"   → male=-830242470
  ///   La même ligne peut contenir ♀ nombre "Mut." et ♂ nombre "Mut."
  ///
  /// FORMAT B Tek/Inv  : "Mutations: ♂ 759,578 ♀ 759,578"
  ///                     "Mutations: ♂ -1,957,092,014 ♀ 0"
  void _parseMutations(
    List<String> lines,
    String rawText,
    void Function(int? male, int? female) callback,
  ) {
    int? mutMale;
    int? mutFemale;

    // ── FORMAT B : "Mutations: ♂ X ♀ Y" ──────────────────────────────────
    // Format avec séparateur deux-points (Jumelles / Inventaire vivant)
    final mutColonRegex = RegExp(
      r'[Mm]utations\s*:\s*[♂♀]?\s*([+-]?[\d,]+)\s*[♂♀]\s*([+-]?[\d,]+)',
    );
    // Cas "Mutations: ♂ X ♀ Y"
    final mutFullMF = RegExp(
      r'[Mm]utations\s*:\s*♂\s*([+-]?[\d,]+)\s*♀\s*([+-]?[\d,]+)',
    );
    // Cas "Mutations: ♀ X ♂ Y" (ordre inversé)
    final mutFullFM = RegExp(
      r'[Mm]utations\s*:\s*♀\s*([+-]?[\d,]+)\s*♂\s*([+-]?[\d,]+)',
    );

    for (final line in lines) {
      // "Mutations: ♂ X ♀ Y"
      var m = mutFullMF.firstMatch(line);
      if (m != null) {
        mutMale   = _parseMutNum(m.group(1)!);
        mutFemale = _parseMutNum(m.group(2)!);
        callback(mutMale, mutFemale);
        return;
      }
      // "Mutations: ♀ X ♂ Y"
      m = mutFullFM.firstMatch(line);
      if (m != null) {
        mutFemale = _parseMutNum(m.group(1)!);
        mutMale   = _parseMutNum(m.group(2)!);
        callback(mutMale, mutFemale);
        return;
      }
      // Fallback Mutations: X Y (sans symboles explicites)
      m = mutColonRegex.firstMatch(line);
      if (m != null) {
        mutMale   = _parseMutNum(m.group(1)!);
        mutFemale = _parseMutNum(m.group(2)!);
        callback(mutMale, mutFemale);
        return;
      }
    }

    // ── FORMAT A : lignes avec ♀/♂ + nombre + Mut. ────────────────────────
    // "♀ 26160Mutations" ou "26160Mutations" ou "-1660484940Mutations (Mat.)"
    //
    // Sur une ligne Cryopod, les deux sexes apparaissent côte à côte :
    // "♀ 26160Mutations   ♂ 26160Mutations"
    // ou chacun sur sa propre ligne.
    //
    // "(Mat.)" = maternel → femelle
    // "(Pat.)" = paternel → mâle

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('mut')) continue;

      // Cas avec ♀ et ♂ sur la même ligne
      final bothOnLine = RegExp(
        r'♀\s*([+-]?[\d,]+)\s*[Mm]ut[^\s]*\s*.*?♂\s*([+-]?[\d,]+)\s*[Mm]ut',
      ).firstMatch(line);
      if (bothOnLine != null) {
        mutFemale = _parseMutNum(bothOnLine.group(1)!);
        mutMale   = _parseMutNum(bothOnLine.group(2)!);
        callback(mutMale, mutFemale);
        return;
      }

      final bothInv = RegExp(
        r'♂\s*([+-]?[\d,]+)\s*[Mm]ut[^\s]*\s*.*?♀\s*([+-]?[\d,]+)\s*[Mm]ut',
      ).firstMatch(line);
      if (bothInv != null) {
        mutMale   = _parseMutNum(bothInv.group(1)!);
        mutFemale = _parseMutNum(bothInv.group(2)!);
        callback(mutMale, mutFemale);
        return;
      }

      // "(Mat.)" ou "(mat)" → femelle
      if (lower.contains('mat')) {
        final m = RegExp(r'([+-]?[\d,]+)\s*[Mm]utations?\s*\(?[Mm]at').firstMatch(line);
        if (m != null) mutFemale = _parseMutNum(m.group(1)!);
      }

      // "(Pat.)" ou "(pat)" → mâle
      if (lower.contains('pat')) {
        final m = RegExp(r'([+-]?[\d,]+)\s*[Mm]utations?\s*\(?[Pp]at').firstMatch(line);
        if (m != null) mutMale = _parseMutNum(m.group(1)!);
      }

      // ♀ X Mutations / ♀ XMut.
      if (line.contains('♀') && mutFemale == null) {
        final m = RegExp(r'♀\s*([+-]?[\d,]+)\s*[Mm]ut').firstMatch(line);
        if (m != null) mutFemale = _parseMutNum(m.group(1)!);
      }

      // ♂ X Mutations / ♂ XMut.
      if (line.contains('♂') && mutMale == null) {
        final m = RegExp(r'♂\s*([+-]?[\d,]+)\s*[Mm]ut').firstMatch(line);
        if (m != null) mutMale = _parseMutNum(m.group(1)!);
      }

      // Cas sans symbole : "51035520Mut."  (ligne avec JUSTE le nombre + Mut)
      // → attribue aux deux si ni l'un ni l'autre trouvé
      if (mutMale == null && mutFemale == null) {
        final m = RegExp(r'^([+-]?[\d,]+)\s*[Mm]ut').firstMatch(line.trim());
        if (m != null) {
          final v = _parseMutNum(m.group(1)!);
          mutMale   = v;
          mutFemale = v;
        }
      }
    }

    // Fallback : chercher ♂/♀ + nombre n'importe où
    if (mutMale == null) {
      final m = RegExp(r'♂\s*([+-]?[\d,]+)').firstMatch(rawText);
      if (m != null) mutMale = _parseMutNum(m.group(1)!);
    }
    if (mutFemale == null) {
      final m = RegExp(r'♀\s*([+-]?[\d,]+)').firstMatch(rawText);
      if (m != null) mutFemale = _parseMutNum(m.group(1)!);
    }

    callback(mutMale, mutFemale);
  }

  /// Parse un nombre de mutations qui peut être négatif ou avoir des virgules
  /// "759,578" → 759578 ;  "-1,957,092,014" → -1957092014
  int? _parseMutNum(String s) {
    final cleaned = s.replaceAll(',', '').trim();
    return int.tryParse(cleaned);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCHING D'ESPÈCES
  // ═══════════════════════════════════════════════════════════════════════════

  String _normalizeSpecies(String raw) {
    // Nettoyer les artefacts OCR classiques
    String cleaned = raw
        .replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ\s\-\(\)]'), '')
        .trim();
    final lower = cleaned.toLowerCase();

    // Match exact
    for (final sp in _allSpeciesSorted) {
      if (sp.toLowerCase() == lower) return sp;
    }
    // Contient
    for (final sp in _allSpeciesSorted) {
      if (lower.contains(sp.toLowerCase())) return sp;
    }
    for (final sp in _allSpeciesSorted) {
      if (sp.toLowerCase().contains(lower) && lower.length >= 4) return sp;
    }
    // Similarité
    String? best;
    double bestScore = 0;
    for (final sp in _allSpeciesSorted) {
      final s = _similarity(lower, sp.toLowerCase());
      if (s > bestScore && s >= 0.6) {
        bestScore = s;
        best = sp;
      }
    }
    if (best != null) return best;

    // Match mots
    final words = lower.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      for (final sp in _allSpeciesSorted) {
        final spWords = sp.toLowerCase().split(RegExp(r'\s+'));
        if (spWords.length >= 2) {
          int matched = 0;
          for (final w in words) {
            for (final sw in spWords) {
              if (_similarity(w, sw) >= 0.7) { matched++; break; }
            }
          }
          if (matched >= 2) return sp;
        }
      }
      for (final w in words) {
        if (w.length < 4) continue;
        for (final sp in _allSpeciesSorted) {
          if (!sp.contains(' ') && _similarity(w, sp.toLowerCase()) >= 0.7) {
            return sp;
          }
        }
      }
    }

    return cleaned.split(' ').map((w) => w.isEmpty
        ? w
        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  String? _findSpeciesInText(String text) {
    final lower = text.toLowerCase();
    for (final sp in _allSpeciesSorted) {
      if (lower.contains(sp.toLowerCase())) return sp;
    }
    final words = lower.split(RegExp(r'[^a-z]+'));
    for (int i = 0; i < words.length - 1; i++) {
      final pair = '${words[i]} ${words[i + 1]}';
      for (final sp in _allSpeciesSorted) {
        if (_similarity(pair, sp.toLowerCase()) >= 0.75) return sp;
      }
    }
    for (final w in words) {
      if (w.length < 4) continue;
      for (final sp in _allSpeciesSorted) {
        if (_similarity(w, sp.toLowerCase()) >= 0.75) return sp;
      }
    }
    return null;
  }

  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final dist = _levenshtein(a, b);
    return 1.0 - (dist / max(a.length, b.length));
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = List.generate(a.length + 1, (i) => List.generate(b.length + 1, (j) => 0));
    for (int i = 0; i <= a.length; i++) m[i][0] = i;
    for (int j = 0; j <= b.length; j++) m[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        m[i][j] = [m[i-1][j]+1, m[i][j-1]+1, m[i-1][j-1]+cost].reduce(min);
      }
    }
    return m[a.length][b.length];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  List<String> _cleanLines(String rawText) {
    return rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  String _extractSex(String rawText) {
    // L'icône de sexe dans ARK peut être lue comme ♀ ou ♂
    // Mais aussi comme "Q" (OCR de ♀) ou "d" (OCR de ♂)
    if (rawText.contains('♀')) return '♀';
    if (rawText.contains('♂')) return '♂';
    // Fallback sur la position : le badge de sexe est en haut à gauche de la carte
    // Dans Cryopod : carré rose = ♀, carré bleu = ♂
    // On ne peut pas déduire depuis OCR seul → 'Inconnu'
    return 'Inconnu';
  }

  int? _extractLevel(String rawText) {
    final m = RegExp(r'(?:LVL|Lvl|lvl|LEVEL|Level|Niv\.?)\s*(\d+)',
        caseSensitive: false).firstMatch(rawText);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  /// Détermine si une ligne/stat représente l'imprint (% ≤ 100 affiché seul)
  /// Format Tek : ligne avec icône ↓ (empreinte) et "100%" ou "50%"
  /// Format Cryo : ligne "100.0% - Maxime" ou "0.0% - Maxime"
  bool _isImprintPercent(String line, _RawStatLine raw) {
    if (!raw.isPercent) return false;
    final v = raw.max ?? 0;
    if (v > 100) return false; // Melee > 100%, jamais l'imprint

    final lower = line.toLowerCase();
    if (lower.contains('imprint')) return true;

    // "X.X% - NomImprinter" → pattern imprint cryopod
    if (RegExp(r'[\d.]+\s*%\s*[-–]\s*\w').hasMatch(line)) return true;

    // "X.X% fr (0|0|0)" avec wild=0, tame=0, mut=0 → souvent imprint ou speed
    // On ne peut pas trancher ici, on laisse l'attribution par ordre
    return false;
  }

  OcrStat? _pickStat(List<_RawStatLine> list, List<bool> assigned, {required int idx}) {
    if (idx >= 0) {
      // Index direct
      if (idx < list.length && !assigned[idx]) {
        assigned[idx] = true;
        return _toStat(list[idx]);
      }
      return null;
    } else {
      // Premier disponible
      for (int i = 0; i < list.length; i++) {
        if (!assigned[i]) {
          assigned[i] = true;
          return _toStat(list[i]);
        }
      }
      return null;
    }
  }

  OcrStat _toStat(_RawStatLine raw) {
    return OcrStat(
      currentValue: raw.current,
      maxValue:     raw.max,
      wildPoints:   raw.wild,
      tamePoints:   raw.tame,
      mutPoints:    raw.mut,
      isPercent:    raw.isPercent,
    );
  }

  double? _parseNum(String text) {
    return double.tryParse(text.replaceAll(',', '').trim());
  }

  int _score(DinoOcrResult r) {
    int s = 0;
    if (r.species != null) s += 10;
    if (r.level != null)   s += 5;
    if (r.hp != null)      s += 3;
    if (r.stamina != null) s += 3;
    if (r.melee != null)   s += 3;
    if (r.colorIds.any((c) => c > 0)) s += 5;
    if (r.hp?.wildPoints != null) s += 5;
    if (r.mutationsMale != null)  s += 3;
    return s;
  }
}