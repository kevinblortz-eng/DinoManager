import 'ark_db.dart';

class ArkSpeciesData {
  /// Toutes les espèces sélectionnables (source : ark_species.json).
  /// Une espèce sans image reste sélectionnable : vérifier avec hasImage.
  static List<String> get speciesWithImages =>
      ArkDb.all.map((s) => s.name).toList();

  /// Espèces qui possèdent un masque de coloration (_ASA_m.png).
  static Set<String> get speciesWithMasks =>
      ArkDb.all.where((s) => s.hasMask).map((s) => s.name).toSet();

  /// Chemin de l'image de base, ou null si l'espèce n'a pas d'image.
  static String? getImageAssetPath(String species) {
    final sp = ArkDb.byName(species);
    if (sp == null || !sp.hasImage) return null;
    return sp.imagePath;
  }

  /// Chemin du masque, ou null si l'espèce n'a pas de masque.
  static String? getMaskAssetPath(String species) {
    final sp = ArkDb.byName(species);
    if (sp == null || !sp.hasMask) return null;
    return sp.maskPath;
  }

  /// Vérifier si une espèce a une image.
  static bool hasImage(String species) => ArkDb.byName(species)?.hasImage ?? false;

  /// Vérifier si une espèce a un masque.
  static bool hasMask(String species) => ArkDb.byName(species)?.hasMask ?? false;
}
