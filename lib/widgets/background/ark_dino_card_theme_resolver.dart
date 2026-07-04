// lib/widgets/background/ark_dino_card_theme_resolver.dart
//
// Résolveur central des thèmes de DinoCard.
// Permet d'associer automatiquement un ArkDinoCardBackgroundStyle
// à un Dino selon des règles déclaratives (espèce, groupe, tag, etc.).
//
// Ajoutez vos propres styles dans la table `_themes` et vos règles dans
// `resolveStyle(...)`. La première règle qui matche gagne.

import 'package:flutter/material.dart';
import '../../models/dino.dart';
import '../../models/ark_species_group.dart';
import 'ark_dino_card_background.dart';

/// Identifiants symboliques des thèmes (ajoutez-en autant que voulu).
enum ArkCardTheme {
  goldDark,    // défaut — or sombre
  silver,      // argent
  oceanBlue,   // exemple : bleu océan (aquatiques)
  emerald,     // exemple : vert émeraude (compagnons)
  crimson,     // exemple : rouge sang (boss)
  obsidian,    // exemple : noir+violet (collection)
}

/// Catalogue de tous les styles disponibles.
/// Pour créer un nouveau thème, ajoutez une entrée ici.
class ArkDinoCardThemes {
  ArkDinoCardThemes._();

  static final Map<ArkCardTheme, ArkDinoCardBackgroundStyle> _themes = {
    ArkCardTheme.goldDark: ArkDinoCardBackgroundStyle.goldDark,
    //
    ArkCardTheme.silver: ArkDinoCardBackgroundStyle.silver,
    //
    ArkCardTheme.oceanBlue: ArkDinoCardBackgroundStyle(
      gradientColors: const [
        Color(0xFF0A1A2E),
        Color(0xFF1B3A5B),
        Color(0xFF051120),
      ],
      haloOuterColor: const Color(0xFF7FD4FF),
      haloInnerColor: const Color(0xFF3FA7E6),
      haloGlowColor: const Color(0x667FD4FF),
      bannerColorLight: const Color(0xFFB8E4FF),
      bannerColorDark: const Color(0xFF2C7CB8),
      bannerColorBack: const Color(0xFF1A4A75),
      bannerBorderColor: const Color(0xFF0A2540),
      nameBannerBorder: const Color(0xFF3FA7E6),
      statCellBorder: const Color(0x663FA7E6),
      statCellGlowColor: const Color(0x447FD4FF),
    ),
    //
    ArkCardTheme.emerald: ArkDinoCardBackgroundStyle(
      gradientColors: const [
        Color(0xFF0A1F12),
        Color(0xFF1F3A28),
        Color(0xFF06140C),
      ],
      haloOuterColor: const Color(0xFF7FE6A8),
      haloInnerColor: const Color(0xFF3FB870),
      haloGlowColor: const Color(0x667FE6A8),
      bannerColorLight: const Color(0xFFB8F0CC),
      bannerColorDark: const Color(0xFF2C8A4F),
      bannerColorBack: const Color(0xFF1A5A33),
      bannerBorderColor: const Color(0xFF0A2814),
      nameBannerBorder: const Color(0xFF3FB870),
      statCellBorder: const Color(0x663FB870),
      statCellGlowColor: const Color(0x447FE6A8),
    ),
    //
    ArkCardTheme.crimson: ArkDinoCardBackgroundStyle(
      gradientColors: const [
        Color(0xFF1F0808),
        Color(0xFF3A1414),
        Color(0xFF140505),
      ],
      haloOuterColor: const Color(0xFFFF6B6B),
      haloInnerColor: const Color(0xFFCC3333),
      haloGlowColor: const Color(0x66FF6B6B),
      bannerColorLight: const Color(0xFFFFB3B3),
      bannerColorDark: const Color(0xFF8A2020),
      bannerColorBack: const Color(0xFF5A1414),
      bannerBorderColor: const Color(0xFF280808),
      nameBannerBorder: const Color(0xFFCC3333),
      statCellBorder: const Color(0x66CC3333),
      statCellGlowColor: const Color(0x44FF6B6B),
    ),
    //
    ArkCardTheme.obsidian: ArkDinoCardBackgroundStyle(
      gradientColors: const [
        Color(0xFF0F0820),
        Color(0xFF24143A),
        Color(0xFF05030D),
      ],
      haloOuterColor: const Color(0xFFB37FE6),
      haloInnerColor: const Color(0xFF7F3FB8),
      haloGlowColor: const Color(0x66B37FE6),
      bannerColorLight: const Color(0xFFD4B8F0),
      bannerColorDark: const Color(0xFF5A2C8A),
      bannerColorBack: const Color(0xFF3A1A5A),
      bannerBorderColor: const Color(0xFF140828),
      nameBannerBorder: const Color(0xFF7F3FB8),
      statCellBorder: const Color(0x667F3FB8),
      statCellGlowColor: const Color(0x44B37FE6),
    ),
  };

  /// Récupère le style associé à un identifiant de thème.
  static ArkDinoCardBackgroundStyle of(ArkCardTheme theme) {
    return _themes[theme] ?? _themes[ArkCardTheme.goldDark]!;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RÉSOLVEUR — règles déclaratives
// ═══════════════════════════════════════════════════════════════════════════

/// Détermine quel thème appliquer à un Dino donné.
///
/// Les règles sont évaluées dans l'ordre ; la première qui retourne un
/// thème non-null gagne. Modifiez `resolveTheme()` pour ajouter / réordonner.
class ArkDinoCardThemeResolver {
  ArkDinoCardThemeResolver._();

  /// Permet à l'application de forcer un thème global (override utilisateur).
  /// Si défini, ignore toutes les règles automatiques.
  static ArkCardTheme? globalOverride;

  /// Résolution principale : passe un Dino, reçoit un thème.
  static ArkCardTheme resolveTheme(Dino dino) {
    if (globalOverride != null) return globalOverride!;

    // ── RÈGLE 1 : Tag explicite "boss" → rouge sang ──────────────────
    final tagsLower = dino.tags.map((t) => t.toLowerCase()).toList();
    if (tagsLower.contains('boss')) return ArkCardTheme.crimson;

    // ── RÈGLE 2 : Tag "collection" → obsidian violet ─────────────────
    if (tagsLower.contains('collection')) return ArkCardTheme.obsidian;

    // ── RÈGLE 3 : Groupe d'espèce → couleur thématique ───────────────
    try {
      final group = ArkSpeciesGroupData.groupFor(dino.espece);
      switch (group) {
        case ArkSpeciesGroup.aquatic:
          return ArkCardTheme.oceanBlue;
        case ArkSpeciesGroup.compagnon:
          return ArkCardTheme.emerald;
        case ArkSpeciesGroup.volant:
        case ArkSpeciesGroup.fantastic:
        case ArkSpeciesGroup.terrestre:
          break; // tombera sur le défaut
      }
    } catch (_) {}

    // ── DÉFAUT : or sombre ────────────────────────────────────────────
    return ArkCardTheme.goldDark;
  }

  /// Raccourci : retourne directement le style appliqué.
  static ArkDinoCardBackgroundStyle resolveStyle(Dino dino) {
    return ArkDinoCardThemes.of(resolveTheme(dino));
  }
}
