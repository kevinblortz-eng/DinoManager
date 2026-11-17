// lib/models/ark_species_stats.dart
// Stats de base des espèces ARK Ascended (niveau 1 sauvage).
// Source unique : assets/data/ark_species.json (via ArkDb).
// Ce fichier ne contient plus de données : il traduit le JSON en types Dart.
//
// STRUCTURE DES DONNÉES :
//   hp       : Points de vie de base
//   stamina  : Endurance de base
//   oxygen   : Oxygène de base (150 par défaut)
//   food     : Nourriture de base
//   weight   : Poids de base
//   melee    : Attaque de base en % (100 = 100%)
//   diet     : Régime alimentaire
//   taming   : Méthode de taming
//   rideable : Montable

import 'ark_db.dart';

enum ArkDiet {
  carnivore,
  herbivore,
  omnivore,
  special, // Sang, élément, biotoxine…
}

enum ArkTaming {
  ko,          // Assommer + nourrir
  passive,     // Apprivoisement passif
  special,     // Méthode unique (ex: Fasolasuchus, Wyverne…)
  nonTameable, // Non apprivoisable
}

class ArkSpeciesStats {
  final int hp;
  final int stamina;
  final int oxygen;
  final int food;
  final int weight;
  final double melee; // pourcentage, ex: 62.0 = 62 %
  final ArkDiet diet;
  final ArkTaming taming;
  final bool rideable;

  const ArkSpeciesStats({
    required this.hp,
    required this.stamina,
    this.oxygen = 150,
    required this.food,
    required this.weight,
    required this.melee,
    required this.diet,
    required this.taming,
    this.rideable = true,
  });

  /// Libellé lisible du régime alimentaire
  String get dietLabel {
    switch (diet) {
      case ArkDiet.carnivore:
        return 'Carnivore';
      case ArkDiet.herbivore:
        return 'Herbivore';
      case ArkDiet.omnivore:
        return 'Omnivore';
      case ArkDiet.special:
        return 'Spécial';
    }
  }

  /// Emoji du régime alimentaire
  String get dietEmoji {
    switch (diet) {
      case ArkDiet.carnivore:
        return '🥩';
      case ArkDiet.herbivore:
        return '🌿';
      case ArkDiet.omnivore:
        return '🍖';
      case ArkDiet.special:
        return '✨';
    }
  }

  /// Libellé de la méthode de taming
  String get tamingLabel {
    switch (taming) {
      case ArkTaming.ko:
        return 'KO';
      case ArkTaming.passive:
        return 'Passif';
      case ArkTaming.special:
        return 'Spécial';
      case ArkTaming.nonTameable:
        return 'Non-apprivoisable';
    }
  }
}

/// Accès aux stats d'une espèce, lues depuis ArkDb.
/// La clé est le nom exact de l'espèce (ex. 'Rex X').
class ArkSpeciesStatsDb {
  static const int defaultOxygen = 150;

  /// Retourne les stats de l'espèce, ou null si l'espèce est inconnue
  /// ou si ni elle ni sa base n'ont de stats dans le JSON.
  static ArkSpeciesStats? get(String species) {
    final stats = ArkDb.byName(species)?.effectiveStats;
    if (stats == null) return null;
    return _fromArkStats(stats);
  }

  /// Vérifie si des stats sont disponibles pour cette espèce.
  static bool hasStats(String species) => get(species) != null;

  /// Retourne les stats ou des valeurs vides si l'espèce est inconnue.
  static ArkSpeciesStats getOrEmpty(String species) =>
      get(species) ??
      const ArkSpeciesStats(
        hp: 0,
        stamina: 0,
        food: 0,
        weight: 0,
        melee: 0,
        diet: ArkDiet.carnivore,
        taming: ArkTaming.ko,
      );

  // ─── Conversion JSON → types Dart ─────────────────────────────────────────

  static ArkSpeciesStats _fromArkStats(ArkStats s) => ArkSpeciesStats(
        hp: s.hp ?? 0,
        stamina: s.stamina ?? 0,
        oxygen: s.oxygen ?? defaultOxygen,
        food: s.food ?? 0,
        weight: s.weight ?? 0,
        melee: (s.melee ?? 0).toDouble(),
        diet: _parseDiet(s.diet),
        taming: _parseTaming(s.taming),
        rideable: s.rideable ?? true,
      );

  /// Valeur absente ou inconnue : carnivore (repli neutre).
  static ArkDiet _parseDiet(String? value) {
    switch (value) {
      case 'herbivore':
        return ArkDiet.herbivore;
      case 'omnivore':
        return ArkDiet.omnivore;
      case 'special':
        return ArkDiet.special;
      case 'carnivore':
      default:
        return ArkDiet.carnivore;
    }
  }

  /// Valeur absente ou inconnue : ko (repli neutre).
  static ArkTaming _parseTaming(String? value) {
    switch (value) {
      case 'passive':
        return ArkTaming.passive;
      case 'special':
        return ArkTaming.special;
      case 'none':
        return ArkTaming.nonTameable;
      case 'ko':
      default:
        return ArkTaming.ko;
    }
  }
}
