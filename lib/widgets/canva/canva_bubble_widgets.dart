// lib/widgets/canva/canva_bubble_widgets.dart
//
// ╔════════════════════════════════════════════════════════════════════════╗
// ║ BRIQUES VISUELLES PARTAGÉES DU CANVA                                  ║
// ║                                                                        ║
// ║ Utilisé par :                                                          ║
// ║   - DinoCanvaScreen (mono-espèce)                                      ║
// ║   - DinoCanvaMultiScreen (multi-espèces)                               ║
// ║                                                                        ║
// ║ Tous les widgets sont publics (pas de underscore) et acceptent un      ║
// ║ exportScale propagé pour adapter tailles/bordures/typographies au      ║
// ║ rendu offscreen 1080×1350.                                             ║
// ╚════════════════════════════════════════════════════════════════════════╝
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dino.dart';
import '../../models/ark_species_color_regions.dart';
import '../../utils/dino_helpers.dart';
import '../dino_image_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  BULLE PRINCIPALE D'UN DINO
// ═══════════════════════════════════════════════════════════════════════════

class CanvaBubble extends StatelessWidget {
  final Dino dino;
  final bool isFavorite;
  final double exportScale;

  /// Si non null, affiche un petit bandeau d'espèce au-dessus de la bulle
  /// (utilisé en mode multi-espèces).
  final String? speciesTagOverride;

  const CanvaBubble({
    super.key,
    required this.dino,
    this.isFavorite = false,
    this.exportScale = 1.0,
    this.speciesTagOverride,
  });

  @override
  Widget build(BuildContext context) {
    final s = exportScale;
    final borderRadius = 12.0 * s;

    final bubbleBody = _buildBubbleBody(s, borderRadius);

    if (speciesTagOverride == null) return bubbleBody;

    // Mode multi : on empile un petit bandeau au-dessus de la bulle
    return Column(
      children: [
        SpeciesNameTag(
          species: speciesTagOverride!,
          exportScale: s,
        ),
        Expanded(child: bubbleBody),
      ],
    );
  }

  Widget _buildBubbleBody(double s, double borderRadius) {
    final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;
    final assetPath =
        'assets/images/dinos/${dino.espece.replaceAll(' ', '_')}_ASA.png';

    final innerRadius = 10.0 * s;
    final imgPadding = 6.0 * s;
    final badgeOffset = 3.0 * s;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isFavorite ? const Color(0xFFFFD700) : dino.roleColor,
          width: (isFavorite ? 3 : 2) * s,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6 * s,
            offset: Offset(0, 3 * s),
          ),
          if (isFavorite)
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              blurRadius: 10 * s,
              spreadRadius: -2 * s,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // FOND FLOUTÉ — limité à 1.1× la taille de l'image
                  Positioned.fill(
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.0,
                                colors: [
                                  dino.roleColor.withValues(alpha: 0.25),
                                  const Color(0xFF0F1115),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 1.1,
                              heightFactor: 1.1,
                              child: ClipRect(
                                child: ImageFiltered(
                                  imageFilter: ui.ImageFilter.blur(
                                    sigmaX: 18 * s,
                                    sigmaY: 18 * s,
                                  ),
                                  child: hasCustomImage
                                      ? Image.file(
                                          File(dino.image!),
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        )
                                      : Image.asset(
                                          assetPath,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.50),
                                  dino.roleColor.withValues(alpha: 0.20),
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // IMAGE NETTE
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(imgPadding),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return hasCustomImage
                              ? Image.file(
                                  File(dino.image!),
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      DinoImageWidget(
                                    species: dino.espece,
                                    regionColors: dino.colorRegions,
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    fit: BoxFit.contain,
                                    showColorBand: false,
                                    alignment: Alignment.center,
                                  ),
                                )
                              : DinoImageWidget(
                                  species: dino.espece,
                                  regionColors: dino.colorRegions,
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  fit: BoxFit.contain,
                                  showColorBand: false,
                                  alignment: Alignment.center,
                                );
                        },
                      ),
                    ),
                  ),

                  // BADGE LVL
                  Positioned(
                    top: badgeOffset,
                    left: badgeOffset,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4 * s,
                        vertical: 1.5 * s,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(3 * s),
                        border: Border.all(
                          color: DinoHelpers.getCardRarityColor(dino.niveau),
                          width: 1 * s,
                        ),
                      ),
                      child: Text(
                        'LVL ${dino.niveau}',
                        style: GoogleFonts.exo2(
                          color: DinoHelpers.getCardRarityColor(dino.niveau),
                          fontSize: 9 * s,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                  // BADGE FAVORI / SEXE
                  if (isFavorite)
                    Positioned(
                      top: badgeOffset,
                      right: badgeOffset,
                      child: Container(
                        width: 22 * s,
                        height: 22 * s,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.7),
                              blurRadius: 6 * s,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          size: 16 * s,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else if (dino.sexe != 'Inconnu')
                    Positioned(
                      top: badgeOffset,
                      right: badgeOffset,
                      child: _buildCompactSexBadge(dino, s),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: CanvaColorStrip(dino: dino, exportScale: s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSexBadge(Dino dino, double s) {
    final isBoth = dino.sexe.contains('Mâle+Femelle');
    if (isBoth) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 3 * s, vertical: 1.5 * s),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(3 * s),
          border: Border.all(color: Colors.purple, width: 1 * s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('♂',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 9 * s,
                  fontWeight: FontWeight.w900,
                  height: 1,
                )),
            Text('♀',
                style: TextStyle(
                  color: Colors.pink[300],
                  fontSize: 9 * s,
                  fontWeight: FontWeight.w900,
                  height: 1,
                )),
          ],
        ),
      );
    }
    return Container(
      width: 20 * s,
      height: 20 * s,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: dino.sexeColor, width: 1 * s),
      ),
      alignment: Alignment.center,
      child: Text(
        dino.sexeSymbol,
        style: TextStyle(
          color: dino.sexeColor,
          fontSize: 11 * s,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PETIT BANDEAU "NOM D'ESPÈCE" AU-DESSUS D'UNE BULLE (multi-espèces)
// ═══════════════════════════════════════════════════════════════════════════

class SpeciesNameTag extends StatelessWidget {
  final String species;
  final double exportScale;

  const SpeciesNameTag({
    super.key,
    required this.species,
    this.exportScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final s = exportScale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 3 * s,
        horizontal: 6 * s,
      ),
      margin: EdgeInsets.only(bottom: 3 * s),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(4 * s),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700),
            width: 1.2 * s,
          ),
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            DinoHelpers.toTitleCase(species).toUpperCase(),
            style: GoogleFonts.cinzelDecorative(
              color: const Color(0xFFFFD700),
              fontSize: 10 * s,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              height: 1,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 3 * s,
                  offset: Offset(1 * s, 1 * s),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BANDEAU TITRE GÉNÉRAL DE L'ESPÈCE (en haut du canva, mono-espèce)
// ═══════════════════════════════════════════════════════════════════════════

class SpeciesTitleBanner extends StatelessWidget {
  final String species;
  final double exportScale;

  const SpeciesTitleBanner({
    super.key,
    required this.species,
    this.exportScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final s = exportScale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 12 * s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.85),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFFFD700), width: 2 * s),
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ).createShader(b),
            child: Text(
              DinoHelpers.toTitleCase(species),
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 26 * s,
                fontWeight: FontWeight.w900,
                letterSpacing: 3 * s,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 6 * s,
                    offset: Offset(2 * s, 2 * s),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATS BUBBLE (stats communes ou favori)
// ═══════════════════════════════════════════════════════════════════════════

class StatsBubble extends StatelessWidget {
  final Dino dino;
  final String label;
  final double exportScale;

  const StatsBubble({
    super.key,
    required this.dino,
    required this.label,
    this.exportScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final s = exportScale;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: const Color(0xFFFFD700), width: 2 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            blurRadius: 10 * s,
            spreadRadius: -2 * s,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10 * s),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 4 * s),
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.exo2(
                      color: const Color(0xFFFFD700),
                      fontSize: 10 * s,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(4 * s),
                child: CanvaStatGrid(dino: dino, exportScale: s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATS GRID (3 colonnes × 2 lignes)
// ═══════════════════════════════════════════════════════════════════════════

class CanvaStatGrid extends StatelessWidget {
  final Dino dino;
  final double exportScale;

  const CanvaStatGrid({
    super.key,
    required this.dino,
    this.exportScale = 1.0,
  });

  String _intVal(int v) => v > 0 ? DinoHelpers.formatNumber(v) : '???';
  String _dmgVal(double v) => v > 0 ? '${v.toStringAsFixed(0)}%' : '???';
  int? _pts(int p) => p > 0 ? p : null;

  @override
  Widget build(BuildContext context) {
    final cells = <CanvaCellData>[
      CanvaCellData('❤️', 'VIE', _intVal(dino.hp),
          const Color(0xFF4CAF50), dino.hp == 0,
          dino.hp > 0 ? _pts(dino.hpPoints) : null),
      CanvaCellData('⚡', 'STAM', _intVal(dino.stamina),
          const Color(0xFFFFD700), dino.stamina == 0,
          dino.stamina > 0 ? _pts(dino.staminaPoints) : null),
      CanvaCellData('⚔️', 'ATK', _dmgVal(dino.degats),
          const Color(0xFFEF4444), dino.degats == 0,
          dino.degats > 0 ? _pts(dino.degatsPoints) : null),
      CanvaCellData('⚖️', 'PDS', _intVal(dino.poids),
          const Color(0xFF3B82F6), dino.poids == 0,
          dino.poids > 0 ? _pts(dino.poidsPoints) : null),
      CanvaCellData('🍖', 'FOOD', _intVal(dino.nourriture),
          const Color(0xFF8B5CF6), dino.nourriture == 0,
          dino.nourriture > 0 ? _pts(dino.nourriturePoints) : null),
      CanvaCellData('🫧', 'OXY', _intVal(dino.oxygene),
          const Color(0xFF10B981), dino.oxygene == 0,
          dino.oxygene > 0 ? _pts(dino.oxygenePoints) : null),
    ];

    final s = exportScale;
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 3, rows = 2;
        final hGap = 4.0 * s;
        final vGap = 4.0 * s;
        final cellW = (c.maxWidth - hGap * (cols - 1)) / cols;
        final cellH = (c.maxHeight - vGap * (rows - 1)) / rows;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (r) {
            return Padding(
              padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : vGap),
              child: Row(
                children: List.generate(cols, (col) {
                  final i = r * cols + col;
                  return Padding(
                    padding:
                        EdgeInsets.only(right: col == cols - 1 ? 0 : hGap),
                    child: SizedBox(
                      width: cellW,
                      height: cellH,
                      child: CanvaStatCell(data: cells[i], exportScale: s),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

class CanvaCellData {
  final String emoji, label, value;
  final Color color;
  final bool isDefault;
  final int? points;

  const CanvaCellData(
    this.emoji,
    this.label,
    this.value,
    this.color,
    this.isDefault,
    this.points,
  );
}

class CanvaStatCell extends StatelessWidget {
  final CanvaCellData data;
  final double exportScale;

  const CanvaStatCell({
    super.key,
    required this.data,
    this.exportScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final eff =
        data.isDefault ? data.color.withValues(alpha: 0.5) : data.color;
    final hasPoints = data.points != null && data.points! > 0;
    final s = exportScale;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(5 * s),
        border: Border.all(color: eff.withValues(alpha: 0.4), width: 1 * s),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: hasPoints ? 28 : 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.emoji,
                      style: TextStyle(fontSize: 12 * s, height: 1)),
                  SizedBox(width: 2 * s),
                  Text(
                    data.label,
                    style: GoogleFonts.exo2(
                      color: Colors.white
                          .withValues(alpha: data.isDefault ? 0.4 : 0.9),
                      fontSize: 10 * s,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: hasPoints ? 42 : 60,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.value,
                style: GoogleFonts.exo2(
                  color: eff,
                  fontSize: 18 * s,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 2 * s,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasPoints)
            Expanded(
              flex: 30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '+${data.points} pts',
                  style: GoogleFonts.exo2(
                    color: eff.withValues(alpha: 0.85),
                    fontSize: 9 * s,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COLOR STRIP (bande de 6 couleurs en bas de la bulle)
// ═══════════════════════════════════════════════════════════════════════════

class CanvaColorStrip extends StatelessWidget {
  final Dino dino;
  final double exportScale;

  const CanvaColorStrip({
    super.key,
    required this.dino,
    this.exportScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveDisplayColors();
    final ids = _resolveDisplayIds();
    final s = exportScale;

    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      padding: EdgeInsets.symmetric(horizontal: 4 * s, vertical: 4 * s),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const int n = 6;
          final double gap = 4 * s;
          final maxByWidth = (constraints.maxWidth - gap * (n - 1)) / n;
          final maxByHeight = constraints.maxHeight;
          final cellSize =
              maxByWidth < maxByHeight ? maxByWidth : maxByHeight;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(n, (i) {
              final hex = i < colors.length ? colors[i] : null;
              final id = i < ids.length ? ids[i] : 0;
              final parsed = DinoHelpers.parseHex(hex);
              final isFilled = parsed != null &&
                  hex != '#808080' &&
                  hex != '#7F7F7F' &&
                  id > 0;
              return Padding(
                padding: EdgeInsets.only(right: i == n - 1 ? 0 : gap),
                child: SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: CanvaColorSquare(
                    color: parsed,
                    colorId: id,
                    isFilled: isFilled,
                    exportScale: s,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  List<String?> _resolveDisplayColors() {
    final base = dino.colorRegions;
    final hasSolid = dino.tags.any((t) => t.toLowerCase() == 'solid');
    final hasVisualSolid =
        dino.tags.any((t) => t.toLowerCase() == 'visualsolid');
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

    final visibility = ArkSpeciesColorRegions.visibilityFor(dino.espece);
    return List.generate(6, (i) {
      if (hasSolid) return firstColor;
      final active = i < visibility.length ? visibility[i] : true;
      return active ? firstColor : base[i];
    });
  }

  List<int> _resolveDisplayIds() {
    final baseIds = [
      dino.colorId0,
      dino.colorId1,
      dino.colorId2,
      dino.colorId3,
      dino.colorId4,
      dino.colorId5,
    ];
    final hasSolid = dino.tags.any((t) => t.toLowerCase() == 'solid');
    final hasVisualSolid =
        dino.tags.any((t) => t.toLowerCase() == 'visualsolid');
    if (!hasSolid && !hasVisualSolid) return baseIds;

    int firstId = 0;
    for (final id in baseIds) {
      if (id > 0) {
        firstId = id;
        break;
      }
    }
    if (firstId == 0) return baseIds;

    final visibility = ArkSpeciesColorRegions.visibilityFor(dino.espece);
    return List.generate(6, (i) {
      if (hasSolid) return firstId;
      final active = i < visibility.length ? visibility[i] : true;
      return active ? firstId : baseIds[i];
    });
  }
}

class CanvaColorSquare extends StatelessWidget {
  final Color? color;
  final int colorId;
  final bool isFilled;
  final double exportScale;

  const CanvaColorSquare({
    super.key,
    required this.color,
    required this.colorId,
    required this.isFilled,
    this.exportScale = 1.0,
  });

  bool _isLight(Color c) => c.computeLuminance() > 0.5;

  @override
  Widget build(BuildContext context) {
    final s = exportScale;
    final radius = 6.0 * s;

    if (!isFilled) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6B6B6B),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8 * s,
          ),
        ),
      );
    }

    final fill = color!;
    final textColor = _isLight(fill) ? Colors.black87 : Colors.white;
    final shadowColor = _isLight(fill)
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.8);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.8 * s,
        ),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.55),
            blurRadius: 3 * s,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(2 * s),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$colorId',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(
                color: textColor,
                fontSize: 22 * s,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: 0,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(color: shadowColor, blurRadius: 1.5 * s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
