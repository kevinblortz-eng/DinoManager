import 'package:flutter/material.dart';
import '../models/dino.dart';

/// Centralise tous les helpers partagés : couleurs, formatage, stats.
/// Évite la duplication de _hexToColor / _parseHex dans chaque widget.
class DinoHelpers {

  // ─── Localisation ──────────────────────────────────────────────────────────

  /// Map les valeurs internes de sexe aux clés i18n
  static String sexeToL10nKey(String sexe) {
    return switch (sexe) {
      'Mâle' => 'sexMale',
      'Femelle' => 'sexFemale',
      'Mâle+Femelle' => 'sexMaleFemale',
      _ => 'sexUnknown',
    };
  }

  /// Retourne la liste des valeurs possibles pour le sexe (avec clés i18n)
  static List<String> sexeOptionsL10n() => [
    'sexUnknown',
    'sexMale',
    'sexFemale',
    'sexMaleFemale',
  ];

  // ─── Formatage ────────────────────────────────────────────────────────────

  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Formate un grand nombre : 12500 → "12.5k", 1200000 → "1.2m"
  static String formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  // ─── Couleurs ─────────────────────────────────────────────────────────────

  /// Parse une chaîne "#RRGGBB" ou "#AARRGGBB" en Color Flutter.
  /// Retourne null si invalide.
  static Color? parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return null;
  }

  /// Variante non-nullable : retourne Colors.grey en cas d'échec.
  static Color hexToColor(String hex) => parseHex(hex) ?? Colors.grey;

  /// Vrai si la couleur est claire (luminance > 0.5).
  static bool isLight(Color color) => color.computeLuminance() > 0.5;

  /// Couleur de texte adaptée au fond (noir sur fond clair, blanc sur fond sombre).
  static Color contrastText(Color background) =>
      isLight(background) ? Colors.black87 : Colors.white;

  // ─── Accès aux couleurs régionales d'un dino ──────────────────────────────

  static int getColorId(Dino dino, int index) {
    switch (index) {
      case 0: return dino.colorId0;
      case 1: return dino.colorId1;
      case 2: return dino.colorId2;
      case 3: return dino.colorId3;
      case 4: return dino.colorId4;
      case 5: return dino.colorId5;
      default: return 0;
    }
  }

  static String getColorHex(Dino dino, int index) {
    switch (index) {
      case 0: return dino.colorHex0;
      case 1: return dino.colorHex1;
      case 2: return dino.colorHex2;
      case 3: return dino.colorHex3;
      case 4: return dino.colorHex4;
      case 5: return dino.colorHex5;
      default: return '#808080';
    }
  }

  /// Vérifie si une région est "active" (non-grise).
  static bool isColorActive(String hex) =>
      hex != '#808080' && hex != '#7F7F7F' && hex.isNotEmpty;

  // ─── Rareté / niveau ──────────────────────────────────────────────────────

  static Color getCardRarityColor(int niveau) {
    if (niveau >= 362) return const Color(0xFFFFD700);  // Or
    if (niveau >= 222) return const Color(0xFFC0C0C0);  // Argent
    if (niveau >= 150) return const Color(0xFFCD7F32);  // Bronze
    return const Color(0xFF8E8E93);                      // Commun
  }

  // ─── Statistiques globales ────────────────────────────────────────────────

  static Map<String, int> getRoleDistribution(List<Dino> dinos) {
    final dist = <String, int>{};
    for (final d in dinos) {
      dist[d.role] = (dist[d.role] ?? 0) + 1;
    }
    return dist;
  }

  static Map<String, int> getSexDistribution(List<Dino> dinos) {
    final dist = <String, int>{};
    for (final d in dinos) {
      dist[d.sexe] = (dist[d.sexe] ?? 0) + 1;
    }
    return dist;
  }

  static Dino? getHighestLevelDino(List<Dino> dinos) {
    if (dinos.isEmpty) return null;
    return dinos.reduce((a, b) => a.niveau > b.niveau ? a : b);
  }
}
