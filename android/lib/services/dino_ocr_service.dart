// lib/services/dino_ocr_service.dart
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ark_color_palette.dart';
import '../models/ark_species_data.dart';
import '../models/dino.dart';

const Set<String> _agePrefixes = {
  'baby', 'juvenile', 'adolescent', 'young', 'adult', 'elder',
  'juvie', 'juvy',
  'bébé', 'bebe', 'juvénile',
  'jungtier', 'jugendlich',
  'bebé', 'juvenil', 'joven', 'adulto',
  'malysh', 'molodoy',
};

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
      case tekBinoculars:  return 'Jumelles Tek';
      case cryopodTooltip: return 'Cryopod';
      case unknown:        return 'Scan';
    }
  }
}

class DinoOcrResult {
  final String? species;
  final int?    level;
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

  final int?    mutationsMale;
  final int?    mutationsFemale;
  final List<int> colorIds;
  final String? imprinter;
  final double? imprintPercent;
  final String  rawText;
  final OcrSourceType sourceType;

  const DinoOcrResult({
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

  double _removeImprintIfNeeded(double v, OcrStat? stat) {
    final imp = imprintPercent ?? 0;
    if (imp <= 0) return v;
    final hasPoints = (stat?.totalPoints ?? 0) > 0;
    if (!hasPoints) return v;
    return v / (1.0 + 0.2 * imp / 100.0);
  }

  Dino toDino({bool removeImprint = true}) {
    final ids = List<int>.from(colorIds);
    while (ids.length < 6) ids.add(0);

    final hexes = ids.map((id) {
      if (id <= 0) return '#808080';
      final entry = ArkColorPalette.allColors
          .cast<Map<String, dynamic>?>()
          .firstWhere((c) => c?['id'] == id, orElse: () => null);
      return (entry?['hex'] as String?) ?? '#808080';
    }).toList();

    String dinoSex = 'Inconnu';
    if (sex != null) {
      if (sex!.contains('♀') || sex!.toLowerCase().contains('female') ||
          sex!.toLowerCase().contains('femelle')) {
        dinoSex = 'Femelle';
      } else if (sex!.contains('♂') || sex!.toLowerCase().contains('male') ||
          sex!.toLowerCase().contains('mâle')) {
        dinoSex = 'Mâle';
      }
    }

    double hpV     = hp?.maxValue     ?? 0;
    double stamV   = stamina?.maxValue ?? 0;
    double weightV = weight?.maxValue  ?? 0;
    double meleeV  = melee?.maxValue   ?? 0;

    if (removeImprint) {
      hpV     = _removeImprintIfNeeded(hpV,     hp);
      stamV   = _removeImprintIfNeeded(stamV,   stamina);
      weightV = _removeImprintIfNeeded(weightV, weight);
      meleeV  = _removeImprintIfNeeded(meleeV,  melee);
    }

    final ptsBlock   = _buildPointsBlock();
    final notesText  = _buildNotes();
    final finalNotes = ptsBlock.isNotEmpty ? '$notesText\n$ptsBlock' : notesText;

    int pts(OcrStat? s) => s?.totalPoints ?? 0;

    return Dino(
      nom:              name ?? '',
      espece:           species ?? 'Rex',
      sexe:             dinoSex,
      role:             'Breed',
      niveau:           level ?? 0,
      hp:               hpV.round(),
      stamina:          stamV.round(),
      oxygene:          (oxygen?.maxValue ?? 0).round(),
      nourriture:       (food?.maxValue ?? 0).round(),
      poids:            weightV.round(),
      degats:           meleeV,
      vitesse:          speed?.maxValue ?? 100.0,
      hpPoints:         pts(hp),
      staminaPoints:    pts(stamina),
      oxygenePoints:    pts(oxygen),
      nourriturePoints: pts(food),
      poidsPoints:      pts(weight),
      degatsPoints:     pts(melee),
      vitessePoints:    0,
      couleur0: Dino.encodeColor(ids[0], hexes[0]),
      couleur1: Dino.encodeColor(ids[1], hexes[1]),
      couleur2: Dino.encodeColor(ids[2], hexes[2]),
      couleur3: Dino.encodeColor(ids[3], hexes[3]),
      couleur4: Dino.encodeColor(ids[4], hexes[4]),
      couleur5: Dino.encodeColor(ids[5], hexes[5]),
      tagVersion: '',
      tags:       _buildAutoTags(),
      notes:      finalNotes,
      dateAjout:  DateTime.now(),
    );
  }

  String _buildPointsBlock() {
    final entries = <String>[];
    void add(String k, OcrStat? s) {
      if (s == null) return;
      final b = s.wildPoints ?? 0;
      final m = s.mutPoints  ?? 0;
      final p = s.tamePoints ?? 0;
      if (b > 0 || m > 0 || p > 0) entries.add('$k=$b/$m/$p');
    }
    add('hp', hp); add('stamina', stamina); add('oxygene', oxygen);
    add('nourriture', food); add('poids', weight); add('degats', melee);
    return entries.isEmpty ? '' : '[PTS:${entries.join(',')}]';
  }

  List<String> _buildAutoTags() {
    final tags = <String>[];
    if (status != null) {
      if (status!.toLowerCase().contains('badass')) tags.add('Badass');
      if (status!.toLowerCase().contains('tamed'))  tags.add('Tamed');
    }
    if ((mutationsMale   ?? 0) > 0 ||
        (mutationsFemale ?? 0) > 0) tags.add('Mutant');
    return tags;
  }

  String _buildNotes() {
    final parts = <String>[];
    parts.add('Import OCR (${sourceType.label})');
    if ((imprintPercent ?? 0) > 0) {
      parts.add('Imprint: ${imprintPercent!.toStringAsFixed(1)}%'
          '${imprinter != null ? ' - $imprinter' : ''}');
      parts.add('⚠️ Stats HP/Stam/Poids/Mêlée corrigées à 0% imprint (si points > 0)');
    }
    if (mutationsMale != null || mutationsFemale != null) {
      parts.add('Mutations: ♂${mutationsMale ?? '?'} ♀${mutationsFemale ?? '?'}');
    }
    return parts.join('\n');
  }

  ({int base, int muta, int perso}) pointsBreakdownFor(OcrStat? s) {
    if (s == null) return (base: 0, muta: 0, perso: 0);
    return (base: s.wildPoints ?? 0, muta: s.mutPoints ?? 0, perso: s.tamePoints ?? 0);
  }
}

class DinoOcrService {
  static final DinoOcrService _instance = DinoOcrService._();
  factory DinoOcrService() => _instance;
  DinoOcrService._();

  static final List<String> _speciesSorted = () {
    final list = List<String>.from(ArkSpeciesData.speciesWithImages);
    list.sort((a, b) => b.length.compareTo(a.length));
    return list;
  }();

  Future<DinoOcrResult> scanImage(File imageFile) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFile(imageFile),
      );
      final rawText = recognized.text;
      final lines   = rawText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final source = _detectSource(lines, rawText);
      switch (source) {
        case OcrSourceType.tekBinoculars:
          return _parseTek(lines, rawText);
        case OcrSourceType.cryopodTooltip:
          return _parseCryo(lines, rawText);
        default:
          final tek  = _parseTek(lines, rawText);
          final cryo = _parseCryo(lines, rawText);
          return _score(tek) >= _score(cryo) ? tek : cryo;
      }
    } finally {
      recognizer.close();
    }
  }

  OcrSourceType _detectSource(List<String> lines, String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'\(\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\)').hasMatch(text)) {
      return OcrSourceType.tekBinoculars;
    }
    if (lower.contains('cryopod') ||
        lower.contains('deploy')  ||
        lower.contains('charge')) {
      return OcrSourceType.cryopodTooltip;
    }
    if (lower.contains('tamed') || lower.contains('wild')) {
      return OcrSourceType.tekBinoculars;
    }
    return OcrSourceType.unknown;
  }

  int _score(DinoOcrResult r) {
    int s = 0;
    if (r.species != null)            s += 10;
    if (r.level   != null)            s += 5;
    if (r.hp      != null)            s += 3;
    if (r.melee   != null)            s += 3;
    if (r.colorIds.any((c) => c > 0)) s += 5;
    if (r.hp?.wildPoints != null)     s += 5;
    return s;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSER JUMELLES TEK
  // ═══════════════════════════════════════════════════════════════════════════
  DinoOcrResult _parseTek(List<String> lines, String rawText) {
    String? species, sex, status, imprinter, name;
    int?    level;
    double? imprintPercent;
    OcrStat? hp, stamina, oxygen, food, weight, melee, speed, torpor;
    int?    mutMale, mutFemale;
    List<int> colorIds = [0, 0, 0, 0, 0, 0];

    sex = _extractSex(rawText);

    final titleRe = RegExp(
      r'^(.+?)\s*[-–]\s*(?:Niv\.?|Lvl\.?|Level|LVL)\s*(\d+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = titleRe.firstMatch(line);
      if (m != null) {
        name    = m.group(1)!.trim();
        level   = int.tryParse(m.group(2)!);
        species = _matchSpecies(name);
        break;
      }
    }
    if (level == null) {
      final lvlRe = RegExp(r'(?:Niv\.?|Lvl\.?|Level|LVL)\s*(\d+)',
          caseSensitive: false);
      for (final line in lines) {
        final m = lvlRe.firstMatch(line);
        if (m != null) { level = int.tryParse(m.group(1)!); break; }
      }
    }

    status = _extractStatus(lines);

    final statFullRe = RegExp(
      r'([\d\s,.]+)\s*/\s*([\d\s,.]+)\s*(?:fr\s*)?\(\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\)',
    );
    final pctFullRe = RegExp(
      r'([\d,.]+)\s*%\s*(?:fr\s*)?\(\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\)',
    );
    final statSimpleRe = RegExp(
      r'([\d\s,.]+)\s*/\s*([\d\s,.]+)',
    );

    final nonPct   = <_RawStat>[];
    final pctStats = <_RawStat>[];

    // Extraire l'imprint EN PREMIER pour ne pas le confondre avec une stat
    for (final line in lines) {
      if (_skipLine(line)) continue;
      if (_isImprintLineTek(line)) {
        final m = RegExp(r'([\d.]+)\s*%').firstMatch(line);
        if (m != null) {
          final v = double.tryParse(m.group(1)!);
          if (v != null && v >= 0 && v <= 100) {
            imprintPercent = v;
          }
        }
        final nm = RegExp(r'%\s*[-–]\s*(\S+)').firstMatch(line);
        if (nm != null) imprinter = nm.group(1);
      }
    }

    for (final line in lines) {
      if (_skipLine(line)) continue;
      if (_isImprintLineTek(line)) continue;

      final mFull = statFullRe.firstMatch(line);
      if (mFull != null) {
        nonPct.add(_RawStat(
          cur: _num(mFull.group(1)!),
          max: _num(mFull.group(2)!),
          w:  int.tryParse(mFull.group(3)!) ?? 0,
          t:  int.tryParse(mFull.group(4)!) ?? 0,
          mu: int.tryParse(mFull.group(5)!) ?? 0,
        ));
        continue;
      }

      final mPct = pctFullRe.firstMatch(line);
      if (mPct != null) {
        pctStats.add(_RawStat(
          cur: _num(mPct.group(1)!),
          max: _num(mPct.group(1)!),
          w:  int.tryParse(mPct.group(2)!) ?? 0,
          t:  int.tryParse(mPct.group(3)!) ?? 0,
          mu: int.tryParse(mPct.group(4)!) ?? 0,
          isPercent: true,
        ));
        continue;
      }

      final mSimple = statSimpleRe.firstMatch(line);
      if (mSimple != null) {
        final maxV = _num(mSimple.group(2)!);
        if (maxV != null && maxV > 0) {
          nonPct.add(_RawStat(cur: _num(mSimple.group(1)!), max: maxV));
        }
      }
    }

    // Ordre ARK Tek binoculars :
    // non-% → [0]HP [1]Stamina [2]Torpor [3]Poids [4]Food [5]Oxygen
    // %     → [0]Melee [1]Vitesse
    if (nonPct.length > 0) hp      = _toStat(nonPct[0]);
    if (nonPct.length > 1) stamina = _toStat(nonPct[1]);
    if (nonPct.length > 2) torpor  = _toStat(nonPct[2]);
    if (nonPct.length > 3) weight  = _toStat(nonPct[3]);
    if (nonPct.length > 4) food    = _toStat(nonPct[4]);
    if (nonPct.length > 5) oxygen  = _toStat(nonPct[5]);

    if (pctStats.length > 0) melee = _toStat(pctStats[0]);
    if (pctStats.length > 1) speed = _toStat(pctStats[1]);

    colorIds = _extractColors(lines);

    final muts = _extractMutations(lines);
    mutMale   = muts.$1;
    mutFemale = muts.$2;

    return DinoOcrResult(
      species: species, level: level, name: name, sex: sex, status: status,
      hp: hp, stamina: stamina, oxygen: oxygen, food: food,
      weight: weight, melee: melee, speed: speed, torpor: torpor,
      mutationsMale: mutMale, mutationsFemale: mutFemale,
      colorIds: colorIds,
      imprinter: imprinter, imprintPercent: imprintPercent,
      rawText: rawText, sourceType: OcrSourceType.tekBinoculars,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSER CRYOPOD
  // ═══════════════════════════════════════════════════════════════════════════
  DinoOcrResult _parseCryo(List<String> lines, String rawText) {
    String? species, sex, name, imprinter;
    int?    level;
    double? imprintPercent;
    List<int> colorIds = [0, 0, 0, 0, 0, 0];
    int?    mutMale, mutFemale;

    sex = _extractSex(rawText);

    final cryoTitleRe = RegExp(
      r'^(.*?)\s+(?:LVL|Lvl|Level|lvl)\s+(\d+)\s*\(([^)]+)\)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final m = cryoTitleRe.firstMatch(line);
      if (m != null) {
        final rawName  = m.group(1)!.trim();
        final rawLevel = m.group(2)!;
        final rawSpec  = m.group(3)!.trim();

        level   = int.tryParse(rawLevel);
        species = _matchSpecies(rawSpec);
        name    = _stripAgePrefixes(rawName);
        break;
      }
    }

    if (species == null) {
      final parenRe = RegExp(r'\(([A-Za-z][A-Za-z\s]+)\)');
      for (final line in lines) {
        final m = parenRe.firstMatch(line);
        if (m != null) {
          final candidate = _matchSpecies(m.group(1)!.trim());
          if (candidate != null) { species = candidate; break; }
        }
      }
      if (level == null) {
        final lvlRe = RegExp(r'(?:LVL|Lvl|Level)\s*(\d+)', caseSensitive: false);
        for (final line in lines) {
          final m = lvlRe.firstMatch(line);
          if (m != null) { level = int.tryParse(m.group(1)!); break; }
        }
      }
      species ??= _findSpeciesInText(rawText);
    }

    // Chercher l'imprint AVANT de parser les stats
    final Set<int> imprintLineIndexes = {};
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isImprintLineCryo(line)) {
        final m = RegExp(r'([\d.]+)\s*%').firstMatch(line);
        if (m != null) {
          final v = double.tryParse(m.group(1)!);
          if (v != null && v >= 0 && v <= 100) {
            imprintPercent = v;
            final nm = RegExp(r'%\s*[-–]\s*(\S+)').firstMatch(line);
            if (nm != null) imprinter = nm.group(1);
            imprintLineIndexes.add(i);
          }
        }
      }
    }

    final statRe = RegExp(r'([\d,.]+)\s*/\s*([\d,.]+)');
    final pctRe  = RegExp(r'^([\d,.]+)\s*%\s*$');

    final nonPctVals = <double>[];
    final pctVals    = <double>[];

    for (int i = 0; i < lines.length; i++) {
      if (imprintLineIndexes.contains(i)) continue;

      final line  = lines[i];
      final lower = line.toLowerCase();

      if (lower.contains('cryopod')  ||
          lower.contains('charge')   ||
          lower.contains('deploy')   ||
          lower.contains('mutation') ||
          lower.contains('weight:')  ||
          lower.contains('poids:'))  continue;

      final mStat = statRe.firstMatch(line);
      if (mStat != null) {
        final maxV = _num(mStat.group(2)!);
        if (maxV != null && maxV > 0) nonPctVals.add(maxV);
        continue;
      }

      final mPct = pctRe.firstMatch(line.trim());
      if (mPct != null) {
        final v = _num(mPct.group(1)!);
        if (v != null && v > 0 && v <= 200) pctVals.add(v);
      }
    }

    // Ordre ARK cryopod :
    // non-% → [0]HP [1]Stamina [2]Water/Torpor(ignoré) [3]Poids [4]Food [5]Oxygen
    // %     → [0]Melee [1]Vitesse
    OcrStat? hp, stamina, oxygen, food, weight, melee, speed;

    if (nonPctVals.length > 0) hp      = OcrStat(maxValue: nonPctVals[0]);
    if (nonPctVals.length > 1) stamina = OcrStat(maxValue: nonPctVals[1]);
    // [2] = Water/Torpor → ignoré
    if (nonPctVals.length > 3) weight  = OcrStat(maxValue: nonPctVals[3]);
    if (nonPctVals.length > 4) food    = OcrStat(maxValue: nonPctVals[4]);
    if (nonPctVals.length > 5) oxygen  = OcrStat(maxValue: nonPctVals[5]);

    if (pctVals.length > 0) melee = OcrStat(maxValue: pctVals[0], isPercent: true);
    if (pctVals.length > 1) speed = OcrStat(maxValue: pctVals[1], isPercent: true);

    colorIds = _extractColors(lines);

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('mutation')) continue;

      final matRe = RegExp(r'(\d+)\s*[Mm]utation[s]?\s*\(.*?[Mm]at', caseSensitive: false);
      final patRe = RegExp(r'(\d+)\s*[Mm]utation[s]?\s*\(.*?[Pp]at', caseSensitive: false);
      final mMat  = matRe.firstMatch(line);
      final mPat  = patRe.firstMatch(line);

      if (mMat != null) mutFemale = int.tryParse(mMat.group(1)!);
      if (mPat != null) mutMale   = int.tryParse(mPat.group(1)!);
    }
    if (mutMale == null && mutFemale == null) {
      final muts = _extractMutations(lines);
      mutMale   = muts.$1;
      mutFemale = muts.$2;
    }

    return DinoOcrResult(
      species: species, level: level, name: name, sex: sex,
      hp: hp, stamina: stamina, oxygen: oxygen, food: food,
      weight: weight, melee: melee, speed: speed,
      mutationsMale: mutMale, mutationsFemale: mutFemale,
      colorIds: colorIds,
      imprinter: imprinter, imprintPercent: imprintPercent,
      rawText: rawText, sourceType: OcrSourceType.cryopodTooltip,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTRACTION DES COULEURS — CORRIGÉE
  // ═══════════════════════════════════════════════════════════════════════════
  List<int> _extractColors(List<String> lines) {
    final result     = [0, 0, 0, 0, 0, 0];
    final candidates = <List<int>>[];

    for (final line in lines) {
      final lower = line.toLowerCase();

      // ✅ CORRIGÉ : filtres allégés — on retire lvl/niv/level/tamed/wild
      // qui pouvaient exclure par erreur la ligne de couleurs
      if (lower.contains('mutation')  ||
          lower.contains('cryopod')   ||
          lower.contains('deploy')    ||
          lower.contains('charge')    ||
          lower.contains('weight')    ||
          lower.contains('poids')     ||
          lower.contains('imprint')   ||
          lower.contains('tamed')     ||
          lower.contains('wild'))     continue;

      // Ignorer les lignes avec "/" (stats) ou "(X|Y|Z)" (points tek)
      if (line.contains('/')) continue;
      if (RegExp(r'\(\s*\d+\s*\|').hasMatch(line)) continue;

      // Ignorer les lignes avec "%" (melee, vitesse, imprint)
      if (line.contains('%')) continue;

      // Extraire tous les nombres de la ligne
      final allNums = RegExp(r'\b(\d+)\b')
          .allMatches(line)
          .map((m) => int.parse(m.group(1)!))
          .toList();

      // ✅ CORRIGÉ : seuil > 500 au lieu de > 277
      // Les IDs ARK vont jusqu'à 277 mais l'OCR peut lire 278-300
      // à cause d'erreurs mineures de reconnaissance
      final hasVeryLargeNum = allNums.any((n) => n > 500);
      if (hasVeryLargeNum) continue;

      // Garder les IDs dans la plage plausible (tolérance OCR jusqu'à 300)
      final colorNums = allNums.where((n) => n >= 0 && n <= 300).toList();

      if (colorNums.length >= 2 && colorNums.length <= 8) {
        candidates.add(colorNums);
      }
    }

    if (candidates.isEmpty) return result;

    // ✅ CORRIGÉ : priorité à la ligne avec exactement 6 IDs valides ARK
    List<int>? best;

    for (final c in candidates) {
      final validArk = c.where((n) => n >= 1 && n <= 277).toList();
      if (validArk.length == 6) {
        best = validArk;
        break;
      }
    }

    // Sinon trier par nombre d'IDs valides et prendre le meilleur
    if (best == null) {
      candidates.sort((a, b) {
        final aValid = a.where((n) => n >= 1 && n <= 277).length;
        final bValid = b.where((n) => n >= 1 && n <= 277).length;
        return bValid.compareTo(aValid);
      });
      final top = candidates.first.where((n) => n >= 1 && n <= 277).toList();
      if (top.isNotEmpty) best = top;
    }

    if (best == null) return result;

    for (int i = 0; i < best.length && i < 6; i++) {
      result[i] = best[i];
    }

    // ✅ CORRIGÉ : compléter avec les candidats suivants si < 4 couleurs trouvées
    if (result.where((c) => c > 0).length < 4 && candidates.length >= 2) {
      final merged = <int>[];
      for (final c in candidates) {
        for (final n in c) {
          if (n >= 1 && n <= 277 && !merged.contains(n)) merged.add(n);
          if (merged.length >= 6) break;
        }
        if (merged.length >= 6) break;
      }
      for (int i = 0; i < merged.length && i < 6; i++) {
        if (result[i] == 0) result[i] = merged[i];
      }
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PARTAGÉS
  // ═══════════════════════════════════════════════════════════════════════════

  String? _extractSex(String text) {
    if (text.contains('♀')) return '♀';
    if (text.contains('♂')) return '♂';
    final lower = text.toLowerCase();
    if (lower.contains('female') || lower.contains('femelle')) return '♀';
    if (lower.contains(' male') || lower.contains('mâle'))     return '♂';
    return null;
  }

  String? _extractStatus(List<String> lines) {
    final parts = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower == 'tamed' || lower.contains('tamed') && line.length < 20)
        parts.add('Tamed');
      if (lower == 'wild' || lower.contains('wild') && line.length < 20)
        parts.add('Wild');
      if (lower.contains('badass')) parts.add('Badass');
    }
    return parts.isEmpty ? null : parts.toSet().join(' ');
  }

  bool _skipLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('mutation') ||
           lower.contains('lvl')      ||
           lower.contains('niv')      ||
           lower.contains('level')    ||
           lower.contains('cryopod')  ||
           lower.contains('deploy')   ||
           lower.contains('charge');
  }

  bool _isImprintLineTek(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('imprint')) return true;
    if (RegExp(r'[\d.]+\s*%\s*[-–]\s*\w').hasMatch(line)) return true;
    return false;
  }

  bool _isImprintLineCryo(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('imprint')) return true;
    if (RegExp(r'[\d.]+\s*%\s*[-–]\s*\w').hasMatch(line)) return true;
    if (RegExp(r'[\d.]+\s*%\s+[-–]\s*\w').hasMatch(line)) return true;
    return false;
  }

  (int?, int?) _extractMutations(List<String> lines) {
    int? male, female;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('mutation') &&
          !line.contains('♂') && !line.contains('♀')) continue;

      var m = RegExp(r'♂\s*([\d,]+)\s*♀\s*([\d,]+)').firstMatch(line);
      if (m != null) {
        male   = _parseIntClean(m.group(1)!);
        female = _parseIntClean(m.group(2)!);
        return (male, female);
      }
      m = RegExp(r'♀\s*([\d,]+)\s*♂\s*([\d,]+)').firstMatch(line);
      if (m != null) {
        female = _parseIntClean(m.group(1)!);
        male   = _parseIntClean(m.group(2)!);
        return (male, female);
      }
      final mM = RegExp(r'♂\s*([\d,]+)').firstMatch(line);
      final mF = RegExp(r'♀\s*([\d,]+)').firstMatch(line);
      if (mM != null) male   = _parseIntClean(mM.group(1)!);
      if (mF != null) female = _parseIntClean(mF.group(1)!);
    }
    return (male, female);
  }

  String _stripAgePrefixes(String raw) {
    final words = raw.split(RegExp(r'\s+'));
    int start = 0;
    for (int i = 0; i < words.length; i++) {
      if (_agePrefixes.contains(words[i].toLowerCase())) {
        start = i + 1;
      } else {
        break;
      }
    }
    return words.sublist(start).join(' ').trim();
  }

  String? _matchSpecies(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z\s\-]'), '').trim();
    final lower   = cleaned.toLowerCase();
    if (lower.isEmpty) return null;

    for (final sp in _speciesSorted) {
      if (sp.toLowerCase() == lower) return sp;
    }
    for (final sp in _speciesSorted) {
      if (lower.contains(sp.toLowerCase())) return sp;
    }
    for (final sp in _speciesSorted) {
      if (sp.toLowerCase().contains(lower) && lower.length >= 4) return sp;
    }
    String? best;
    double bestScore = 0;
    for (final sp in _speciesSorted) {
      final s = _sim(lower, sp.toLowerCase());
      if (s > bestScore && s >= 0.65) { bestScore = s; best = sp; }
    }
    return best;
  }

  String? _findSpeciesInText(String text) {
    final lower = text.toLowerCase();
    for (final sp in _speciesSorted) {
      if (lower.contains(sp.toLowerCase())) return sp;
    }
    return null;
  }

  double _sim(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final d = _lev(a, b);
    return 1.0 - d / max(a.length, b.length);
  }

  int _lev(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = List.generate(a.length + 1,
        (i) => List.generate(b.length + 1,
            (j) => i == 0 ? j : (j == 0 ? i : 0)));
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        m[i][j] = [m[i-1][j]+1, m[i][j-1]+1, m[i-1][j-1]+cost].reduce(min);
      }
    }
    return m[a.length][b.length];
  }

  OcrStat _toStat(_RawStat r) => OcrStat(
        currentValue: r.cur,
        maxValue:     r.max,
        wildPoints:   r.w,
        tamePoints:   r.t,
        mutPoints:    r.mu,
        isPercent:    r.isPercent,
      );

  double? _num(String s) =>
      double.tryParse(s.replaceAll(RegExp(r'[\s,]'), '').trim());

  int _parseIntClean(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[\s,.]'), '')) ?? 0;
}

class _RawStat {
  final double? cur;
  final double? max;
  final int     w;
  final int     t;
  final int     mu;
  final bool    isPercent;

  _RawStat({this.cur, this.max, this.w = 0, this.t = 0,
            this.mu = 0, this.isPercent = false});
}
