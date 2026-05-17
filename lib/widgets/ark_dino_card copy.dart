// lib/widgets/ark_dino_card.dart
// Tuile bibliothèque — version liste horizontale épurée.
// ──────────────────────────────────────────────────────────────────────────────
// Changements vs version "portrait" :
//  • Suppression du fond image (share_card_portrait_bg.png) → fond uni sobre
//  • Layout horizontal : portrait à gauche, infos à droite
//  • Sexe → haut à droite, tag principal → sous le sexe
//  • Régime alimentaire + taming chip retirés (réservés à la Dinocard complète)
//  • 6 cases de couleur TOUJOURS toutes affichées sur la tuile
//    (le masquage par espèce reste réservé à la Dinocard complète)
//  • Image du dino qui peut déborder du cercle vers la droite
//    (effet "dino qui sort du cercle")
//  • Conservé : médaillon LVL, résolution intelligente des stats (base/auto),
//    "+X pts" investis, logique Solid/VisualSolid pour les couleurs.
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../models/role_theme.dart';
import '../models/ark_species_color_regions.dart';
import '../models/ark_species_stat.dart';
import '../utils/dino_helpers.dart';
import 'dino_image_widget.dart';

class ArkDinoCard extends StatelessWidget {
  final Dino dino;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Thème injecté depuis RoleThemeProvider — null = fallback sur dino.roleColor
  final RoleTheme? roleTheme;

  const ArkDinoCard({
    super.key,
    required this.dino,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.roleTheme,
  });

  // ── Dimensions clés (à régler ici si besoin) ──────────────────────────────
  static const double _cardHeight       = 130;
  static const double _leftSectionWidth = 120;
  static const double _circleSize       = 108;
  // L'image est plus large que le cercle pour pouvoir déborder vers la droite
  static const double _imageSize        = 132;

  // ── Couleurs thème ────────────────────────────────────────────────────────
  Color get _borderColor => roleTheme?.border ?? dino.roleColor;
  Color get _textColor   => roleTheme?.text   ?? dino.roleColor;

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: _cardHeight,
        decoration: BoxDecoration(
          // Fond uni sobre, plus de portrait_bg
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F2E), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderColor.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: _borderColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // ⚠️ Pas de ClipRRect ici : on veut autoriser le débordement de l'image
        //    du portrait vers la zone des stats (effet "dino qui sort").
        //    Les coins arrondis restent assurés par le BoxDecoration.
        child: Row(
          children: [
            _buildDinoSection(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 6),
                    Expanded(child: _buildStatsGrid()),
                    const SizedBox(height: 5),
                    _buildColorStrip(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.25),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION GAUCHE : cercle + image qui dépasse vers la droite + médaillon LVL
  // ──────────────────────────────────────────────────────────────────────────
  // Principe :
  //  1. Halo + cercle noir bordé (cadre du portrait)
  //  2. Image plus grande que le cercle, clippée en demi-cercle à gauche
  //     et LIBRE à droite (déborde dans la zone des stats)
  //  3. Médaillon LVL en bas-gauche
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDinoSection() {
    final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;

    return SizedBox(
      width: _leftSectionWidth,
      height: _cardHeight,
      child: Stack(
        clipBehavior: Clip.none, // autorise l'image à déborder visuellement
        alignment: Alignment.center,
        children: [
          // 1) Halo radial discret (au lieu d'un fond image)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    _borderColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2) Cercle noir (cadre du portrait)
          Container(
            width: _circleSize,
            height: _circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.55),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _borderColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.70),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          // 3) Image — clippée à gauche en demi-cercle, libre à droite
          Positioned.fill(
            child: ClipPath(
              clipper: _LeftHalfCircleRightFreeClipper(
                circleDiameter: _circleSize,
              ),
              child: Center(
                child: OverflowBox(
                  maxWidth: _imageSize,
                  maxHeight: _imageSize,
                  child: SizedBox(
                    width: _imageSize,
                    height: _imageSize,
                    child: hasCustomImage
                        ? Image.file(
                            File(dino.image!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildDinoImageFlipped(_imageSize),
                          )
                        : _buildDinoImageFlipped(_imageSize),
                  ),
                ),
              ),
            ),
          ),

          // 4) Médaillon LVL — coin bas-gauche
          Positioned(
            bottom: 4,
            left: 4,
            child: _buildLvlBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildDinoImageFlipped(double sz) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
      child: DinoImageWidget(
        species: dino.espece,
        regionColors: _resolveDisplayColors(),
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        showColorBand: false,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildLvlBadge() {
    final c = DinoHelpers.getCardRarityColor(dino.niveau);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.88),
        border: Border.all(color: c, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.60),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LVL',
            style: GoogleFonts.exo2(
              color: c.withValues(alpha: 0.80),
              fontSize: 5.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            '${dino.niveau}',
            style: GoogleFonts.exo2(
              color: c,
              fontSize: dino.niveau >= 1000 ? 8.0 : 10.0,
              fontWeight: FontWeight.w900,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER : nom + espèce à gauche, sexe + tag à droite (empilés)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bloc gauche : nom + espèce
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dino.nom,
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                DinoHelpers.toTitleCase(dino.espece),
                style: GoogleFonts.cinzelDecorative(
                  color: const Color(0xFFE8C97A),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Bloc droit : sexe en haut, tag principal en dessous
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dino.sexe != 'Inconnu') _buildSexBadge(),
            if (dino.sexe != 'Inconnu') const SizedBox(height: 3),
            _buildPrimaryTag(),
          ],
        ),
      ],
    );
  }

  Widget _buildSexBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: dino.sexeColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: dino.sexeColor.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: Text(
        dino.sexeSymbol,
        style: TextStyle(
          color: dino.sexeColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }

  /// Tag principal affiché à droite : on prend le PREMIER tag s'il existe,
  /// sinon on retombe sur le rôle du dino (comportement de la version "avant").
  Widget _buildPrimaryTag() {
    final hasTag = dino.tags.isNotEmpty;
    final label  = hasTag ? dino.tags.first : dino.role;
    final color  = hasTag ? _tagColor(dino.tags.first) : _textColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          height: 1.0,
        ),
      ),
    );
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'boss':         return const Color(0xFFEF4444);
      case 'breeding':
      case 'breed':        return const Color(0xFFF48FB1);
      case 'solid':        return const Color(0xFFFFD700);
      case 'visualsolid':  return const Color(0xFFFFD700);
      case 'farm':         return const Color(0xFF4CAF50);
      case 'collection':   return const Color(0xFF8B5CF6);
      case 'combat':       return const Color(0xFFFF6B00);
      case 'jokermut':     return const Color(0xFF22D3EE);
      case 'monstermut':   return const Color(0xFF22D3EE);
      default:             return _textColor;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS : 2 lignes × 3 colonnes — fond uni sombre, lisible
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    final baseStats = ArkSpeciesStatsDb.get(dino.espece);

    String resolveStatValue(int dinoVal, int? baseVal) {
      if (dinoVal > 0) return DinoHelpers.formatNumber(dinoVal);
      if (baseVal != null && baseVal > 0) {
        return '~${DinoHelpers.formatNumber(baseVal)}';
      }
      return '-';
    }

    String resolveDmgValue(double dinoVal, double? baseVal) {
      if (dinoVal > 0) return '${dinoVal.toStringAsFixed(0)}%';
      if (baseVal != null && baseVal > 0) {
        return '~${baseVal.toStringAsFixed(0)}%';
      }
      return '-';
    }

    bool isDefault(int v) => v == 0;
    bool isDefaultD(double v) => v == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        // Fond opaque sobre : remplace définitivement le "portail"
        color: const Color(0xFF0B0F17),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Expanded(child: _buildCompactStat(
                'HP',
                resolveStatValue(dino.hp, baseStats?.hp),
                const Color(0xFF4CAF50),
                isDefault: isDefault(dino.hp),
                points: dino.hp > 0
                    ? _resolvePoints(dino.hpPoints, dino.hp, baseStats?.hp)
                    : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Stam',
                resolveStatValue(dino.stamina, baseStats?.stamina),
                const Color(0xFFFFD700),
                isDefault: isDefault(dino.stamina),
                points: dino.stamina > 0
                    ? _resolvePoints(
                        dino.staminaPoints, dino.stamina, baseStats?.stamina)
                    : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Dmg',
                resolveDmgValue(dino.degats, baseStats?.melee),
                const Color(0xFFEF4444),
                isDefault: isDefaultD(dino.degats),
                points: dino.degats > 0 ? dino.degatsPoints : null,
              )),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCompactStat(
                'Poids',
                resolveStatValue(dino.poids, baseStats?.weight),
                const Color(0xFF3B82F6),
                isDefault: isDefault(dino.poids),
                points: dino.poids > 0
                    ? _resolvePoints(
                        dino.poidsPoints, dino.poids, baseStats?.weight)
                    : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Food',
                resolveStatValue(dino.nourriture, baseStats?.food),
                const Color(0xFF8B5CF6),
                isDefault: isDefault(dino.nourriture),
                points: dino.nourriture > 0
                    ? _resolvePoints(
                        dino.nourriturePoints,
                        dino.nourriture,
                        baseStats?.food)
                    : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'O₂',
                resolveStatValue(dino.oxygene, baseStats?.oxygen),
                const Color(0xFF10B981),
                isDefault: isDefault(dino.oxygene),
                points: dino.oxygene > 0
                    ? _resolvePoints(
                        dino.oxygenePoints,
                        dino.oxygene,
                        baseStats?.oxygen)
                    : null,
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Résolution inverse des points investis (inchangée).
  int? _resolvePoints(int storedPoints, int dinoVal, int? baseVal) {
    if (storedPoints > 0) return storedPoints;
    if (baseVal == null || baseVal == 0) return null;
    final diff = dinoVal - baseVal;
    if (diff <= 0) return 0;
    final pts = (diff / (baseVal * 0.1)).round();
    return pts > 0 ? pts : null;
  }

  Widget _buildCompactStat(
    String label,
    String value,
    Color color, {
    bool isDefault = false,
    int? points,
  }) {
    final effectiveColor = isDefault ? color.withValues(alpha: 0.45) : color;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.exo2(
                  color: Colors.white
                      .withValues(alpha: isDefault ? 0.40 : 0.75),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                value,
                style: GoogleFonts.exo2(
                  color: effectiveColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
          if (points != null && points > 0)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '+$points pts',
                style: GoogleFonts.exo2(
                  color: effectiveColor.withValues(alpha: 0.65),
                  fontSize: 5.5,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BANDE DE COULEURS — 6 cases TOUJOURS visibles sur la tuile
  // ──────────────────────────────────────────────────────────────────────────
  // /!\ La logique ArkSpeciesColorRegions.visibilityFor(...) qui masque les
  // zones inactives est volontairement RETIRÉE ici. Elle reste utilisée par
  // la Dinocard complète (écran détail).
  // En revanche, on conserve _resolveDisplayColors() qui gère Solid/VisualSolid.
  // ══════════════════════════════════════════════════════════════════════════
  List<String?> _resolveDisplayColors() {
    final base = dino.colorRegions;

    final hasSolid       = dino.tags.any((t) => t.toLowerCase() == 'solid');
    final hasVisualSolid = dino.tags.any((t) => t.toLowerCase() == 'visualsolid');

    if (!hasSolid && !hasVisualSolid) return base;

    String? firstColor;
    for (final c in base) {
      if (c != null &&
          c.toUpperCase().replaceAll('#', '') != '808080' &&
          c.toUpperCase().replaceAll('#', '') != '7F7F7F') {
        firstColor = c;
        break;
      }
    }
    if (firstColor == null) return base;

    // Pour la coloration de l'IMAGE, on respecte encore la visibilité par espèce
    // (sinon on essaierait de colorer une région inexistante du modèle 3D).
    final visibility = ArkSpeciesColorRegions.visibilityFor(dino.espece);
    return List.generate(6, (i) {
      if (hasSolid) return firstColor;
      final active = i < visibility.length ? visibility[i] : true;
      return active ? firstColor : base[i];
    });
  }

  Widget _buildColorStrip() {
    final colors = _resolveDisplayColors();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(6, (i) {
          final hex = i < colors.length ? colors[i] : null;
          final parsed = _parseHex(hex);
          // Couleur grise neutre si absente/non définie — pas de masquage.
          final isNeutral = parsed == null ||
              hex == '#808080' ||
              hex == '#7F7F7F';
          final color = isNeutral ? const Color(0xFF2A2F3A) : parsed;

          return Expanded(
            child: Container(
              height: 10,
              margin: EdgeInsets.only(right: i < 5 ? 2 : 0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: isNeutral ? 0.08 : 0.30,
                  ),
                  width: 0.5,
                ),
                boxShadow: isNeutral
                    ? null
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 2,
                        ),
                      ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color? _parseHex(String? hex) => DinoHelpers.parseHex(hex);
}

// ══════════════════════════════════════════════════════════════════════════════
// CLIPPER : moitié GAUCHE clippée en demi-cercle, moitié DROITE libre
// ──────────────────────────────────────────────────────────────────────────────
// Permet à l'image du dino de "sortir" du cercle côté droit (vers les stats),
// tout en restant proprement délimitée par le bord circulaire à gauche.
// ══════════════════════════════════════════════════════════════════════════════
class _LeftHalfCircleRightFreeClipper extends CustomClipper<Path> {
  final double circleDiameter;
  const _LeftHalfCircleRightFreeClipper({required this.circleDiameter});

  @override
  Path getClip(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = circleDiameter / 2;

    final path = Path();

    // Moitié gauche du cercle (demi-disque)
    path.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.14159 / 2,  // début à 90° (bas)
      3.14159,      // 180° dans le sens horaire → arc gauche
    );
    path.close();

    // Moitié droite : rectangle libre (peut largement déborder)
    path.addRect(Rect.fromLTRB(cx, 0, size.width + 80, size.height));

    return path;
  }

  @override
  bool shouldReclip(covariant _LeftHalfCircleRightFreeClipper old) =>
      old.circleDiameter != circleDiameter;
}
