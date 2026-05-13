// lib/widgets/ark_dino_card.dart
// DinoCard redesignée — fond portrait (share_card_portrait_bg.png)
// Layout calqué sur DinoShareCardPortrait :
//   ovale dino (haut) → parchemin espèce → bandeau nom/tags → 2×3 stats → bande couleurs

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

  // Thème injecté depuis RoleThemeProvider — null = comportement actuel
  final RoleTheme? roleTheme;

  const ArkDinoCard({
    super.key,
    required this.dino,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.roleTheme,
  });

  // ── Couleurs thème ─────────────────────────────────────────────────────────
  Color get _borderColor => roleTheme?.border ?? dino.roleColor;
  Color get _textColor   => roleTheme?.text   ?? dino.roleColor;

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL — carte portrait avec fond image
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        // Hauteur fixe portrait-style (ratio approximatif 607:1077 → ~0.5×)
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: _borderColor.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 0. FOND IMAGE ───────────────────────────────────────────
              _buildBackground(),

              // ── 1. CONTENU principal ────────────────────────────────────
              _buildContent(),

              // ── 2. Chevron tap indicator ────────────────────────────────
              Positioned(
                right: 6,
                bottom: 34,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Fond ──────────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Image.asset(
      'assets/images/ui/share_card_portrait_bg.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1F2E),
              Color.lerp(
                  const Color(0xFF1A1F2E), const Color(0xFF111827), 0.6)!,
            ],
          ),
        ),
      ),
    );
  }

  // ── Layout principal — colonne gauche (dino) + droite (infos) ────────────
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colonne gauche : image dino dans cadre oval
          _buildDinoSection(),
          const SizedBox(width: 6),
          // Colonne droite : toutes les infos texte
          Expanded(child: _buildInfoColumn()),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION GAUCHE — image dino
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDinoSection() {
    final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;
    const size = 116.0;

    return SizedBox(
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo lumineux
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _borderColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.70),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Cercle fond semi-transparent (simule l'ovale du fond image)
          Container(
            width: size - 4,
            height: size - 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.50),
                width: 1.5,
              ),
            ),
          ),
          // Image
          ClipOval(
            child: SizedBox(
              width: size - 8,
              height: size - 8,
              child: hasCustomImage
                  ? Image.file(
                      File(dino.image!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDinoImageFlipped(size - 8),
                    )
                  : _buildDinoImageFlipped(size - 8),
            ),
          ),
          // Médaillon LVL — coin bas-gauche
          Positioned(
            bottom: 2,
            left: 2,
            child: _buildLvlBadge(),
          ),
          // Badge sexe — coin haut-droit
          if (dino.sexe != 'Inconnu')
            Positioned(
              top: 2,
              right: 2,
              child: _buildSexBadge(),
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
              color: c.withValues(alpha: 0.60), blurRadius: 8, spreadRadius: 1),
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

  Widget _buildSexBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
          fontSize: 10,
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLONNE DROITE — toutes les infos
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Espèce (style parchemin) ──
        _buildSpeciesScroll(),
        const SizedBox(height: 3),
        // ── Nom + tags ──
        _buildNameBand(),
        const SizedBox(height: 4),
        // ── Diet chip ──
        _buildDietChip(),
        const SizedBox(height: 4),
        // ── Grille 2×3 stats ──
        Expanded(child: _buildStatsGrid()),
        const SizedBox(height: 3),
        // ── Bande couleurs ──
        _buildColorStrip(),
      ],
    );
  }

  // ── Parchemin espèce ──────────────────────────────────────────────────────
  Widget _buildSpeciesScroll() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5A3).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFD4A843).withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Text(
        DinoHelpers.toTitleCase(dino.espece),
        style: GoogleFonts.cinzelDecorative(
          color: const Color(0xFFE8C97A),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          height: 1.0,
          decoration: TextDecoration.none,
          shadows: const [
            Shadow(color: Color(0x88000000), blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Bandeau nom + tags ────────────────────────────────────────────────────
  Widget _buildNameBand() {
    return Row(
      children: [
        Expanded(
          child: Text(
            dino.nom,
            style: GoogleFonts.exo2(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              height: 1.0,
              decoration: TextDecoration.none,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.70),
                  blurRadius: 4,
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        _buildTagsRow(),
      ],
    );
  }

  Widget _buildTagsRow() {
    final tags = dino.tags.take(3).toList();
    if (tags.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tags.map((tag) {
        final tagColor = _tagColor(tag);
        return Container(
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: tagColor.withValues(alpha: 0.55), width: 1),
          ),
          child: Text(
            tag.toUpperCase(),
            style: TextStyle(
              color: tagColor,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              decoration: TextDecoration.none,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'boss':        return const Color(0xFFEF4444);
      case 'breeding':    return const Color(0xFFF48FB1);
      case 'solid':       return const Color(0xFFFFD700);
      case 'visualsolid': return const Color(0xFFFFD700);
      case 'farm':        return const Color(0xFF4CAF50);
      case 'collection':  return const Color(0xFF8B5CF6);
      case 'combat':      return const Color(0xFFFF6B00);
      default:            return _textColor;
    }
  }

  // ── Chip régime alimentaire ───────────────────────────────────────────────
  Widget _buildDietChip() {
    final stats = ArkSpeciesStatsDb.get(dino.espece);
    if (stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: _dietColor(stats.diet).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: _dietColor(stats.diet).withValues(alpha: 0.50),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stats.dietEmoji,
                style: const TextStyle(fontSize: 8, height: 1.0),
              ),
              const SizedBox(width: 3),
              Text(
                stats.dietLabel.toUpperCase(),
                style: TextStyle(
                  color: _dietColor(stats.diet),
                  fontSize: 6.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        // Taming chip compact
        if (stats.taming != ArkTaming.nonTameable) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Text(
              stats.tamingLabel.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 6.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _dietColor(ArkDiet diet) {
    switch (diet) {
      case ArkDiet.carnivore:  return const Color(0xFFEF5350);
      case ArkDiet.herbivore:  return const Color(0xFF66BB6A);
      case ArkDiet.omnivore:   return const Color(0xFFFF9800);
      case ArkDiet.special:    return const Color(0xFFAB47BC);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GRILLE STATS 2×3
  // Affiche les stats du dino, ou les stats de base si le dino = 0
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    final baseStats = ArkSpeciesStatsDb.get(dino.espece);

    // Résoudre la valeur à afficher :
    // Si la stat du dino est 0 → afficher la stat de base (grisée)
    String _resolveStatValue(int dinoVal, int? baseVal) {
      if (dinoVal > 0) return DinoHelpers.formatNumber(dinoVal);
      if (baseVal != null && baseVal > 0) return '~${DinoHelpers.formatNumber(baseVal)}';
      return '-';
    }

    String _resolveDmgValue(double dinoVal, double? baseVal) {
      if (dinoVal > 0) return '${dinoVal.toStringAsFixed(0)}%';
      if (baseVal != null && baseVal > 0) return '~${baseVal.toStringAsFixed(0)}%';
      return '-';
    }

    bool _isDefault(int dinoVal) => dinoVal == 0;
    bool _isDefaultDouble(double dinoVal) => dinoVal == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
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
                _resolveStatValue(dino.hp, baseStats?.hp),
                const Color(0xFF4CAF50),
                isDefault: _isDefault(dino.hp),
                points: dino.hp > 0 ? _resolvePoints(dino.hpPoints, dino.hp, baseStats?.hp) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Stam',
                _resolveStatValue(dino.stamina, baseStats?.stamina),
                const Color(0xFFFFD700),
                isDefault: _isDefault(dino.stamina),
                points: dino.stamina > 0 ? _resolvePoints(dino.staminaPoints, dino.stamina, baseStats?.stamina) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Dmg',
                _resolveDmgValue(dino.degats, baseStats?.melee),
                const Color(0xFFEF4444),
                isDefault: _isDefaultDouble(dino.degats),
                points: dino.degats > 0 ? dino.degatsPoints : null,
              )),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCompactStat(
                'Poids',
                _resolveStatValue(dino.poids, baseStats?.weight),
                const Color(0xFF3B82F6),
                isDefault: _isDefault(dino.poids),
                points: dino.poids > 0 ? _resolvePoints(dino.poidsPoints, dino.poids, baseStats?.weight) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Food',
                _resolveStatValue(dino.nourriture, baseStats?.food),
                const Color(0xFF8B5CF6),
                isDefault: _isDefault(dino.nourriture),
                points: dino.nourriture > 0 ? _resolvePoints(dino.nourriturePoints, dino.nourriture, baseStats?.food) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'O₂',
                _resolveStatValue(dino.oxygene, baseStats?.oxygen),
                const Color(0xFF10B981),
                isDefault: _isDefault(dino.oxygene),
                points: dino.oxygene > 0 ? _resolvePoints(dino.oxygenePoints, dino.oxygene, baseStats?.oxygen) : null,
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Résolution inverse des points investis :
  /// Si points == 0 mais valeur > base connue → déduire les points investis.
  /// Formula ARK (approximative) : points ≈ (valeur - base) / (base * 0.1)
  int? _resolvePoints(int storedPoints, int dinoVal, int? baseVal) {
    if (storedPoints > 0) return storedPoints;
    if (baseVal == null || baseVal == 0) return null;
    // Auto-calcul inversé : (valeur - base) / (base * multiplicateur)
    // Multiplicateur ARK taming = 0.1 (10% par niveau)
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
                  color: Colors.white.withValues(alpha: isDefault ? 0.40 : 0.70),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                ' ',
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.30),
                  fontSize: 7.5,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.exo2(
                  color: effectiveColor,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          // Points investis — petit badge sous la valeur
          if (points != null && points > 0)
            Text(
              '+$points pts',
              style: GoogleFonts.exo2(
                color: effectiveColor.withValues(alpha: 0.65),
                fontSize: 5.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BANDE DE COULEURS
  // ══════════════════════════════════════════════════════════════════════════
  List<String?> _resolveDisplayColors() {
    final base = dino.colorRegions;

    final hasSolid      = dino.tags.any((t) => t.toLowerCase() == 'solid');
    final hasVisualSolid = dino.tags.any((t) => t.toLowerCase() == 'visualsolid');

    if (!hasSolid && !hasVisualSolid) return base;

    // Trouver la première couleur réelle (non grise, non nulle)
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

  Widget _buildColorStrip() {
    final colors     = _resolveDisplayColors();
    final visibility = ArkSpeciesColorRegions.visibilityFor(dino.espece);

    return Container(
      padding: const EdgeInsets.all(2),
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
          final isZoneActive = i < visibility.length ? visibility[i] : true;

          // Zone inactive pour cette espèce → case transparente
          if (!isZoneActive) {
            return Expanded(
              child: Container(
                height: 7,
                margin: EdgeInsets.only(right: i < 5 ? 1 : 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 0.5,
                  ),
                ),
              ),
            );
          }

          final hex = i < colors.length ? colors[i] : null;
          final isInactive = hex == null || hex == '#808080' || hex == '#7F7F7F';
          final color = isInactive
              ? const Color(0xFF1F2937)
              : _parseHex(hex) ?? const Color(0xFF1F2937);

          return Expanded(
            child: Container(
              height: 7,
              margin: EdgeInsets.only(right: i < 5 ? 1 : 0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color:
                      Colors.white.withValues(alpha: isInactive ? 0.05 : 0.25),
                  width: 0.5,
                ),
                boxShadow: !isInactive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
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
