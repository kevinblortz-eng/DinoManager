// lib/models/ark_species_stats.dart
// AUTO-GENERATED — Stats de base des espèces ARK Ascended (niveau 1 sauvage)
// Sources : ark.wiki.gg, dododex.com (Mai 2026)
//
// STRUCTURE DES DONNÉES :
//   hp       : Points de vie de base
//   stamina  : Endurance de base
//   oxygen   : Oxygène de base (150 par défaut pour terrestres)
//   food     : Nourriture de base
//   weight   : Poids de base
//   melee    : Attaque de base en % (100 = 100%)
//   diet     : Régime alimentaire
//   taming   : Méthode de taming
//   rideable : Montable

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
      case ArkDiet.carnivore:  return 'Carnivore';
      case ArkDiet.herbivore:  return 'Herbivore';
      case ArkDiet.omnivore:   return 'Omnivore';
      case ArkDiet.special:    return 'Spécial';
    }
  }

  /// Emoji du régime alimentaire
  String get dietEmoji {
    switch (diet) {
      case ArkDiet.carnivore:  return '🥩';
      case ArkDiet.herbivore:  return '🌿';
      case ArkDiet.omnivore:   return '🍖';
      case ArkDiet.special:    return '✨';
    }
  }

  /// Libellé de la méthode de taming
  String get tamingLabel {
    switch (taming) {
      case ArkTaming.ko:          return 'KO';
      case ArkTaming.passive:     return 'Passif';
      case ArkTaming.special:     return 'Spécial';
      case ArkTaming.nonTameable: return 'Non-apprivoisable';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RACCOURCIS INTERNES
// ─────────────────────────────────────────────────────────────────────────────
const _carn  = ArkDiet.carnivore;
const _herb  = ArkDiet.herbivore;
const _omni  = ArkDiet.omnivore;
const _spec  = ArkDiet.special;
const _ko    = ArkTaming.ko;
const _pass  = ArkTaming.passive;
const _spc   = ArkTaming.special;
const _none  = ArkTaming.nonTameable;

// ─────────────────────────────────────────────────────────────────────────────
// BASE DE DONNÉES COMPLÈTE
// ─────────────────────────────────────────────────────────────────────────────

/// Retourne les stats de base d'une espèce, ou null si inconnue.
/// La clé correspond EXACTEMENT aux noms dans [ArkSpeciesData.speciesWithImages].
class ArkSpeciesStatsDb {

  static const Map<String, ArkSpeciesStats> _data = {

    // ═══════════════════════════════════════════════════════════
    // A
    // ═══════════════════════════════════════════════════════════

    'Achatina': ArkSpeciesStats(
      hp: 120, stamina: 100, food: 450, weight: 10, melee: 5,
      diet: _herb, taming: _pass, rideable: false,
    ),
    'Achatina Aberrant': ArkSpeciesStats(
      hp: 120, stamina: 100, food: 450, weight: 10, melee: 5,
      diet: _herb, taming: _pass, rideable: false,
    ),

    // Source ark.wiki.gg — Acrocanthosaurus : HP 1100, Stam 500, Food 3000, Weight 600, Melee 58%
    'Acrocanthosaurus': ArkSpeciesStats(
      hp: 1100, stamina: 500, food: 3000, weight: 600, melee: 58,
      diet: _carn, taming: _ko,
    ),

    'Allosaurus': ArkSpeciesStats(
      hp: 800, stamina: 250, food: 3450, weight: 380, melee: 66,
      diet: _carn, taming: _ko,
    ),

    'Anglerfish': ArkSpeciesStats(
      hp: 275, stamina: 200, food: 1000, weight: 100, melee: 30,
      diet: _carn, taming: _ko,
    ),
    'Anglerfish Aberrant': ArkSpeciesStats(
      hp: 275, stamina: 200, food: 1000, weight: 100, melee: 30,
      diet: _carn, taming: _ko,
    ),

    'Ankylosaurus': ArkSpeciesStats(
      hp: 840, stamina: 280, food: 3000, weight: 1500, melee: 44,
      diet: _herb, taming: _ko,
    ),
    'Ankylosaurus Aberrant': ArkSpeciesStats(
      hp: 840, stamina: 280, food: 3000, weight: 1500, melee: 44,
      diet: _herb, taming: _ko,
    ),

    'Araneo': ArkSpeciesStats(
      hp: 165, stamina: 200, food: 900, weight: 50, melee: 25,
      diet: _carn, taming: _ko, rideable: false,
    ),
    'Araneo Aberrant': ArkSpeciesStats(
      hp: 165, stamina: 200, food: 900, weight: 50, melee: 25,
      diet: _carn, taming: _ko, rideable: false,
    ),

    'Archaeopteryx': ArkSpeciesStats(
      hp: 85, stamina: 100, food: 450, weight: 15, melee: 10,
      diet: _carn, taming: _pass, rideable: false,
    ),

    // Source dododex.com — Archelon : HP 1400, Stam 775, Food 3500, Weight 1000, Melee 100%
    'Archelon': ArkSpeciesStats(
      hp: 1400, stamina: 775, food: 3500, weight: 1000, melee: 100,
      diet: _spec, taming: _pass,
    ),

    'Argentavis': ArkSpeciesStats(
      hp: 525, stamina: 280, food: 1500, weight: 350, melee: 50,
      diet: _carn, taming: _ko,
    ),

    // Armadoggo — créature ASA exclusive (pas dans la source TS), données approximatives
    'Armadoggo': ArkSpeciesStats(
      hp: 250, stamina: 200, food: 900, weight: 100, melee: 25,
      diet: _omni, taming: _pass, rideable: false,
    ),

    'Arthropluera': ArkSpeciesStats(
      hp: 480, stamina: 200, food: 1500, weight: 200, melee: 35,
      diet: _carn, taming: _pass,
    ),
    'Arthropluera Aberrant': ArkSpeciesStats(
      hp: 480, stamina: 200, food: 1500, weight: 200, melee: 35,
      diet: _carn, taming: _pass,
    ),

    // Aureliax — créature de mod/vote, données estimées
    'Aureliax': ArkSpeciesStats(
      hp: 600, stamina: 280, food: 1500, weight: 200, melee: 45,
      diet: _carn, taming: _spc,
    ),

    // ═══════════════════════════════════════════════════════════
    // B
    // ═══════════════════════════════════════════════════════════

    'Baryonyx': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 1500, weight: 200, melee: 52,
      diet: _carn, taming: _ko,
    ),
    'Baryonyx Aberrant': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 1500, weight: 200, melee: 52,
      diet: _carn, taming: _ko,
    ),

    'Basilisk': ArkSpeciesStats(
      hp: 1600, stamina: 400, food: 3000, weight: 500, melee: 70,
      diet: _carn, taming: _pass,
    ),

    'Basilosaurus': ArkSpeciesStats(
      hp: 1850, stamina: 600, food: 5000, weight: 500, melee: 45,
      diet: _carn, taming: _pass,
    ),

    'Beelzebufo': ArkSpeciesStats(
      hp: 210, stamina: 150, food: 900, weight: 100, melee: 20,
      diet: _carn, taming: _ko,
    ),
    'Beelzebufo Aberrant': ArkSpeciesStats(
      hp: 210, stamina: 150, food: 900, weight: 100, melee: 20,
      diet: _carn, taming: _ko,
    ),

    'Bison': ArkSpeciesStats(
      hp: 700, stamina: 350, food: 1500, weight: 350, melee: 35,
      diet: _herb, taming: _ko,
    ),

    'Brontosaurus': ArkSpeciesStats(
      hp: 2950, stamina: 800, food: 8000, weight: 1500, melee: 32,
      diet: _herb, taming: _ko,
    ),

    'Bulbdog': ArkSpeciesStats(
      hp: 120, stamina: 100, food: 450, weight: 25, melee: 10,
      diet: _omni, taming: _pass, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // C
    // ═══════════════════════════════════════════════════════════

    'Carbonemys': ArkSpeciesStats(
      hp: 420, stamina: 280, food: 1500, weight: 200, melee: 25,
      diet: _herb, taming: _ko, rideable: false,
    ),
    'Carbonemys Aberrant': ArkSpeciesStats(
      hp: 420, stamina: 280, food: 1500, weight: 200, melee: 25,
      diet: _herb, taming: _ko, rideable: false,
    ),

    // Source ark.wiki.gg — Carcharodontosaurus : HP 1800, Stam 500, Food 3000, Weight 500, Melee 110%
    'Carcharodontosaurus': ArkSpeciesStats(
      hp: 1800, stamina: 500, food: 3000, weight: 500, melee: 110,
      diet: _carn, taming: _ko,
    ),

    'Carnotaurus': ArkSpeciesStats(
      hp: 560, stamina: 300, food: 1500, weight: 250, melee: 52,
      diet: _carn, taming: _ko,
    ),
    'Carnotaurus Aberrant': ArkSpeciesStats(
      hp: 560, stamina: 300, food: 1500, weight: 250, melee: 52,
      diet: _carn, taming: _ko,
    ),

    'Castoroides': ArkSpeciesStats(
      hp: 520, stamina: 280, food: 1500, weight: 300, melee: 28,
      diet: _herb, taming: _ko,
    ),

    // Cat — créature ASA/mod, données estimées
    'Cat': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 450, weight: 20, melee: 10,
      diet: _carn, taming: _pass, rideable: false,
    ),

    // Source ark.wiki.gg — Ceratosaurus : HP 550, Stam ?, Food ?, Weight ?, Melee ?
    // Complété avec NamuWiki et wiki.gg snippet
    'Ceratosaurus': ArkSpeciesStats(
      hp: 550, stamina: 300, food: 1500, weight: 250, melee: 55,
      diet: _carn, taming: _pass,
    ),

    'Chalicotherium': ArkSpeciesStats(
      hp: 650, stamina: 300, food: 2000, weight: 250, melee: 35,
      diet: _herb, taming: _pass,
    ),

    // Chalk Elemental — variante Rock Elemental de Lost Island
    'Chalk Elemental': ArkSpeciesStats(
      hp: 2200, stamina: 400, food: 2000, weight: 1200, melee: 80,
      diet: _spec, taming: _pass,
    ),

    'Cnidaria': ArkSpeciesStats(
      hp: 200, stamina: 200, food: 900, weight: 50, melee: 20,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Coelacanth': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 450, weight: 30, melee: 10,
      diet: _carn, taming: _none, rideable: false,
    ),
    'Coelacanth Aberrant': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 450, weight: 30, melee: 10,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Compy': ArkSpeciesStats(
      hp: 65, stamina: 100, food: 300, weight: 15, melee: 10,
      diet: _carn, taming: _pass, rideable: false,
    ),

    // Cosmo — créature ASA exclusive, données estimées
    'Cosmo': ArkSpeciesStats(
      hp: 200, stamina: 150, food: 600, weight: 50, melee: 15,
      diet: _spec, taming: _pass, rideable: false,
    ),

    // Cryolophosaurus — créature ASA/mod, données estimées
    'Cryolophosaurus': ArkSpeciesStats(
      hp: 650, stamina: 280, food: 1500, weight: 250, melee: 55,
      diet: _carn, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // D
    // ═══════════════════════════════════════════════════════════

    'Daeodon': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 2000, weight: 300, melee: 42,
      diet: _omni, taming: _pass,
    ),

    'Deinonychus': ArkSpeciesStats(
      hp: 330, stamina: 210, food: 900, weight: 100, melee: 60,
      diet: _carn, taming: _pass,
    ),

    // Source ark.wiki.gg — Deinosuchus : HP ~1200, Stam ~350, Food 3000, Weight 600, Melee 55%
    // (wiki.gg snippet mentionne Food 3000, Weight 600, Melee 55/70)
    'Deinosuchus': ArkSpeciesStats(
      hp: 1200, stamina: 350, food: 3000, weight: 600, melee: 55,
      diet: _carn, taming: _pass,
    ),

    // Source ark.wiki.gg — Deinotherium : HP 1750, Stam 450, Food ?, Weight 800, Melee 100%
    'Deinotherium': ArkSpeciesStats(
      hp: 1750, stamina: 450, food: 3000, weight: 800, melee: 100,
      diet: _herb, taming: _pass,
    ),

    // Source dododex.com — Desmodus : HP 325, Stam 500, Food ~1000, Weight 350, Melee 40%
    'Desmodus': ArkSpeciesStats(
      hp: 325, stamina: 500, food: 1000, weight: 350, melee: 40,
      diet: _spec, taming: _pass,
    ),

    'Dimetrodon': ArkSpeciesStats(
      hp: 350, stamina: 200, food: 1200, weight: 100, melee: 30,
      diet: _carn, taming: _ko, rideable: false,
    ),
    'Dimetrodon Aberrant': ArkSpeciesStats(
      hp: 350, stamina: 200, food: 1200, weight: 100, melee: 30,
      diet: _carn, taming: _ko, rideable: false,
    ),

    'Dimorphodon': ArkSpeciesStats(
      hp: 135, stamina: 100, food: 450, weight: 30, melee: 30,
      diet: _carn, taming: _ko, rideable: false,
    ),
    'Dimorphodon Aberrant': ArkSpeciesStats(
      hp: 135, stamina: 100, food: 450, weight: 30, melee: 30,
      diet: _carn, taming: _ko, rideable: false,
    ),

    'Diplocaulus': ArkSpeciesStats(
      hp: 210, stamina: 150, food: 900, weight: 75, melee: 20,
      diet: _carn, taming: _ko, rideable: false,
    ),
    'Diplocaulus Aberrant': ArkSpeciesStats(
      hp: 210, stamina: 150, food: 900, weight: 75, melee: 20,
      diet: _carn, taming: _ko, rideable: false,
    ),

    'Diplodocus': ArkSpeciesStats(
      hp: 2100, stamina: 700, food: 8000, weight: 1800, melee: 18,
      diet: _herb, taming: _ko,
    ),
    'Diplodocus Aberrant': ArkSpeciesStats(
      hp: 2100, stamina: 700, food: 8000, weight: 1800, melee: 18,
      diet: _herb, taming: _ko,
    ),

    'Dire Bear': ArkSpeciesStats(
      hp: 700, stamina: 250, food: 2000, weight: 350, melee: 45,
      diet: _omni, taming: _ko,
    ),
    'Dire Bear Aberrant': ArkSpeciesStats(
      hp: 700, stamina: 250, food: 2000, weight: 350, melee: 45,
      diet: _omni, taming: _ko,
    ),

    // Dire Polar Bear — variante, mêmes stats de base
    'Dire Polar Bear': ArkSpeciesStats(
      hp: 700, stamina: 250, food: 2000, weight: 350, melee: 45,
      diet: _omni, taming: _ko,
    ),

    'Direwolf': ArkSpeciesStats(
      hp: 400, stamina: 200, food: 1000, weight: 125, melee: 52,
      diet: _carn, taming: _ko,
    ),

    'Dodo': ArkSpeciesStats(
      hp: 35, stamina: 100, food: 450, weight: 15, melee: 5,
      diet: _herb, taming: _ko, rideable: false,
    ),
    'Dodo Aberrant': ArkSpeciesStats(
      hp: 35, stamina: 100, food: 450, weight: 15, melee: 5,
      diet: _herb, taming: _ko, rideable: false,
    ),

    'Doedicurus': ArkSpeciesStats(
      hp: 420, stamina: 280, food: 1500, weight: 300, melee: 36,
      diet: _herb, taming: _ko,
    ),
    'Doedicurus Aberrant': ArkSpeciesStats(
      hp: 420, stamina: 280, food: 1500, weight: 300, melee: 36,
      diet: _herb, taming: _ko,
    ),

    // Drakelings — créatures de saison/événement, stats estimées
    'Drakeling (Autumn)': ArkSpeciesStats(
      hp: 800, stamina: 350, food: 2000, weight: 300, melee: 65,
      diet: _carn, taming: _spc,
    ),
    'Drakeling (Spring)': ArkSpeciesStats(
      hp: 800, stamina: 350, food: 2000, weight: 300, melee: 65,
      diet: _carn, taming: _spc,
    ),
    'Drakeling (Summer)': ArkSpeciesStats(
      hp: 800, stamina: 350, food: 2000, weight: 300, melee: 65,
      diet: _carn, taming: _spc,
    ),
    'Drakeling (Winter)': ArkSpeciesStats(
      hp: 800, stamina: 350, food: 2000, weight: 300, melee: 65,
      diet: _carn, taming: _spc,
    ),

    // Dreadmare — créature de mod/vote, données estimées
    'Dreadmare': ArkSpeciesStats(
      hp: 700, stamina: 350, food: 1500, weight: 250, melee: 55,
      diet: _carn, taming: _spc,
    ),

    // Source dododex.com — Dreadnoughtus : HP 100000, Stam 300, Food ?, Weight 3000, Melee 100%
    'Dreadnoughtus': ArkSpeciesStats(
      hp: 100000, stamina: 300, food: 8000, weight: 3000, melee: 100,
      diet: _herb, taming: _ko,
    ),

    'Dung Beetle': ArkSpeciesStats(
      hp: 200, stamina: 150, food: 900, weight: 50, melee: 10,
      diet: _spec, taming: _pass, rideable: false,
    ),
    'Dung Beetle Aberrant': ArkSpeciesStats(
      hp: 200, stamina: 150, food: 900, weight: 50, melee: 10,
      diet: _spec, taming: _pass, rideable: false,
    ),

    'Dunkleosteus': ArkSpeciesStats(
      hp: 600, stamina: 280, food: 1500, weight: 400, melee: 40,
      diet: _carn, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // E
    // ═══════════════════════════════════════════════════════════

    // Elderclaw — créature de mod/vote, données estimées
    'Elderclaw': ArkSpeciesStats(
      hp: 900, stamina: 350, food: 2000, weight: 350, melee: 70,
      diet: _carn, taming: _spc,
    ),

    'Electrophorus': ArkSpeciesStats(
      hp: 230, stamina: 200, food: 900, weight: 50, melee: 30,
      diet: _carn, taming: _none, rideable: false,
    ),
    'Electrophorus Aberrant': ArkSpeciesStats(
      hp: 230, stamina: 200, food: 900, weight: 50, melee: 30,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Enforcer': ArkSpeciesStats(
      hp: 475, stamina: 350, food: 1200, weight: 300, melee: 60,
      diet: _spec, taming: _none, rideable: false,
    ),

    'Equus': ArkSpeciesStats(
      hp: 340, stamina: 280, food: 1500, weight: 200, melee: 25,
      diet: _herb, taming: _pass,
    ),
    'Equus Aberrant': ArkSpeciesStats(
      hp: 340, stamina: 280, food: 1500, weight: 200, melee: 25,
      diet: _herb, taming: _pass,
    ),

    // ═══════════════════════════════════════════════════════════
    // F
    // ═══════════════════════════════════════════════════════════

    // Source dododex.com — Fasolasuchus : HP 950, Stam 350, Food ~2000, Weight 400, Melee 100%
    'Fasolasuchus': ArkSpeciesStats(
      hp: 950, stamina: 350, food: 2000, weight: 400, melee: 100,
      diet: _carn, taming: _spc,
    ),
    'Fasolasuchus Aberrant': ArkSpeciesStats(
      hp: 950, stamina: 350, food: 2000, weight: 400, melee: 100,
      diet: _carn, taming: _spc,
    ),

    'Featherlight': ArkSpeciesStats(
      hp: 100, stamina: 100, food: 450, weight: 20, melee: 10,
      diet: _herb, taming: _pass, rideable: false,
    ),

    'Fire Wyvern': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 82,
      diet: _carn, taming: _spc,
    ),

    // ═══════════════════════════════════════════════════════════
    // G
    // ═══════════════════════════════════════════════════════════

    'Gacha': ArkSpeciesStats(
      hp: 2800, stamina: 400, food: 3000, weight: 1200, melee: 40,
      diet: _omni, taming: _pass,
    ),

    'Gallimimus': ArkSpeciesStats(
      hp: 200, stamina: 200, food: 600, weight: 100, melee: 10,
      diet: _herb, taming: _ko,
    ),

    'Gasbags': ArkSpeciesStats(
      hp: 1200, stamina: 400, food: 2500, weight: 500, melee: 30,
      diet: _herb, taming: _pass,
    ),

    // Gigadesmodus — variant géant du Desmodus, données estimées
    'Gigadesmodus': ArkSpeciesStats(
      hp: 1200, stamina: 500, food: 2500, weight: 600, melee: 70,
      diet: _spec, taming: _none,
    ),

    'Giganotosaurus': ArkSpeciesStats(
      hp: 80000, stamina: 420, food: 10000, weight: 1500, melee: 100,
      diet: _carn, taming: _ko,
    ),
    // Tek Giga — non-apprivoisable dans le jeu vanilla
    'Giganotosaurus Tek': ArkSpeciesStats(
      hp: 96000, stamina: 420, food: 12000, weight: 1800, melee: 120,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Gigantopithecus': ArkSpeciesStats(
      hp: 330, stamina: 200, food: 1200, weight: 150, melee: 35,
      diet: _herb, taming: _pass, rideable: false,
    ),
    'Gigantopithecus Aberrant': ArkSpeciesStats(
      hp: 330, stamina: 200, food: 1200, weight: 150, melee: 35,
      diet: _herb, taming: _pass, rideable: false,
    ),

    // Source ark.wiki.gg — Gigantoraptor : HP 770, Stam ?, Food 3000, Weight 320, Melee 100%
    'Gigantoraptor': ArkSpeciesStats(
      hp: 770, stamina: 280, food: 3000, weight: 320, melee: 100,
      diet: _carn, taming: _ko,
    ),
    'Gigantoraptor Aberrant': ArkSpeciesStats(
      hp: 770, stamina: 280, food: 3000, weight: 320, melee: 100,
      diet: _carn, taming: _ko,
    ),

    // Gloon — créature de mod/événement, données estimées
    'Gloon': ArkSpeciesStats(
      hp: 500, stamina: 250, food: 1200, weight: 200, melee: 40,
      diet: _carn, taming: _pass, rideable: false,
    ),

    'Glowtail': ArkSpeciesStats(
      hp: 120, stamina: 100, food: 450, weight: 25, melee: 10,
      diet: _herb, taming: _pass, rideable: false,
    ),

    // Grand Tortugar — créature de mod/vote, données estimées
    'Grand Tortugar': ArkSpeciesStats(
      hp: 3000, stamina: 600, food: 6000, weight: 2000, melee: 50,
      diet: _herb, taming: _ko,
    ),

    // Grendel (Alpha) — boss/créature événement, données estimées
    'Grendel (Alpha)': ArkSpeciesStats(
      hp: 50000, stamina: 500, food: 5000, weight: 1000, melee: 150,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Griffin': ArkSpeciesStats(
      hp: 875, stamina: 350, food: 2500, weight: 350, melee: 60,
      diet: _carn, taming: _pass,
    ),

    // ═══════════════════════════════════════════════════════════
    // H
    // ═══════════════════════════════════════════════════════════

    // Source dododex.com — Helicoprion : HP 1300, Stam 500, Food ?, Weight ?, Melee ?
    'Helicoprion': ArkSpeciesStats(
      hp: 1300, stamina: 500, food: 2000, weight: 400, melee: 70,
      diet: _carn, taming: _ko,
    ),

    'Hesperornis': ArkSpeciesStats(
      hp: 120, stamina: 150, food: 600, weight: 50, melee: 15,
      diet: _carn, taming: _ko, rideable: false,
    ),

    'Hyaenodon': ArkSpeciesStats(
      hp: 350, stamina: 200, food: 1000, weight: 125, melee: 40,
      diet: _carn, taming: _pass, rideable: false,
    ),

    // Hydraskos the Unbroken — boss/créature événement, données estimées
    'Hydraskos the Unbroken': ArkSpeciesStats(
      hp: 80000, stamina: 600, food: 10000, weight: 2000, melee: 120,
      diet: _carn, taming: _none, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // I
    // ═══════════════════════════════════════════════════════════

    // Ice Elemental — variante Rock Elemental, données estimées
    'Ice Elemental': ArkSpeciesStats(
      hp: 2200, stamina: 400, food: 2000, weight: 1200, melee: 80,
      diet: _spec, taming: _pass,
    ),

    'Ice Wyvern': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 78,
      diet: _carn, taming: _spc,
    ),

    'Ichthyornis': ArkSpeciesStats(
      hp: 75, stamina: 100, food: 450, weight: 15, melee: 15,
      diet: _carn, taming: _ko, rideable: false,
    ),

    'Ichthyosaurus': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 600, weight: 50, melee: 10,
      diet: _carn, taming: _pass,
    ),

    'Iguanodon': ArkSpeciesStats(
      hp: 380, stamina: 280, food: 1200, weight: 200, melee: 20,
      diet: _herb, taming: _ko,
    ),
    'Iguanodon Aberrant': ArkSpeciesStats(
      hp: 380, stamina: 280, food: 1200, weight: 200, melee: 20,
      diet: _herb, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // J
    // ═══════════════════════════════════════════════════════════

    'Jerboa': ArkSpeciesStats(
      hp: 75, stamina: 100, food: 300, weight: 15, melee: 5,
      diet: _herb, taming: _pass, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // K
    // ═══════════════════════════════════════════════════════════

    'Kairuku': ArkSpeciesStats(
      hp: 90, stamina: 100, food: 450, weight: 25, melee: 10,
      diet: _carn, taming: _pass, rideable: false,
    ),

    'Kaprosuchus': ArkSpeciesStats(
      hp: 375, stamina: 200, food: 1200, weight: 150, melee: 40,
      diet: _carn, taming: _ko,
    ),

    'Karkinos': ArkSpeciesStats(
      hp: 1200, stamina: 350, food: 2000, weight: 800, melee: 55,
      diet: _carn, taming: _ko,
    ),

    'Kentrosaurus': ArkSpeciesStats(
      hp: 600, stamina: 280, food: 1500, weight: 300, melee: 30,
      diet: _herb, taming: _ko, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // L
    // ═══════════════════════════════════════════════════════════

    // Lava Elemental — Extinction/Genesis variant
    'Lava Elemental': ArkSpeciesStats(
      hp: 80000, stamina: 600, food: 5000, weight: 2000, melee: 120,
      diet: _spec, taming: _none, rideable: false,
    ),

    'Lightning Wyvern': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 80,
      diet: _carn, taming: _spc,
    ),

    'Liopleurodon': ArkSpeciesStats(
      hp: 1200, stamina: 400, food: 4000, weight: 300, melee: 50,
      diet: _carn, taming: _pass,
    ),

    'Lymantria': ArkSpeciesStats(
      hp: 200, stamina: 200, food: 900, weight: 75, melee: 15,
      diet: _herb, taming: _ko,
    ),

    'Lystrosaurus': ArkSpeciesStats(
      hp: 100, stamina: 100, food: 450, weight: 50, melee: 10,
      diet: _herb, taming: _ko, rideable: false,
    ),
    'Lystrosaurus Aberrant': ArkSpeciesStats(
      hp: 100, stamina: 100, food: 450, weight: 50, melee: 10,
      diet: _herb, taming: _ko, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // M
    // ═══════════════════════════════════════════════════════════

    // Maeguana — créature de mod/vote, données estimées
    'Maeguana': ArkSpeciesStats(
      hp: 600, stamina: 300, food: 1500, weight: 250, melee: 50,
      diet: _carn, taming: _spc,
    ),

    // Malwyn — créature de mod/vote, données estimées
    'Malwyn': ArkSpeciesStats(
      hp: 700, stamina: 350, food: 2000, weight: 300, melee: 60,
      diet: _carn, taming: _spc,
    ),

    'Mammoth': ArkSpeciesStats(
      hp: 700, stamina: 350, food: 1500, weight: 350, melee: 35,
      diet: _herb, taming: _ko,
    ),

    'Managarmr': ArkSpeciesStats(
      hp: 1100, stamina: 420, food: 2500, weight: 400, melee: 55,
      diet: _carn, taming: _ko,
    ),

    'Manta': ArkSpeciesStats(
      hp: 180, stamina: 200, food: 900, weight: 75, melee: 25,
      diet: _carn, taming: _pass,
    ),
    'Manta Aberrant': ArkSpeciesStats(
      hp: 180, stamina: 200, food: 900, weight: 75, melee: 25,
      diet: _carn, taming: _pass,
    ),

    'Mantis': ArkSpeciesStats(
      hp: 400, stamina: 280, food: 1200, weight: 200, melee: 45,
      diet: _carn, taming: _pass,
    ),

    'Megalania': ArkSpeciesStats(
      hp: 280, stamina: 200, food: 900, weight: 100, melee: 30,
      diet: _carn, taming: _ko, rideable: false,
    ),
    'Megalania Aberrant': ArkSpeciesStats(
      hp: 280, stamina: 200, food: 900, weight: 100, melee: 30,
      diet: _carn, taming: _ko, rideable: false,
    ),

    'Megaloceros': ArkSpeciesStats(
      hp: 350, stamina: 250, food: 1200, weight: 150, melee: 25,
      diet: _herb, taming: _ko,
    ),

    'Megalodon': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 2000, weight: 300, melee: 60,
      diet: _carn, taming: _ko,
    ),

    'Megalosaurus': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 2000, weight: 250, melee: 50,
      diet: _carn, taming: _ko,
    ),
    'Megalosaurus Aberrant': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 2000, weight: 250, melee: 50,
      diet: _carn, taming: _ko,
    ),

    'Meganeura': ArkSpeciesStats(
      hp: 50, stamina: 100, food: 300, weight: 5, melee: 5,
      diet: _carn, taming: _none, rideable: false,
    ),
    'Meganeura Aberrant': ArkSpeciesStats(
      hp: 50, stamina: 100, food: 300, weight: 5, melee: 5,
      diet: _carn, taming: _none, rideable: false,
    ),

    // Megaraptor — créature de mod/vote, données estimées
    'Megaraptor': ArkSpeciesStats(
      hp: 500, stamina: 250, food: 1200, weight: 200, melee: 65,
      diet: _carn, taming: _ko,
    ),

    'Megatherium': ArkSpeciesStats(
      hp: 980, stamina: 350, food: 3000, weight: 400, melee: 42,
      diet: _omni, taming: _ko,
    ),

    // Minotarchos — créature de mod/vote, données estimées
    'Minotarchos': ArkSpeciesStats(
      hp: 1500, stamina: 400, food: 3000, weight: 600, melee: 80,
      diet: _carn, taming: _spc, rideable: false,
    ),

    'Morellatops': ArkSpeciesStats(
      hp: 350, stamina: 250, food: 1500, weight: 200, melee: 20,
      diet: _herb, taming: _ko,
    ),

    'Mosasaurus': ArkSpeciesStats(
      hp: 2400, stamina: 420, food: 6000, weight: 750, melee: 80,
      diet: _carn, taming: _ko,
    ),

    'Moschops': ArkSpeciesStats(
      hp: 280, stamina: 200, food: 1200, weight: 150, melee: 20,
      diet: _omni, taming: _pass, rideable: false,
    ),
    'Moschops Aberrant': ArkSpeciesStats(
      hp: 280, stamina: 200, food: 1200, weight: 150, melee: 20,
      diet: _omni, taming: _pass, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // N
    // ═══════════════════════════════════════════════════════════

    // Neophyte — créature de mod/vote, données estimées
    'Neophyte': ArkSpeciesStats(
      hp: 300, stamina: 200, food: 900, weight: 100, melee: 30,
      diet: _spec, taming: _pass, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // O
    // ═══════════════════════════════════════════════════════════

    // Oasisaur — créature ASA exclusive
    'Oasisaur': ArkSpeciesStats(
      hp: 5000, stamina: 600, food: 8000, weight: 2000, melee: 40,
      diet: _herb, taming: _pass,
    ),

    'Onyc': ArkSpeciesStats(
      hp: 125, stamina: 100, food: 450, weight: 40, melee: 10,
      diet: _carn, taming: _ko, rideable: false,
    ),

    // Ossidon — créature de mod/vote, données estimées
    'Ossidon': ArkSpeciesStats(
      hp: 1200, stamina: 400, food: 3000, weight: 500, melee: 80,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Otter': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 600, weight: 25, melee: 15,
      diet: _carn, taming: _pass, rideable: false,
    ),
    'Otter Aberrant': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 600, weight: 25, melee: 15,
      diet: _carn, taming: _pass, rideable: false,
    ),

    'Oviraptor': ArkSpeciesStats(
      hp: 175, stamina: 150, food: 900, weight: 75, melee: 20,
      diet: _omni, taming: _ko, rideable: false,
    ),
    'Oviraptor Aberrant': ArkSpeciesStats(
      hp: 175, stamina: 150, food: 900, weight: 75, melee: 20,
      diet: _omni, taming: _ko, rideable: false,
    ),

    'Ovis': ArkSpeciesStats(
      hp: 200, stamina: 150, food: 900, weight: 75, melee: 10,
      diet: _herb, taming: _pass,
    ),
    'Ovis Aberrant': ArkSpeciesStats(
      hp: 200, stamina: 150, food: 900, weight: 75, melee: 10,
      diet: _herb, taming: _pass,
    ),

    // ═══════════════════════════════════════════════════════════
    // P
    // ═══════════════════════════════════════════════════════════

    'Pachyrhinosaurus': ArkSpeciesStats(
      hp: 600, stamina: 280, food: 1500, weight: 300, melee: 30,
      diet: _herb, taming: _ko,
    ),

    'Paraceratherium': ArkSpeciesStats(
      hp: 1200, stamina: 560, food: 3000, weight: 1000, melee: 18,
      diet: _herb, taming: _ko,
    ),
    'Paraceratherium Aberrant': ArkSpeciesStats(
      hp: 1200, stamina: 560, food: 3000, weight: 1000, melee: 18,
      diet: _herb, taming: _ko,
    ),

    'Parasaur': ArkSpeciesStats(
      hp: 200, stamina: 280, food: 1000, weight: 100, melee: 15,
      diet: _herb, taming: _ko,
    ),
    'Parasaur Aberrant': ArkSpeciesStats(
      hp: 200, stamina: 280, food: 1000, weight: 100, melee: 15,
      diet: _herb, taming: _ko,
    ),
    'Parasaur Tek': ArkSpeciesStats(
      hp: 240, stamina: 280, food: 1200, weight: 120, melee: 18,
      diet: _herb, taming: _ko,
    ),

    'Pegomastax': ArkSpeciesStats(
      hp: 90, stamina: 100, food: 450, weight: 25, melee: 15,
      diet: _herb, taming: _pass, rideable: false,
    ),

    'Pelagornis': ArkSpeciesStats(
      hp: 200, stamina: 200, food: 1000, weight: 50, melee: 25,
      diet: _carn, taming: _ko,
    ),

    'Phoenix': ArkSpeciesStats(
      hp: 2800, stamina: 600, food: 3000, weight: 500, melee: 75,
      diet: _spec, taming: _pass,
    ),

    'Piranha': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 450, weight: 25, melee: 20,
      diet: _carn, taming: _none, rideable: false,
    ),
    'Piranha Aberrant': ArkSpeciesStats(
      hp: 100, stamina: 150, food: 450, weight: 25, melee: 20,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Plesiosaur': ArkSpeciesStats(
      hp: 2400, stamina: 400, food: 6000, weight: 600, melee: 40,
      diet: _carn, taming: _ko,
    ),

    'Poison Wyvern': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 75,
      diet: _carn, taming: _spc,
    ),

    'Procoptodon': ArkSpeciesStats(
      hp: 430, stamina: 350, food: 1500, weight: 200, melee: 28,
      diet: _herb, taming: _ko,
    ),

    'Pteranodon': ArkSpeciesStats(
      hp: 270, stamina: 100, food: 900, weight: 150, melee: 25,
      diet: _carn, taming: _ko,
    ),

    'Pulmonoscorpius': ArkSpeciesStats(
      hp: 270, stamina: 200, food: 1200, weight: 100, melee: 30,
      diet: _carn, taming: _ko,
    ),
    'Pulmonoscorpius Aberrant': ArkSpeciesStats(
      hp: 270, stamina: 200, food: 1200, weight: 100, melee: 30,
      diet: _carn, taming: _ko,
    ),

    'Purlovia': ArkSpeciesStats(
      hp: 350, stamina: 200, food: 1200, weight: 150, melee: 35,
      diet: _carn, taming: _ko, rideable: false,
    ),
    'Purlovia Aberrant': ArkSpeciesStats(
      hp: 350, stamina: 200, food: 1200, weight: 150, melee: 35,
      diet: _carn, taming: _ko, rideable: false,
    ),

    // Pyromane — créature ASA exclusive (Scorched Earth)
    'Pyromane': ArkSpeciesStats(
      hp: 500, stamina: 200, food: 1000, weight: 150, melee: 45,
      diet: _spec, taming: _pass,
    ),

    // ═══════════════════════════════════════════════════════════
    // Q
    // ═══════════════════════════════════════════════════════════

    'Quetzal': ArkSpeciesStats(
      hp: 900, stamina: 350, food: 3000, weight: 800, melee: 30,
      diet: _herb, taming: _ko,
    ),
    'Quetzal Tek': ArkSpeciesStats(
      hp: 1080, stamina: 350, food: 3600, weight: 960, melee: 36,
      diet: _herb, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // R
    // ═══════════════════════════════════════════════════════════

    'Raptor': ArkSpeciesStats(
      hp: 350, stamina: 210, food: 900, weight: 100, melee: 52,
      diet: _carn, taming: _ko,
    ),
    'Raptor Aberrant': ArkSpeciesStats(
      hp: 350, stamina: 210, food: 900, weight: 100, melee: 52,
      diet: _carn, taming: _ko,
    ),
    'Raptor Tek': ArkSpeciesStats(
      hp: 420, stamina: 210, food: 1080, weight: 120, melee: 62,
      diet: _carn, taming: _ko,
    ),

    'Ravager': ArkSpeciesStats(
      hp: 420, stamina: 210, food: 1000, weight: 150, melee: 50,
      diet: _carn, taming: _ko,
    ),

    'Reaper King': ArkSpeciesStats(
      hp: 2000, stamina: 700, food: 5000, weight: 500, melee: 80,
      diet: _carn, taming: _spc,
    ),

    'Rex': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 62,
      diet: _carn, taming: _ko,
    ),
    'Rex Tek': ArkSpeciesStats(
      hp: 1440, stamina: 420, food: 3600, weight: 600, melee: 74,
      diet: _carn, taming: _ko,
    ),

    // Source ark.wiki.gg — Rhyniognatha : HP 450, Stam 250, Food 1200, Weight 200, Melee 45%
    'Rhyniognatha': ArkSpeciesStats(
      hp: 450, stamina: 250, food: 1200, weight: 200, melee: 45,
      diet: _spec, taming: _spc,
    ),
    'Rhyniognatha Drone': ArkSpeciesStats(
      hp: 200, stamina: 200, food: 600, weight: 100, melee: 25,
      diet: _spec, taming: _none, rideable: false,
    ),

    'Rock Drake': ArkSpeciesStats(
      hp: 900, stamina: 350, food: 2000, weight: 400, melee: 68,
      diet: _carn, taming: _spc,
    ),

    'Rock Elemental': ArkSpeciesStats(
      hp: 2200, stamina: 400, food: 2000, weight: 1200, melee: 80,
      diet: _spec, taming: _pass,
    ),

    'Roll Rat': ArkSpeciesStats(
      hp: 520, stamina: 280, food: 1500, weight: 400, melee: 35,
      diet: _herb, taming: _pass,
    ),

    'Rubble Golem': ArkSpeciesStats(
      hp: 1100, stamina: 300, food: 1500, weight: 800, melee: 60,
      diet: _spec, taming: _pass, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // S
    // ═══════════════════════════════════════════════════════════

    'Sabertooth': ArkSpeciesStats(
      hp: 400, stamina: 200, food: 1000, weight: 125, melee: 52,
      diet: _carn, taming: _ko,
    ),

    'Sabertooth Salmon': ArkSpeciesStats(
      hp: 75, stamina: 100, food: 300, weight: 15, melee: 15,
      diet: _carn, taming: _none, rideable: false,
    ),
    'Salmon Aberrant': ArkSpeciesStats(
      hp: 75, stamina: 100, food: 300, weight: 15, melee: 15,
      diet: _carn, taming: _none, rideable: false,
    ),

    'Sarco': ArkSpeciesStats(
      hp: 540, stamina: 210, food: 1500, weight: 225, melee: 38,
      diet: _carn, taming: _ko,
    ),
    'Sarco Aberrant': ArkSpeciesStats(
      hp: 540, stamina: 210, food: 1500, weight: 225, melee: 38,
      diet: _carn, taming: _ko,
    ),

    // Source ark.wiki.gg — Shastasaurus : HP 4500, Stam 300, Food ?, Weight ?, Melee ?
    'Shastasaurus': ArkSpeciesStats(
      hp: 4500, stamina: 300, food: 8000, weight: 1200, melee: 60,
      diet: _carn, taming: _pass,
    ),

    'Shinehorn': ArkSpeciesStats(
      hp: 140, stamina: 150, food: 600, weight: 50, melee: 10,
      diet: _herb, taming: _pass, rideable: false,
    ),

    'Snow Owl': ArkSpeciesStats(
      hp: 725, stamina: 350, food: 1200, weight: 200, melee: 45,
      diet: _carn, taming: _ko,
    ),

    // Solwyn — créature de mod/vote, données estimées
    'Solwyn': ArkSpeciesStats(
      hp: 700, stamina: 350, food: 2000, weight: 300, melee: 60,
      diet: _carn, taming: _spc,
    ),

    'Spino': ArkSpeciesStats(
      hp: 1100, stamina: 385, food: 3000, weight: 500, melee: 70,
      diet: _carn, taming: _ko,
    ),
    'Spino Aberrant': ArkSpeciesStats(
      hp: 1100, stamina: 385, food: 3000, weight: 500, melee: 70,
      diet: _carn, taming: _ko,
    ),

    'Stegosaurus': ArkSpeciesStats(
      hp: 840, stamina: 420, food: 3000, weight: 350, melee: 36,
      diet: _herb, taming: _ko,
    ),
    'Stegosaurus Aberrant': ArkSpeciesStats(
      hp: 840, stamina: 420, food: 3000, weight: 350, melee: 36,
      diet: _herb, taming: _ko,
    ),
    'Stegosaurus Tek': ArkSpeciesStats(
      hp: 1008, stamina: 420, food: 3600, weight: 420, melee: 43,
      diet: _herb, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // T
    // ═══════════════════════════════════════════════════════════

    'Tapejara': ArkSpeciesStats(
      hp: 300, stamina: 200, food: 1000, weight: 100, melee: 25,
      diet: _carn, taming: _ko,
    ),

    'Terror Bird': ArkSpeciesStats(
      hp: 350, stamina: 210, food: 900, weight: 100, melee: 48,
      diet: _carn, taming: _ko,
    ),

    'Therizinosaur': ArkSpeciesStats(
      hp: 700, stamina: 420, food: 4000, weight: 450, melee: 52,
      diet: _herb, taming: _pass,
    ),

    'Thorny Dragon': ArkSpeciesStats(
      hp: 450, stamina: 250, food: 1200, weight: 200, melee: 35,
      diet: _herb, taming: _ko,
    ),

    'Thylacoleo': ArkSpeciesStats(
      hp: 550, stamina: 240, food: 1500, weight: 180, melee: 60,
      diet: _carn, taming: _ko,
    ),

    'Titanoboa': ArkSpeciesStats(
      hp: 300, stamina: 200, food: 1000, weight: 50, melee: 30,
      diet: _carn, taming: _pass, rideable: false,
    ),
    'Titanoboa Aberrant': ArkSpeciesStats(
      hp: 300, stamina: 200, food: 1000, weight: 50, melee: 30,
      diet: _carn, taming: _pass, rideable: false,
    ),

    'Triceratops': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 1500, weight: 250, melee: 40,
      diet: _herb, taming: _ko,
    ),
    'Triceratops Aberrant': ArkSpeciesStats(
      hp: 700, stamina: 280, food: 1500, weight: 250, melee: 40,
      diet: _herb, taming: _ko,
    ),
    'Triceratops Tek': ArkSpeciesStats(
      hp: 840, stamina: 280, food: 1800, weight: 300, melee: 48,
      diet: _herb, taming: _ko,
    ),

    'Troodon': ArkSpeciesStats(
      hp: 175, stamina: 150, food: 900, weight: 75, melee: 28,
      diet: _carn, taming: _spc, rideable: false,
    ),

    'Tusoteuthis': ArkSpeciesStats(
      hp: 2000, stamina: 500, food: 5000, weight: 500, melee: 60,
      diet: _carn, taming: _pass,
    ),

    // ═══════════════════════════════════════════════════════════
    // U
    // ═══════════════════════════════════════════════════════════

    'Unicorn': ArkSpeciesStats(
      hp: 340, stamina: 280, food: 1500, weight: 200, melee: 25,
      diet: _herb, taming: _pass,
    ),

    // ═══════════════════════════════════════════════════════════
    // V
    // ═══════════════════════════════════════════════════════════

    // Veilwyn — créature de mod/vote, données estimées
    'Veilwyn': ArkSpeciesStats(
      hp: 700, stamina: 350, food: 2000, weight: 300, melee: 60,
      diet: _carn, taming: _spc,
    ),

    'Velonasaur': ArkSpeciesStats(
      hp: 465, stamina: 280, food: 1200, weight: 200, melee: 50,
      diet: _carn, taming: _ko,
    ),

    'Vulture': ArkSpeciesStats(
      hp: 120, stamina: 150, food: 450, weight: 30, melee: 20,
      diet: _carn, taming: _pass, rideable: false,
    ),

    // ═══════════════════════════════════════════════════════════
    // W
    // ═══════════════════════════════════════════════════════════

    'Woolly Rhino': ArkSpeciesStats(
      hp: 900, stamina: 280, food: 1500, weight: 320, melee: 35,
      diet: _herb, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // X
    // ═══════════════════════════════════════════════════════════

    // Source ark.wiki.gg — Xiphactinus : HP 450, Stam 420, Food ?, Weight ?, Melee ?
    'Xiphactinus': ArkSpeciesStats(
      hp: 450, stamina: 420, food: 1500, weight: 200, melee: 50,
      diet: _carn, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // Y
    // ═══════════════════════════════════════════════════════════

    // Yi Ling — créature de mod/vote, données estimées
    'Yi Ling': ArkSpeciesStats(
      hp: 300, stamina: 200, food: 900, weight: 100, melee: 30,
      diet: _carn, taming: _pass, rideable: false,
    ),

    'Yutyrannus': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 350, melee: 55,
      diet: _carn, taming: _ko,
    ),

    // ═══════════════════════════════════════════════════════════
    // Z — Zombie Wyvernes (non-apprivoisables)
    // ═══════════════════════════════════════════════════════════

    'Zombie Fire Wyvern': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 82,
      diet: _carn, taming: _none, rideable: false,
    ),
    'Zombie Lightning Wyvern': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 80,
      diet: _carn, taming: _none, rideable: false,
    ),
    'Zombie Poison Wyvern': ArkSpeciesStats(
      hp: 1200, stamina: 420, food: 3000, weight: 500, melee: 75,
      diet: _carn, taming: _none, rideable: false,
    ),
  };

  // ─────────────────────────────────────────────────────────────────────────
  // API PUBLIQUE
  // ─────────────────────────────────────────────────────────────────────────

  /// Retourne les stats de base de l'espèce, ou null si inconnue.
  static ArkSpeciesStats? get(String species) => _data[species];

  /// Vérifie si les stats d'une espèce sont disponibles.
  static bool hasStats(String species) => _data.containsKey(species);

  /// Retourne les stats ou des valeurs vides si l'espèce est inconnue.
  static ArkSpeciesStats getOrEmpty(String species) =>
      _data[species] ??
      const ArkSpeciesStats(
        hp: 0, stamina: 0, food: 0, weight: 0, melee: 0,
        diet: ArkDiet.carnivore, taming: ArkTaming.ko,
      );
}
