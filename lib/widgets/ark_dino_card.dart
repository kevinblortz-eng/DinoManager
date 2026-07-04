// lib/widgets/ark_dino_card.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../models/role_theme.dart';
import '../models/ark_species_color_regions.dart';
import '../utils/dino_helpers.dart';
import 'dino_image_widget.dart';
import 'background/ark_dino_card_background.dart';
import 'background/ark_dino_card_theme_resolver.dart';

class ArkDinoCard extends StatelessWidget {
  final Dino dino;
  final RoleTheme? roleTheme;

  /// Permet de forcer un thème spécifique (preview, démo, etc.).
  /// Si null, le thème est résolu automatiquement via
  /// [ArkDinoCardThemeResolver.resolveTheme].
  final ArkCardTheme? themeOverride;

  const ArkDinoCard({
    super.key,
    required this.dino,
    this.roleTheme,
    this.themeOverride,
  });

  static const double _refW = 242;
  static const double _refH = 428;

  Color get _themeColor => roleTheme?.text ?? dino.roleColor;

  ArkDinoCardBackgroundStyle get _resolvedStyle {
    if (themeOverride != null) return ArkDinoCardThemes.of(themeOverride!);
    return ArkDinoCardThemeResolver.resolveStyle(dino);
  }

   @override
  Widget build(BuildContext context) {
    // Force la cohérence app ↔ export : ignore le réglage système
    // "taille de texte" qui sinon casserait le layout pixel-perfect.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: AspectRatio(
        aspectRatio: _refW / _refH,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final scale = w / _refW;

            return Stack(
              clipBehavior: Clip.none,
              children: [
              // ── 0. FOND ENTIÈREMENT GÉNÉRÉ PAR CODE (thème auto) ────────
              Positioned.fill(
                child: ArkDinoCardBackground(style: _resolvedStyle),
              ),

              // ── 1. IMAGE DINO ──────────────────────────────────────────
              _positionedCentered(
                cx: 123, cy: 130, w: 165, h: 210,
                scale: scale,
                child: _buildEggImage(),
              ),

              // ── 2. MÉDAILLON LVL ───────────────────────────────────────
              _positionedCentered(
                cx: 30, cy: 35, w: 32, h: 32,
                scale: scale,
                child: _buildLvlBadge(scale),
              ),

              // ── 3. BADGE SEXE ──────────────────────────────────────────
              if (dino.sexe != 'Inconnu')
                _positionedCentered(
                  cx: 215, cy: 36, w: 32, h: 32,
                  scale: scale,
                  child: _buildSexBadge(scale),
                ),

              // ── 4. PARCHEMIN ESPÈCE (à y=230 pour matcher la bannière) ─
              _positionedCentered(
                cx: 123, cy: 230, w: 145, h: 28,
                scale: scale,
                child: _buildSpeciesText(scale),
              ),

              // ── 5. PARCHEMIN NOM + TAG (à y=258) ───────────────────────
              _positionedCentered(
                cx: 123, cy: 258, w: 130, h: 16,
                scale: scale,
                child: _buildNameAndTag(scale),
              ),

              // ── 6. STATS GRID (y=305 et y=365) ─────────────────────────
              ..._buildAllStatCells(scale),

              // ── 7. CARRÉS DE COULEUR (y=408) ───────────────────────────
              ..._buildAllColorSquares(scale),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _positionedCentered({
    required double cx,
    required double cy,
    required double w,
    required double h,
    required double scale,
    required Widget child,
  }) {
    return Positioned(
      left: (cx - w / 2) * scale,
      top: (cy - h / 2) * scale,
      width: w * scale,
      height: h * scale,
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // IMAGE DINO + DOUBLE HALO FLOU
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEggImage() {
    final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;

    Widget rawImage() {
      return hasCustomImage
          ? Image.file(
              File(dino.image!),
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => _buildSpeciesImage(),
            )
          : _buildSpeciesImage();
    }

    Widget blurredCopy({
      required double sigma,
      required double opacity,
      required double scale,
      Color? tint,
    }) {
      Widget child = rawImage();
      if (tint != null) {
        child = ColorFiltered(
          colorFilter: ColorFilter.mode(tint, BlendMode.srcATop),
          child: child,
        );
      }
      return IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.decal,
            ),
            child: Transform.scale(scale: scale, child: child),
          ),
        ),
      );
    }

    // Teinte du halo large = couleur extérieure du halo doré du thème
    final haloTint = _resolvedStyle.haloOuterColor;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _OvalGlowPainter(
                glowColor: Colors.black.withOpacity(0.45),
                edgeColor: Colors.transparent,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: blurredCopy(
            sigma: 22,
            opacity: 0.25,
            scale: 1.30,
            tint: haloTint,
          ),
        ),
        Positioned.fill(
          child: blurredCopy(
            sigma: 8,
            opacity: 0.45,
            scale: 1.08,
          ),
        ),
        Positioned.fill(child: rawImage()),
      ],
    );
  }

  Widget _buildSpeciesImage() {
    return DinoImageWidget(
      species: dino.espece,
      regionColors: _resolveDisplayColors(),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      showColorBand: false,
      alignment: Alignment.center,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BADGES
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLvlBadge(double scale) {
    final c = DinoHelpers.getCardRarityColor(dino.niveau);
    final clamped = scale.clamp(1.0, 3.5);
    final fontLvl = 6.0 * clamped;
    final fontNum = (dino.niveau >= 1000 ? 9.0 : 11.0) * clamped;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.55),
        border: Border.all(color: c, width: 1.5 * scale.clamp(1.0, 2.5)),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.6),
            blurRadius: 6 * scale.clamp(1.0, 3.0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LVL',
            style: GoogleFonts.exo2(
              color: c.withOpacity(0.85),
              fontSize: fontLvl,
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
              fontSize: fontNum,
              fontWeight: FontWeight.w900,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexBadge(double scale) {
    final clamped = scale.clamp(1.0, 3.5);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dino.sexeColor.withOpacity(0.22),
        shape: BoxShape.circle,
        border: Border.all(
          color: dino.sexeColor.withOpacity(0.75),
          width: 1.5 * scale.clamp(1.0, 2.5),
        ),
        boxShadow: [
          BoxShadow(
            color: dino.sexeColor.withOpacity(0.45),
            blurRadius: 6 * scale.clamp(1.0, 3.0),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            dino.sexeSymbol,
            style: TextStyle(
              color: dino.sexeColor,
              fontSize: 14 * clamped,
              fontWeight: FontWeight.w900,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEXTES
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSpeciesText(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = DinoHelpers.toTitleCase(dino.espece);
          const double maxFont = 20.0;
          const double minFont = 10.0;
          final style = GoogleFonts.cinzelDecorative(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            height: 1.0,
          );
          double fontSize = maxFont;
          while (fontSize > minFont) {
            final tp = TextPainter(
              text: TextSpan(
                text: text,
                style: style.copyWith(fontSize: fontSize),
              ),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout();
            if (tp.width <= constraints.maxWidth &&
                tp.height <= constraints.maxHeight) {
              break;
            }
            fontSize -= 0.5;
          }
          return Center(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style.copyWith(
                fontSize: fontSize,
                color: const Color.fromARGB(255, 0, 0, 0),
                decoration: TextDecoration.none,
                shadows: const [
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 1.5,
                    offset: Offset(0, 0.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNameAndTag(double scale) {
    final hasTag = dino.tags.isNotEmpty;
    final tagLbl = hasTag ? dino.tags.first : null;
    final tagCol = hasTag ? _tagColor(tagLbl!) : _themeColor;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dino.nom,
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.0,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.7),
                    blurRadius: 2,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (tagLbl != null) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: tagCol.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: tagCol.withOpacity(0.7),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  tagLbl.toUpperCase(),
                  style: TextStyle(
                    color: tagCol,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'boss':        return const Color(0xFFEF4444);
      case 'breeding':
      case 'breed':       return const Color(0xFFF48FB1);
      case 'solid':       return const Color(0xFFFFD700);
      case 'visualsolid': return const Color(0xFFFFD700);
      case 'farm':        return const Color(0xFF4CAF50);
      case 'collection':  return const Color(0xFF8B5CF6);
      case 'combat':      return const Color(0xFFFF6B00);
      case 'jokermut':    return const Color(0xFF22D3EE);
      case 'monstermut':  return const Color(0xFF22D3EE);
      default:            return _themeColor;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllStatCells(double scale) {
    String intVal(int v) => v > 0 ? DinoHelpers.formatNumber(v) : '???';
    String dmgVal(double v) => v > 0 ? '${v.toStringAsFixed(0)}%' : '???';
    int? userPts(int pts) => pts > 0 ? pts : null;

    final cells = <_StatCellData>[
      _StatCellData(
        cx: 48, cy: 305,
        emoji: '❤️', label: 'VIE',
        value: intVal(dino.hp),
        color: const Color(0xFF4CAF50),
        isDefault: dino.hp == 0,
        points: dino.hp > 0 ? userPts(dino.hpPoints) : null,
      ),
      _StatCellData(
        cx: 123, cy: 305,
        emoji: '⚡', label: 'STAM',
        value: intVal(dino.stamina),
        color: const Color(0xFFFFD700),
        isDefault: dino.stamina == 0,
        points: dino.stamina > 0 ? userPts(dino.staminaPoints) : null,
      ),
      _StatCellData(
        cx: 200, cy: 305,
        emoji: '⚔️', label: 'ATTACK',
        value: dmgVal(dino.degats),
        color: const Color(0xFFEF4444),
        isDefault: dino.degats == 0,
        points: dino.degats > 0 ? userPts(dino.degatsPoints) : null,
      ),
      _StatCellData(
        cx: 48, cy: 365,
        emoji: '⚖️', label: 'POIDS',
        value: intVal(dino.poids),
        color: const Color(0xFF3B82F6),
        isDefault: dino.poids == 0,
        points: dino.poids > 0 ? userPts(dino.poidsPoints) : null,
      ),
      _StatCellData(
        cx: 125, cy: 365,
        emoji: '🍖', label: 'FOOD',
        value: intVal(dino.nourriture),
        color: const Color(0xFF8B5CF6),
        isDefault: dino.nourriture == 0,
        points: dino.nourriture > 0 ? userPts(dino.nourriturePoints) : null,
      ),
      _StatCellData(
        cx: 200, cy: 365,
        emoji: '🫧', label: 'OXY',
        value: intVal(dino.oxygene),
        color: const Color(0xFF10B981),
        isDefault: dino.oxygene == 0,
        points: dino.oxygene > 0 ? userPts(dino.oxygenePoints) : null,
      ),
    ];

    return cells.map((c) {
      return _positionedCentered(
        cx: c.cx, cy: c.cy, w: 50, h: 47,
        scale: scale,
        child: _buildStatCell(c, scale),
      );
    }).toList();
  }

  Widget _buildStatCell(_StatCellData c, double scale) {
    final effColor = c.isDefault ? c.color.withOpacity(0.50) : c.color;

    const double rowLabel = 13.0;
    const double rowValue = 18.0;
    const double rowPoints = 12.0;

    String pointsText = '';
    Color pointsColor = Colors.transparent;
    if (c.points != null) {
      if (c.points == -1) {
        pointsText = '??? pts';
        pointsColor = Colors.white.withOpacity(0.55);
      } else if (c.points! > 0) {
        pointsText = '+${c.points} pts';
        pointsColor = effColor.withOpacity(0.85);
      } else {
        pointsText = '+0 pts';
        pointsColor = effColor.withOpacity(0.85);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 2 * scale,
        vertical: 1 * scale,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: rowLabel * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.emoji,
                      style: const TextStyle(fontSize: 15, height: 1.0)),
                  const SizedBox(width: 2),
                  Text(
                    c.label,
                    style: GoogleFonts.exo2(
                      color: Colors.white
                          .withOpacity(c.isDefault ? 0.45 : 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: rowValue * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                c.value,
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  color: effColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: rowPoints * scale,
            child: pointsText.isEmpty
                ? const SizedBox.shrink()
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      pointsText,
                      style: GoogleFonts.exo2(
                        color: pointsColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CARRÉS COULEURS (y=408)
  // ═══════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllColorSquares(double scale) {
    final colors = _resolveDisplayColors();
    final ids = _resolveDisplayIds();
    final xs = [34.0, 69.0, 105.0, 140.0, 176.0, 211.0];

    return List.generate(6, (i) {
      final hex = i < colors.length ? colors[i] : null;
      final id = i < ids.length ? ids[i] : 0;
      final parsed = _parseHex(hex);
      final isFilled = parsed != null &&
          hex != '#808080' &&
          hex != '#7F7F7F' &&
          id > 0;

      return _positionedCentered(
        cx: xs[i], cy: 408, w: 22, h: 22,
        scale: scale,
        child: _buildColorSquare(
          color: parsed,
          colorId: id,
          isFilled: isFilled,
          scale: scale,
        ),
      );
    });
  }

  Widget _buildColorSquare({
    required Color? color,
    required int colorId,
    required bool isFilled,
    required double scale,
  }) {
    const double radius = 6.0;

    if (!isFilled) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6B6B6B),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 0.8,
          ),
        ),
      );
    }

    final fill = color!;
    final textColor = _isLight(fill) ? Colors.black87 : Colors.white;
    final shadowColor = _isLight(fill)
        ? Colors.white.withOpacity(0.8)
        : Colors.black.withOpacity(0.8);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: fill.withOpacity(0.55),
            blurRadius: 3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(1.5),
          child: Text(
            '$colorId',
            style: GoogleFonts.exo2(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: 0,
              decoration: TextDecoration.none,
              shadows: [
                Shadow(color: shadowColor, blurRadius: 1.5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isLight(Color c) => c.computeLuminance() > 0.5;

  // ═══════════════════════════════════════════════════════════════════════
  // Solid / VisualSolid
  // ═══════════════════════════════════════════════════════════════════════
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

  Color? _parseHex(String? hex) => DinoHelpers.parseHex(hex);
}

class _StatCellData {
  final double cx, cy;
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final bool isDefault;
  final int? points;

  _StatCellData({
    required this.cx,
    required this.cy,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.isDefault,
    required this.points,
  });
}

class _OvalGlowPainter extends CustomPainter {
  final Color glowColor;
  final Color edgeColor;

  _OvalGlowPainter({required this.glowColor, required this.edgeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.7,
        colors: [
          glowColor,
          glowColor.withOpacity(glowColor.opacity * 0.4),
          edgeColor,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.95,
      height: size.height * 0.98,
    );
    canvas.drawOval(ovalRect, paint);
  }

  @override
  bool shouldRepaint(covariant _OvalGlowPainter old) =>
      old.glowColor != glowColor || old.edgeColor != edgeColor;
}
