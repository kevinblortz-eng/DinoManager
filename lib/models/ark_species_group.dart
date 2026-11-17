// lib/models/ark_species_group.dart
// Groupe d'espèce ARK — détermine le fond interactif de la DinoCard.
// Ordre de résolution : _overrides (manuel) > type du JSON > terrestre.

import 'ark_db.dart';

enum ArkSpeciesGroup { terrestre, aquatic, volant, fantastic, compagnon }

class ArkSpeciesGroupData {
  // ─── API publique ─────────────────────────────────────────────────────────

  /// Retourne le groupe d'une espèce.
  /// Priorité : correction manuelle, puis type du JSON, puis terrestre.
  static ArkSpeciesGroup groupFor(String species) {
    final manual = _overrides[species];
    if (manual != null) return manual;
    return ArkDb.byName(species)?.type ?? ArkSpeciesGroup.terrestre;
  }

  /// Emoji représentant le groupe
  static String groupEmoji(ArkSpeciesGroup g) {
    switch (g) {
      case ArkSpeciesGroup.terrestre:
        return '🦕';
      case ArkSpeciesGroup.aquatic:
        return '🌊';
      case ArkSpeciesGroup.volant:
        return '🦅';
      case ArkSpeciesGroup.fantastic:
        return '✨';
      case ArkSpeciesGroup.compagnon:
        return '🐾';
    }
  }

  /// Label lisible du groupe
  static String groupLabel(ArkSpeciesGroup g) {
    switch (g) {
      case ArkSpeciesGroup.terrestre:
        return 'Terrestre';
      case ArkSpeciesGroup.aquatic:
        return 'Aquatique';
      case ArkSpeciesGroup.volant:
        return 'Volant';
      case ArkSpeciesGroup.fantastic:
        return 'Fantastique';
      case ArkSpeciesGroup.compagnon:
        return 'Compagnon';
    }
  }

  // ─── Corrections manuelles (prioritaires sur le JSON) ─────────────────────
  // Ajoute ici uniquement les espèces à corriger. Exemple : 'Leedsichthys': ArkSpeciesGroup.aquatic,
  static const Map<String, ArkSpeciesGroup> _overrides = {
    // Types à confirmer avant usage
    'Leedsichthys': ArkSpeciesGroup.aquatic,
    'Lamprey': ArkSpeciesGroup.aquatic,
    'Leech': ArkSpeciesGroup.aquatic,
    'Kairuku': ArkSpeciesGroup.aquatic,
  };
}
