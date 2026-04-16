import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';
import '../widgets/common/dino_stat_grid.dart';
import '../utils/dino_helpers.dart';

class DinoVariantsScreen extends StatelessWidget {
  final Dino baseDino;
  final List<Dino> selectedVariants;

  const DinoVariantsScreen({
    super.key,
    required this.baseDino,
    required this.selectedVariants,
  });

  @override
  Widget build(BuildContext context) {
    final dinoCount = selectedVariants.length;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: bottomPadding > 0 ? 8 : 24,
          ),
          child: Column(
            children: [
              Expanded(
                flex: dinoCount <= 2 ? 5 : 4,
                child: _buildVariantsGrid(dinoCount),
              ),
              const SizedBox(height: 16),
              _buildSpeciesTitle(),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: _buildCommonStats(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GRILLE ADAPTATIVE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVariantsGrid(int count) {
    if (count == 0) return _buildVariantCard(baseDino, isLarge: true);
    if (count == 1) {
      return _buildVariantCard(selectedVariants[0], isLarge: true);
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildVariantCard(selectedVariants[0])),
          const SizedBox(width: 8),
          Expanded(child: _buildVariantCard(selectedVariants[1])),
        ],
      );
    }

    if (count == 3) {
      return Column(
        children: [
          Expanded(
            child: _buildVariantCard(selectedVariants[0], isLarge: true),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildVariantCard(selectedVariants[1])),
                const SizedBox(width: 8),
                Expanded(child: _buildVariantCard(selectedVariants[2])),
              ],
            ),
          ),
        ],
      );
    }

    if (count == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildVariantCard(selectedVariants[0])),
                const SizedBox(width: 8),
                Expanded(child: _buildVariantCard(selectedVariants[1])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildVariantCard(selectedVariants[2])),
                const SizedBox(width: 8),
                Expanded(child: _buildVariantCard(selectedVariants[3])),
              ],
            ),
          ),
        ],
      );
    }

    if (count == 5) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildVariantCard(selectedVariants[0])),
                const SizedBox(width: 8),
                Expanded(child: _buildVariantCard(selectedVariants[1])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildVariantCard(selectedVariants[2])),
                const SizedBox(width: 8),
                Expanded(child: _buildVariantCard(selectedVariants[3])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildVariantCard(selectedVariants[4], isLarge: true),
          ),
        ],
      );
    }

    // 6 variantes
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildVariantCard(selectedVariants[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildVariantCard(selectedVariants[1])),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildVariantCard(selectedVariants[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildVariantCard(selectedVariants[3])),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildVariantCard(selectedVariants[4])),
              const SizedBox(width: 8),
              Expanded(child: _buildVariantCard(selectedVariants[5])),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARTE INDIVIDUELLE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVariantCard(Dino variantDino, {bool isLarge = false}) {
    final hasCustomImage =
        variantDino.image != null && variantDino.image!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: variantDino.roleColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Zone image + badges
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    variantDino.roleColor.withValues(alpha: 0.15),
                    const Color(0xFF0F1115),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return hasCustomImage
                              ? Image.file(
                                  File(variantDino.image!),
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildDinoImageWidget(
                                    variantDino,
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  ),
                                )
                              : _buildDinoImageWidget(
                                  variantDino,
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                        },
                      ),
                    ),
                  ),
                  // Badge niveau
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: DinoHelpers.getCardRarityColor(
                            variantDino.niveau,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'LVL ${variantDino.niveau}',
                        style: GoogleFonts.exo2(
                          color: DinoHelpers.getCardRarityColor(
                            variantDino.niveau,
                          ),
                          fontSize: isLarge ? 11 : 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  // Badge sexe
                  if (variantDino.sexe != 'Inconnu')
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _buildCompactSexBadge(variantDino, isLarge),
                    ),
                ],
              ),
            ),
          ),
          // Bande de couleurs
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(10)),
                border: Border(
                  top: BorderSide(color: Color(0xFF3A3A3A), width: 1),
                ),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: List.generate(6, (i) {
                  final id = DinoHelpers.getColorId(variantDino, i);
                  final hex = DinoHelpers.getColorHex(variantDino, i);
                  final isActive =
                      id > 0 && hex != '#808080' && hex != '#7F7F7F';
                  final color = isActive
                      ? DinoHelpers.parseHex(hex)
                      : const Color(0xFF2A2A2A);

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color!.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isActive ? '$id' : '-',
                          style: TextStyle(
                            color: isActive
                                ? (DinoHelpers.isLight(color!)
                                    ? Colors.black87
                                    : Colors.white)
                                : Colors.white.withValues(alpha: 0.3),
                            fontSize: isLarge ? 14 : 12,
                            fontWeight: FontWeight.w900,
                            shadows: isActive
                                ? [
                                    Shadow(
                                      color: DinoHelpers.isLight(color!)
                                          ? Colors.white
                                              .withValues(alpha: 0.8)
                                          : Colors.black
                                              .withValues(alpha: 0.8),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget image avec taille explicite
  Widget _buildDinoImageWidget(Dino dino, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dino.roleColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: DinoImageWidget(
        species: dino.espece,
        regionColors: dino.colorRegions,
        width: width,
        height: height,
        fit: BoxFit.contain,
        showColorBand: false,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildCompactSexBadge(Dino dino, bool isLarge) {
    final isBoth = dino.sexe.contains('Mâle+Femelle');

    if (isBoth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.purple, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '♂',
              style: TextStyle(
                color: Colors.blue[300],
                fontSize: isLarge ? 10 : 8,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '♀',
              style: TextStyle(
                color: Colors.pink[300],
                fontSize: isLarge ? 10 : 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: isLarge ? 24 : 20,
      height: isLarge ? 24 : 20,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: dino.sexeColor, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        dino.sexeSymbol,
        style: TextStyle(
          color: dino.sexeColor,
          fontSize: isLarge ? 12 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TITRE ESPÈCE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSpeciesTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ).createShader(bounds),
          child: Text(
            DinoHelpers.toTitleCase(baseDino.espece),
            style: GoogleFonts.cinzelDecorative(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS COMMUNES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCommonStats() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: baseDino.roleColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF5A5A5A), width: 1),
              ),
            ),
            child: Text(
              'Stats Communes',
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DinoStatGrid(dino: baseDino),
            ),
          ),
        ],
      ),
    );
  }
}
