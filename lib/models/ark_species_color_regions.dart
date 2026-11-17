// lib/models/ark_species_color_regions.dart
// Visibilité des 6 régions de couleur ARK par espèce.
// Source : assets/data/ark_species.json (via ArkDb).
// Ordre : [R0, R1, R2, R3, R4, R5]
// true  = région visible sur le modèle 3D
// false = région invisible (pas de coloration affichée)
// Ordre de résolution : _overrides (manuel) > JSON > tout visible.

import 'ark_db.dart';

class ArkSpeciesColorRegions {
  static const int regionCount = 6;

  /// Régions par défaut quand une espèce n'a pas de données.
  static const List<bool> _allVisible = [true, true, true, true, true, true];

  /// Corrections manuelles, prioritaires sur le JSON.
  /// Exemple : 'Rex': [true, true, false, false, true, true],
  static const Map<String, List<bool>> _overrides = {};

  /// Noms des régions ARK (0-5)
  static const List<String> regionNames = [
    'Région 0', 'Région 1', 'Région 2',
    'Région 3', 'Région 4', 'Région 5',
  ];

  /// Retourne la liste des 6 booléens de visibilité pour une espèce.
  /// Si l'espèce est inconnue ou sans données, toutes les régions sont visibles.
  static List<bool> visibilityFor(String species) {
    final manual = _overrides[species];
    if (manual != null) return _normalize(manual);

    final sp = ArkDb.byName(species) ?? _findIgnoreCase(species);
    final regions = sp?.regions;
    if (regions == null) return _allVisible;
    return _normalize(regions);
  }

  /// Nombre de régions visibles pour une espèce.
  static int visibleCount(String species) =>
      visibilityFor(species).where((v) => v).length;

  /// Retourne true si la région [region] est visible pour cette espèce.
  static bool isVisible(String species, int region) {
    final vis = visibilityFor(species);
    if (region < 0 || region >= vis.length) return false;
    return vis[region];
  }

  /// Espèces sans données de régions dans le JSON (affichées « tout visible »).
  /// Utile pour l'audit : ces espèces méritent une vérification.
  static List<String> get speciesWithoutRegionData =>
      ArkDb.all.where((s) => s.regions == null).map((s) => s.name).toList();

  /// Espèces dont aucune région n'est visible. Elles ne se colorent pas.
  static List<String> get speciesWithNoVisibleRegion =>
      ArkDb.all
          .where((s) => s.regions != null && !s.regions!.any((v) => v))
          .map((s) => s.name)
          .toList();

  // ─── Helpers privés ───────────────────────────────────────────────────────

  /// Garantit exactement 6 valeurs : complète par true ou tronque.
  static List<bool> _normalize(List<bool> input) {
    final out = List<bool>.generate(
      regionCount,
      (i) => i < input.length ? input[i] : true,
    );
    return List.unmodifiable(out);
  }

  /// Recherche insensible à la casse, utilisée si le nom exact n'existe pas.
  static ArkSpecies? _findIgnoreCase(String species) {
    final lower = species.toLowerCase();
    for (final s in ArkDb.all) {
      if (s.name.toLowerCase() == lower) return s;
    }
    return null;
  }
}
