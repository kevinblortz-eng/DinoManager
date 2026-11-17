import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'ark_species_group.dart';

/// Statistiques d'une espèce de base (issues du JSON).
class ArkStats {
  final int? hp;
  final int? stamina;
  final int? oxygen;
  final int? food;
  final int? weight;
  final int? melee;
  final String? diet;
  final String? taming;
  final bool? rideable;

  const ArkStats({
    this.hp,
    this.stamina,
    this.oxygen,
    this.food,
    this.weight,
    this.melee,
    this.diet,
    this.taming,
    this.rideable,
  });

  factory ArkStats.fromJson(Map<String, dynamic> j) {
    int? i(String key) => (j[key] as num?)?.toInt();
    return ArkStats(
      hp: i('hp'),
      stamina: i('stamina'),
      oxygen: i('oxygen'),
      food: i('food'),
      weight: i('weight'),
      melee: i('melee'),
      diet: j['diet'] as String?,
      taming: j['taming'] as String?,
      rideable: j['rideable'] as bool?,
    );
  }
}

/// Une entrée du catalogue ARK (base ou variante).
class ArkSpecies {
  final String name;
  /// Nom de l'espèce de base (ex. "Rex" pour "Rex X").
  final String base;
  /// none, aberrant, tek, x, r, zombie
  final String variant;
  /// basic ou evolved
  final String stage;
  final ArkSpeciesGroup type;
  final List<String> sexes;
  final bool hasImage;
  final bool hasMask;
  /// 6 positions R0 à R5. null = toutes les régions visibles.
  final List<bool>? regions;
  /// null pour la plupart des variantes : utiliser [effectiveStats].
  final ArkStats? stats;

  const ArkSpecies({
    required this.name,
    required this.base,
    required this.variant,
    required this.stage,
    required this.type,
    required this.sexes,
    required this.hasImage,
    required this.hasMask,
    required this.regions,
    required this.stats,
  });

  factory ArkSpecies.fromJson(Map<String, dynamic> j) {
    final name = j['name'] as String;
    final regionsRaw = j['regions'];
    final statsRaw = j['stats'];
    return ArkSpecies(
      name: name,
      base: (j['base'] as String?) ?? name,
      variant: (j['variant'] as String?) ?? 'none',
      stage: (j['stage'] as String?) ?? 'basic',
      type: ArkSpeciesGroup.values.firstWhere(
        (g) => g.name == j['type'],
        orElse: () => ArkSpeciesGroup.terrestre,
      ),
      sexes: (j['sexes'] as List?)?.cast<String>() ?? const [],
      hasImage: j['image'] == true,
      hasMask: j['mask'] == true,
      regions: regionsRaw is List
          ? regionsRaw.map((e) => e == true).toList()
          : null,
      stats: statsRaw is Map<String, dynamic>
          ? ArkStats.fromJson(statsRaw)
          : null,
    );
  }

  /// Nom de fichier : espaces remplacés par underscores.
  String get fileName => name.replaceAll(' ', '_');

  /// Image attendue : assets/images/dinos/Nom_ASA.png
  String get imagePath => 'assets/images/dinos/${fileName}_ASA.png';

  /// Masque de coloration : assets/images/dinos/Nom_ASA_m.png
  String get maskPath => 'assets/images/dinos/${fileName}_ASA_m.png';

  bool get isVariant => variant != 'none';

  /// Stats propres, ou celles de l'espèce de base si la variante n'en a pas.
  ArkStats? get effectiveStats => stats ?? ArkDb.byName(base)?.stats;

  /// null = toutes visibles. Sinon vérifie la position R0 à R5.
  bool isRegionVisible(int index) {
    final r = regions;
    if (r == null) return true;
    if (index < 0 || index >= r.length) return false;
    return r[index];
  }
}

/// Point d'accès unique à la base JSON. Appeler [ArkDb.load] une fois au démarrage.
class ArkDb {
  static const String assetPath = 'assets/data/ark_species.json';

  static List<ArkSpecies> _all = const [];
  static Map<String, ArkSpecies> _byName = const {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['especes'] as List).cast<Map<String, dynamic>>();

    final map = <String, ArkSpecies>{};
    for (final e in list) {
      final sp = ArkSpecies.fromJson(e);
      map.putIfAbsent(sp.name, () => sp);
    }
    _byName = Map.unmodifiable(map);
    _all = List.unmodifiable(map.values);
    _loaded = true;
  }

  static void _ensureLoaded() {
    if (!_loaded) {
      throw StateError(
        'ArkDb.load() doit être appelé dans main() avant toute utilisation.',
      );
    }
  }

  /// Toutes les entrées, bases et variantes (sans doublons).
  static List<ArkSpecies> get all {
    _ensureLoaded();
    return _all;
  }

  /// Uniquement les espèces de base (variant == none).
  static List<ArkSpecies> get bases =>
      all.where((s) => s.variant == 'none').toList();

  static ArkSpecies? byName(String name) {
    _ensureLoaded();
    return _byName[name];
  }
}
