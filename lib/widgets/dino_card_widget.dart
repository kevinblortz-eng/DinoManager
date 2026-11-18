// lib/widgets/dino_card_widget.dart
// Tuile compacte horizontale utilisée dans la LISTE de la bibliothèque.
// ──────────────────────────────────────────────────────────────────────────────
// /!\ Ce fichier est DÉDIÉ à la tuile bibliothèque.
//     La Dinocard COMPLÈTE (format portrait, écran détail) se trouve dans
//     lib/widgets/ark_dino_card.dart — ne pas mélanger les deux.
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../models/role_theme.dart';
import '../models/ark_species_color_regions.dart';
import '../models/ark_species_stat.dart';
import '../utils/dino_helpers.dart';
import 'dino_image_widget.dart';

class DinoCardWidget extends StatelessWidget {
  final Dino dino;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Thème injecté depuis RoleThemeProvider — null = fallback sur dino.roleColor
  final RoleTheme? roleTheme;

  const DinoCardWidget({
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
  static const double _imageSize        = 132; // > _circleSize pour déborder

  // ── Couleurs thème ────────────────────────────────────────────────────────
  Color get _borderColor => roleTheme?.border ?? dino.roleColor;
  Color get _textColor   => roleTheme?.text   ?? dino.roleColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: _cardHeight,
        decoration: BoxDecoration(
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
  // SECTION GAUCHE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDinoSection() {
    final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;

    return SizedBox(
      width: _leftSectionWidth,
      height: _cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
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
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
  // STATS — pas de fallback espèce, ??? quand l'utilisateur n'a rien saisi
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    String intVal(int v) => v > 0 ? DinoHelpers.formatNumber(v) : '???';
    String dmgVal(double v) => v > 0 ? '${v.toStringAsFixed(0)}%' : '???';

    int? userPts(int pts) => pts > 0 ? pts : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
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
                intVal(dino.hp),
                const Color(0xFF4CAF50),
                isDefault: dino.hp == 0,
                points: dino.hp > 0 ? userPts(dino.hpPoints) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Stam',
                intVal(dino.stamina),
                const Color(0xFFFFD700),
                isDefault: dino.stamina == 0,
                points: dino.stamina > 0 ? userPts(dino.staminaPoints) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Dmg',
                dmgVal(dino.degats),
                const Color(0xFFEF4444),
                isDefault: dino.degats == 0,
                points: dino.degats > 0 ? userPts(dino.degatsPoints) : null,
              )),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCompactStat(
                'Poids',
                intVal(dino.poids),
                const Color(0xFF3B82F6),
                isDefault: dino.poids == 0,
                points: dino.poids > 0 ? userPts(dino.poidsPoints) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'Food',
                intVal(dino.nourriture),
                const Color(0xFF8B5CF6),
                isDefault: dino.nourriture == 0,
                points: dino.nourriture > 0 ? userPts(dino.nourriturePoints) : null,
              )),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat(
                'O₂',
                intVal(dino.oxygene),
                const Color(0xFF10B981),
                isDefault: dino.oxygene == 0,
                points: dino.oxygene > 0 ? userPts(dino.oxygenePoints) : null,
              )),
            ],
          ),
        ],
      ),
    );
  }

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
  // 6 COULEURS — toutes visibles sur la tuile
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

  Color? _parseHex(String? hex) => DinoHelpers.parseHex(hex);
}

// ══════════════════════════════════════════════════════════════════════════════
// CLIPPER : moitié GAUCHE en demi-cercle, moitié DROITE libre
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
    path.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.14159 / 2,
      3.14159,
    );
    path.close();
    path.addRect(Rect.fromLTRB(cx, 0, size.width + 80, size.height));
    return path;
  }

  @override
  bool shouldReclip(covariant _LeftHalfCircleRightFreeClipper old) =>
      old.circleDiameter != circleDiameter;
}
