// lib/services/dino_ocr_service.dart
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/dino.dart';
import '../models/ark_color_palette.dart';
import '../models/ark_species_data.dart';

// ─── Résultat enrichi ───
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
  final OcrStat? speed; // Conservé pour le parsing, non utilisé dans l'app
  final OcrStat? torpor; // Conservé pour le parsing, non utilisé dans l'app

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

  /// Stats corrigées à 0% imprint.
  /// L'imprint ajoute +20% sur HP, Stamina, Weight, Melee (pas Food, Oxygen).
  /// Formule: statBase = statAffichée / (1 + 0.2 * imprint/100)
  double _removeImprintBonus(double value, bool isAffectedByImprint) {
    if (!isAffectedByImprint) return value;
    final imprint = imprintPercent ?? 0;
    if (imprint <= 0) return value;
    final multiplier = 1.0 + (0.2 * imprint / 100.0);
    return value / multiplier;
  }

  /// Convertit le résultat OCR en Dino.
  /// Les points sont stockés dans le format [PTS:hp=base/muta/perso,...] dans les notes.
  /// - wildPoints → base (points wild / de base)
  /// - mutPoints → muta (points de mutation)
  /// - tamePoints → perso (points investis manuellement / level up)
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

    // Corriger les stats si imprint > 0
    double hpVal = hp?.maxValue ?? 0;
    double stamVal = stamina?.maxValue ?? 0;
    double oxyVal = oxygen?.maxValue ?? 0;
    double foodVal = food?.maxValue ?? 0;
    double weightVal = weight?.maxValue ?? 0;
    double meleeVal = melee?.maxValue ?? 0;

    if (removeImprint && (imprintPercent ?? 0) > 0) {
      hpVal = _removeImprintBonus(hpVal, true);
      stamVal = _removeImprintBonus(stamVal, true);
      weightVal = _removeImprintBonus(weightVal, true);
      meleeVal = _removeImprintBonus(meleeVal, true);
      // Food, Oxygen ne sont PAS affectés par l'imprint
    }

    // Construire le bloc [PTS:...] avec base/muta/perso
    final ptsBlock = _buildPointsBlock();
    final notesText = _buildNotes();
    final finalNotes =
        ptsBlock.isNotEmpty ? '$notesText\n$ptsBlock' : notesText;

    // Total points pour compatibilité avec les champs existants du modèle
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

  /// Retourne l'affichage des points pour le dialog de scan
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

  /// Retourne les 3 valeurs séparées : base, muta, perso
  /// - base = wildPoints (points wild / de base)
  /// - muta = mutPoints (points de mutation)
  /// - perso = tamePoints (points investis manuellement)
  ({int base, int muta, int perso}) pointsBreakdownFor(OcrStat? stat) {
    if (stat == null) return (base: 0, muta: 0, perso: 0);
    return (
      base: stat.wildPoints ?? 0,
      muta: stat.mutPoints ?? 0,
      perso: stat.tamePoints ?? 0,
    );
  }

  /// Construit le bloc [PTS:hp=base/muta/perso,...] pour les notes
  String _buildPointsBlock() {
    final entries = <String>[];

    void addStat(String key, OcrStat? stat) {
      if (stat == null) return;
      final b = stat.wildPoints ?? 0;
      final m = stat.mutPoints ?? 0;
      final p = stat.tamePoints ?? 0;
      if (b > 0 || m > 0 || p > 0) {
        entries.add('$key=$b/$m/$p');
      }
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
          'Imprint: ${imprintPercent!.toStringAsFixed(1)}%${imprinter != null ? ' - $imprinter' : ''}');
      parts.add('⚠️ Stats HP/Stam/Weight/Melee corrigées à 0% imprint');
    }
    if (mutationsMale != null || mutationsFemale != null) {
      parts.add(
          'Mutations: ♂${mutationsMale ?? '?'} ♀${mutationsFemale ?? '?'}');
    }
    return parts.join('\n');
  }
}

// ─── Stat individuelle ───
class OcrStat {
  final double? currentValue;
  final double? maxValue;
  final int? wildPoints;  // → base
  final int? tamePoints;  // → perso (points investis)
  final int? mutPoints;   // → muta
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

// ─── Service OCR principal ───
class DinoOcrService {
  static final DinoOcrService _instance = DinoOcrService._();
  factory DinoOcrService() => _instance;
  DinoOcrService._();

  static final List<String> _allSpeciesSorted = () {
    final list = List<String>.from(ArkSpeciesData.speciesWithImages);
    list.sort((a, b) => b.length.compareTo(a.length));
    return list;
  }();

  Future<DinoOcrResult> scanImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      final lines = rawText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final sourceType = _detectSourceType(lines, rawText);

      switch (sourceType) {
        case OcrSourceType.tekBinoculars:
          return _parseTekBinoculars(lines, rawText);
        case OcrSourceType.cryopodTooltip:
          return _parseCryopodTooltip(lines, rawText);
        default:
          final tek = _parseTekBinoculars(lines, rawText);
          final cryo = _parseCryopodTooltip(lines, rawText);
          return _scoreResult(tek) >= _scoreResult(cryo) ? tek : cryo;
      }
    } finally {
      textRecognizer.close();
    }
  }

  OcrSourceType _detectSourceType(List<String> lines, String fullText) {
    final lower = fullText.toLowerCase();
    if (RegExp(r'\(\d+\s*\|\s*\d+\s*\|\s*\d+\)').hasMatch(fullText)) {
      return OcrSourceType.tekBinoculars;
    }
    if ((lower.contains('tamed') || lower.contains('wild')) &&
        !lower.contains('cryopod')) {
      return OcrSourceType.tekBinoculars;
    }
    if (lower.contains('cryopod') || lower.contains('deploy')) {
      return OcrSourceType.cryopodTooltip;
    }
    return OcrSourceType.unknown;
  }

  int _scoreResult(DinoOcrResult r) {
    int score = 0;
    if (r.species != null) score += 10;
    if (r.level != null) score += 5;
    if (r.hp != null) score += 3;
    if (r.stamina != null) score += 3;
    if (r.melee != null) score += 3;
    if (r.colorIds.any((c) => c > 0)) score += 5;
    if (r.hp?.wildPoints != null) score += 5;
    if (r.mutationsMale != null) score += 3;
    return score;
  }

  // ═══════════════════════════════════════════════════════
  // MATCHING D'ESPÈCES
  // ═══════════════════════════════════════════════════════

  String _normalizeSpecies(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z\s\-\(\)]'), '').trim();
    final lower = cleaned.toLowerCase();

    for (final sp in _allSpeciesSorted) {
      if (sp.toLowerCase() == lower) return sp;
    }
    for (final sp in _allSpeciesSorted) {
      if (lower.contains(sp.toLowerCase())) return sp;
    }
    for (final sp in _allSpeciesSorted) {
      if (sp.toLowerCase().contains(lower) && lower.length >= 4) return sp;
    }

    String? bestMatch;
    double bestScore = 0;
    for (final sp in _allSpeciesSorted) {
      final score = _similarity(lower, sp.toLowerCase());
      if (score > bestScore && score >= 0.6) {
        bestScore = score;
        bestMatch = sp;
      }
    }
    if (bestMatch != null) return bestMatch;

    final words = lower.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      for (final sp in _allSpeciesSorted) {
        final spWords = sp.toLowerCase().split(RegExp(r'\s+'));
        if (spWords.length >= 2) {
          int matched = 0;
          for (final w in words) {
            for (final sw in spWords) {
              if (_similarity(w, sw) >= 0.7) {
                matched++;
                break;
              }
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

    return cleaned
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
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
    final maxLen = max(a.length, b.length);
    final dist = _levenshtein(a, b);
    return 1.0 - (dist / maxLen);
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }
    return matrix[a.length][b.length];
  }

  // ═══════════════════════════════════════════════════════
  // PARSER JUMELLES TEK
  // ═══════════════════════════════════════════════════════

  DinoOcrResult _parseTekBinoculars(List<String> lines, String rawText) {
    String? species;
    int? level;
    String? sex;
    String? status;
    OcrStat? hp, stamina, oxygen, food, weight, melee, speed, torpor;
    int? mutMale, mutFemale;
    List<int> colorIds = [0, 0, 0, 0, 0, 0];
    String? imprinter;
    double? imprintPercent;

    final fullText = lines.join(' ');

    // ── 1. Sexe ──
    if (fullText.contains('♀') || rawText.contains('♀')) {
      sex = '♀';
    } else if (fullText.contains('♂') || rawText.contains('♂')) {
      sex = '♂';
    }

    // ── 2. Espèce + Niveau ──
    final titleRegex = RegExp(
      r'([A-Za-z][A-Za-z\s\(\)]+?)\s*[-–]\s*(?:Lvl|LVL|Level|lvl)\s*(\d+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = titleRegex.firstMatch(line);
      if (m != null) {
        species = _normalizeSpecies(m.group(1)!.trim());
        level = int.tryParse(m.group(2)!);
        break;
      }
    }

    if (species == null) {
      final lvlMatch =
          RegExp(r'(?:Lvl|LVL|Level)\s*(\d+)', caseSensitive: false)
              .firstMatch(fullText);
      if (lvlMatch != null) level = int.tryParse(lvlMatch.group(1)!);
      species = _findSpeciesInText(fullText);
    }

    // ── 3. Statut ──
    final statusParts = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('tamed') && !statusParts.contains('Tamed')) {
        statusParts.add('Tamed');
      }
      if (lower.contains('wild') && !statusParts.contains('Wild')) {
        statusParts.add('Wild');
      }
      if (lower.contains('badass') && !statusParts.contains('Badass')) {
        statusParts.add('Badass');
      }
    }
    if (statusParts.isNotEmpty) status = statusParts.join(' ');

    // ── 4. Stats ──
    final statFullRegex = RegExp(
      r'([\d,]+(?:\.\d+)?)\s*/\s*([\d,]+(?:\.\d+)?)\s*\((\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\)',
    );
    final pctFullRegex = RegExp(
      r'([\d,]+(?:\.\d+)?)\s*%\s*\((\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\)',
    );
    final statSimpleRegex = RegExp(
      r'([\d,]+(?:\.\d+)?)\s*/\s*([\d,]+(?:\.\d+)?)',
    );
    final pctSimpleRegex = RegExp(
      r'^[^\d/]*([\d,]+(?:\.\d+)?)\s*%\s*$',
    );

    final parsedStats = <_RawStatLine>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('mutation') ||
          lower.contains('lvl') ||
          lower.contains('level') ||
          lower.contains('tamed') ||
          lower.contains('wild') ||
          lower.contains('badass') ||
          lower.contains('cryopod') ||
          lower.contains('deploy')) {
        continue;
      }

      if (_isImprintLine(line)) {
        final impMatch = RegExp(r'([\d.]+)\s*%').firstMatch(line);
        if (impMatch != null) {
          imprintPercent = double.tryParse(impMatch.group(1)!);
        }
        final nameMatch = RegExp(r'%\s*[-–]\s*(\S+)').firstMatch(line);
        if (nameMatch != null) {
          imprinter = nameMatch.group(1);
        }
        continue;
      }

      final mFull = statFullRegex.firstMatch(line);
      if (mFull != null) {
        parsedStats.add(_RawStatLine(
          current: _parseNumber(mFull.group(1)!),
          max: _parseNumber(mFull.group(2)!),
          wild: int.tryParse(mFull.group(3)!) ?? 0,
          tame: int.tryParse(mFull.group(4)!) ?? 0,
          mut: int.tryParse(mFull.group(5)!) ?? 0,
          isPercent: false,
          rawLine: line,
        ));
        continue;
      }

      final mPct = pctFullRegex.firstMatch(line);
      if (mPct != null) {
        parsedStats.add(_RawStatLine(
          current: _parseNumber(mPct.group(1)!),
          max: _parseNumber(mPct.group(1)!),
          wild: int.tryParse(mPct.group(2)!) ?? 0,
          tame: int.tryParse(mPct.group(3)!) ?? 0,
          mut: int.tryParse(mPct.group(4)!) ?? 0,
          isPercent: true,
          rawLine: line,
        ));
        continue;
      }

      final mSimple = statSimpleRegex.firstMatch(line);
      if (mSimple != null) {
        parsedStats.add(_RawStatLine(
          current: _parseNumber(mSimple.group(1)!),
          max: _parseNumber(mSimple.group(2)!),
          isPercent: false,
          rawLine: line,
        ));
        continue;
      }

      final mPctS = pctSimpleRegex.firstMatch(line);
      if (mPctS != null) {
        final val = _parseNumber(mPctS.group(1)!);
        if (val != null) {
          parsedStats.add(_RawStatLine(
            current: val,
            max: val,
            isPercent: true,
            rawLine: line,
          ));
        }
      }
    }

    // Assigner: Non-%: HP → Stamina → Food → Weight → Oxygen → Torpor
    //           %: Melee → Speed
    final nonPctStats = parsedStats.where((s) => !s.isPercent).toList();
    final pctStats = parsedStats.where((s) => s.isPercent).toList();

    if (nonPctStats.isNotEmpty) hp = _toOcrStat(nonPctStats[0]);
    if (nonPctStats.length > 1) stamina = _toOcrStat(nonPctStats[1]);
    if (nonPctStats.length > 2) food = _toOcrStat(nonPctStats[2]);
    if (nonPctStats.length > 3) weight = _toOcrStat(nonPctStats[3]);
    if (nonPctStats.length > 4) oxygen = _toOcrStat(nonPctStats[4]);
    if (nonPctStats.length > 5) torpor = _toOcrStat(nonPctStats[5]);

    if (pctStats.isNotEmpty) melee = _toOcrStat(pctStats[0]);
    if (pctStats.length > 1) speed = _toOcrStat(pctStats[1]);

    // ── 5. Couleurs ──
    colorIds = _extractColorIds(lines, fullText);

    // ── 6. Mutations ──
    _parseMutations(lines, fullText, (m, f) {
      mutMale = m;
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
      torpor: torpor,
      mutationsMale: mutMale,
      mutationsFemale: mutFemale,
      colorIds: colorIds,
      imprinter: imprinter,
      imprintPercent: imprintPercent,
      rawText: rawText,
      sourceType: OcrSourceType.tekBinoculars,
    );
  }

  bool _isImprintLine(String line) {
    final lower = line.toLowerCase();
    if (RegExp(r'[\d.]+\s*%\s*[-–]\s*\w').hasMatch(line)) return true;
    if (lower.contains('imprint')) return true;
    if (RegExp(r'^\s*[↓⬇🔽]?\s*[\d.]+\s*%\s*[-–]?\s*\w*\s*$')
        .hasMatch(line)) {
      final pct = double.tryParse(
          RegExp(r'([\d.]+)\s*%').firstMatch(line)?.group(1) ?? '');
      if (pct != null && pct <= 100) return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════
  // PARSER CRYOPOD
  // ═══════════════════════════════════════════════════════

  DinoOcrResult _parseCryopodTooltip(List<String> lines, String rawText) {
    String? species;
    int? level;
    String? sex;
    List<int> colorIds = [0, 0, 0, 0, 0, 0];
    int? mutMale, mutFemale;
    String? imprinter;
    double? imprintPercent;

    final fullText = lines.join(' ');

    // ── 1. Sexe ──
    if (fullText.contains('♀') || rawText.contains('♀')) {
      sex = '♀';
    } else if (fullText.contains('♂') || rawText.contains('♂')) {
      sex = '♂';
    }

    // ── 2. Titre ──
    final titleRegex = RegExp(
      r'(?:BABY\s+)?(.+?)\s*[-–]\s*(?:LVL|LEVEL|Lvl|lvl)\s*(\d+)',
      caseSensitive: false,
    );
    final titleMatch = titleRegex.firstMatch(fullText);
    if (titleMatch != null) {
      species = _normalizeSpecies(titleMatch.group(1)!.trim());
      level = int.tryParse(titleMatch.group(2)!);
    }

    if (species == null) {
      final lvlMatch =
          RegExp(r'(?:Lvl|LVL|Level)\s*(\d+)', caseSensitive: false)
              .firstMatch(fullText);
      if (lvlMatch != null) level = int.tryParse(lvlMatch.group(1)!);
      species = _findSpeciesInText(fullText);
    }

    // ── 3. Stats ──
    final dualRegex = RegExp(r'([\d,.]+)\s*/\s*([\d,.]+)');
    final dualMatches = <RegExpMatch>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('cryopod') ||
          lower.contains('charge') ||
          lower.contains('mutation') ||
          lower.contains('deploy')) {
        continue;
      }
      final m = dualRegex.firstMatch(line);
      if (m != null) dualMatches.add(m);
    }

    OcrStat? hp, stamina, oxygen, food, weight;
    OcrStat? melee, speed;

    final maxValues = dualMatches
        .map((m) => _parseNumber(m.group(2)!))
        .whereType<double>()
        .toList();

    final assigned = List<bool>.filled(maxValues.length, false);

    for (int i = 0; i < maxValues.length; i++) {
      if (!assigned[i] && maxValues[i] >= 100 && hp == null) {
        hp = OcrStat(maxValue: maxValues[i]);
        assigned[i] = true;
        break;
      }
    }
    for (int i = 0; i < maxValues.length; i++) {
      if (!assigned[i] && maxValues[i] > 3000 && food == null) {
        food = OcrStat(maxValue: maxValues[i]);
        assigned[i] = true;
        break;
      }
    }
    for (int i = 0; i < maxValues.length; i++) {
      if (!assigned[i] && maxValues[i] > 500 && weight == null) {
        weight = OcrStat(maxValue: maxValues[i]);
        assigned[i] = true;
        break;
      }
    }
    for (int i = 0; i < maxValues.length; i++) {
      if (!assigned[i]) {
        if (stamina == null) {
          stamina = OcrStat(maxValue: maxValues[i]);
          assigned[i] = true;
        } else if (oxygen == null) {
          oxygen = OcrStat(maxValue: maxValues[i]);
          assigned[i] = true;
        }
      }
    }

    // Melee% et Speed%
    final pctRegex = RegExp(r'([\d,.]+)\s*%');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('imprint') || lower.contains('mutation')) continue;
      if (dualRegex.hasMatch(line)) continue;

      if (_isImprintLine(line)) {
        final impMatch = pctRegex.firstMatch(line);
        if (impMatch != null) {
          imprintPercent =
              double.tryParse(impMatch.group(1)!.replaceAll(',', ''));
        }
        final nameMatch = RegExp(r'%\s*[-–]\s*(\S+)').firstMatch(line);
        if (nameMatch != null) imprinter = nameMatch.group(1);
        continue;
      }

      final m = pctRegex.firstMatch(line);
      if (m != null) {
        final val = _parseNumber(m.group(1)!);
        if (val != null) {
          if (val > 100 && melee == null) {
            melee = OcrStat(maxValue: val, isPercent: true);
          } else {
            speed ??= OcrStat(maxValue: val, isPercent: true);
          }
        }
      }
    }

    // ── 4. Couleurs ──
    colorIds = _extractColorIds(lines, fullText);

    // ── 5. Mutations ──
    _parseMutations(lines, fullText, (m, f) {
      mutMale = m;
      mutFemale = f;
    });

    // ── 6. Imprint fallback ──
    if (imprintPercent == null) {
      for (final line in lines) {
        final impRegex = RegExp(r'([\d.]+)\s*%\s*[-–]\s*(\w+)');
        final im = impRegex.firstMatch(line);
        if (im != null) {
          final pct = double.tryParse(im.group(1)!);
          if (pct != null && pct <= 100) {
            imprintPercent = pct;
            imprinter = im.group(2);
          }
        }
      }
    }

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

  // ═══════════════════════════════════════════════════════
  // EXTRACTION DES COULEURS
  // ═══════════════════════════════════════════════════════

  List<int> _extractColorIds(List<String> lines, String fullText) {
    final colorIds = [0, 0, 0, 0, 0, 0];

    final colorCandidates = <List<int>>[];

    // ignore: unused_local_variable
    bool pastStats = false;

    for (final line in lines) {
      final lower = line.toLowerCase();

      if (line.contains('%') && !line.contains('|') && !line.contains('/')) {
        pastStats = true;
        if (_isImprintLine(line)) continue;
        continue;
      }
      if (line.contains('/') && RegExp(r'\d').hasMatch(line)) {
        pastStats = true;
        continue;
      }

      if (lower.contains('mutation')) break;

      if (line.contains('|') ||
          lower.contains('lvl') ||
          lower.contains('level') ||
          lower.contains('tamed') ||
          lower.contains('wild') ||
          lower.contains('badass') ||
          lower.contains('cryopod') ||
          lower.contains('deploy') ||
          lower.contains('charge') ||
          lower.contains('weight')) {
        continue;
      }

      final nums = RegExp(r'\b(\d{1,3})\b')
          .allMatches(line)
          .map((m) => int.parse(m.group(1)!))
          .where((n) => n >= 0 && n <= 100)
          .toList();

      if (nums.length >= 2 && nums.length <= 6) {
        colorCandidates.add(nums);
      }
    }

    if (colorCandidates.isNotEmpty) {
      final best = colorCandidates.firstWhere(
        (c) => c.length >= 5,
        orElse: () => colorCandidates.firstWhere(
          (c) => c.length >= 3,
          orElse: () => colorCandidates.first,
        ),
      );
      for (int i = 0; i < best.length && i < 6; i++) {
        colorIds[i] = best[i];
      }
      if (colorIds.any((c) => c > 0)) return colorIds;
    }

    for (final line in lines) {
      if (line.contains('/') || line.contains('|') || line.contains('%')) {
        continue;
      }
      final lower = line.toLowerCase();
      if (lower.contains('mutation') ||
          lower.contains('lvl') ||
          lower.contains('cryopod') ||
          lower.contains('deploy') ||
          lower.contains('charge')) {
        continue;
      }

      final nums = RegExp(r'\b(\d{1,3})\b')
          .allMatches(line)
          .map((m) => int.parse(m.group(1)!))
          .where((n) => n >= 1 && n <= 100)
          .toList();

      if (nums.length >= 3 && nums.length <= 6) {
        for (int i = 0; i < nums.length && i < 6; i++) {
          colorIds[i] = nums[i];
        }
        return colorIds;
      }
    }

    final allColorNums = <int>[];
    bool inColorZone = false;

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('mutation')) break;

      if (line.contains('%') && !line.contains('|')) {
        inColorZone = true;
        continue;
      }

      if (inColorZone) {
        final nums = RegExp(r'\b(\d{1,2})\b')
            .allMatches(line)
            .map((m) => int.parse(m.group(1)!))
            .where((n) => n >= 0 && n <= 100)
            .toList();
        allColorNums.addAll(nums);
      }
    }

    if (allColorNums.length >= 3) {
      for (int i = 0; i < allColorNums.length && i < 6; i++) {
        colorIds[i] = allColorNums[i];
      }
    }

    return colorIds;
  }

  // ═══════════════════════════════════════════════════════
  // UTILITAIRES PARTAGÉS
  // ═══════════════════════════════════════════════════════

  void _parseMutations(
    List<String> lines,
    String fullText,
    void Function(int? male, int? female) callback,
  ) {
    int? mutMale;
    int? mutFemale;

    for (final line in lines) {
      if (!line.toLowerCase().contains('mutation') &&
          !line.contains('♂') &&
          !line.contains('♀')) {
        continue;
      }

      final mutFull = RegExp(r'♂\s*(\d+)\s*♀\s*(\d+)').firstMatch(line);
      if (mutFull != null) {
        mutMale = int.tryParse(mutFull.group(1)!);
        mutFemale = int.tryParse(mutFull.group(2)!);
        callback(mutMale, mutFemale);
        return;
      }

      final mutInv = RegExp(r'♀\s*(\d+)\s*♂\s*(\d+)').firstMatch(line);
      if (mutInv != null) {
        mutFemale = int.tryParse(mutInv.group(1)!);
        mutMale = int.tryParse(mutInv.group(2)!);
        callback(mutMale, mutFemale);
        return;
      }

      final mutF = RegExp(r'♀\s*(\d+)\s*[Mm]utation').firstMatch(line);
      if (mutF != null) mutFemale = int.tryParse(mutF.group(1)!);

      final mutM = RegExp(r'♂\s*(\d+)\s*[Mm]utation').firstMatch(line);
      if (mutM != null) mutMale = int.tryParse(mutM.group(1)!);

      if (mutMale == null && mutFemale == null) {
        final mutText = RegExp(r'(\d+)\s*[Mm]utation').firstMatch(line);
        if (mutText != null) mutFemale = int.tryParse(mutText.group(1)!);
      }
    }

    if (mutMale == null || mutFemale == null) {
      for (final line in lines) {
        if (mutMale == null) {
          final m = RegExp(r'♂\s*(\d+)').firstMatch(line);
          if (m != null) mutMale = int.tryParse(m.group(1)!);
        }
        if (mutFemale == null) {
          final m = RegExp(r'♀\s*(\d+)').firstMatch(line);
          if (m != null) mutFemale = int.tryParse(m.group(1)!);
        }
      }
    }

    callback(mutMale, mutFemale);
  }

  OcrStat _toOcrStat(_RawStatLine raw) {
    return OcrStat(
      currentValue: raw.current,
      maxValue: raw.max,
      wildPoints: raw.wild,
      tamePoints: raw.tame,
      mutPoints: raw.mut,
      isPercent: raw.isPercent,
    );
  }

  double? _parseNumber(String text) {
    final cleaned = text.replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }
}

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
}
