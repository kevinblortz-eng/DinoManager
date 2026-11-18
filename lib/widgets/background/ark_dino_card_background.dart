// lib/widgets/background/ark_dino_card_background.dart
//
// Fond entier de la DinoCard généré uniquement par du code.
//   • Dégradé diagonal noir → gris anthracite → noir
//   • Halo doré ovoïde (vraie forme d'œuf, symétrique, allongé)
//   • Bannière dorée avec pans repliés en diagonale bas-arrière
//   • Petite bannière pour le nom du dino
//   • 6 cases de stats avec halo lumineux léger sous chacune
//
// Référentiel logique : 242 × 428 px.

import 'package:material_ui/material_ui.dart';

// ═══════════════════════════════════════════════════════════════════════════
// STYLE
// ═══════════════════════════════════════════════════════════════════════════
class ArkDinoCardBackgroundStyle {
  // Dégradé principal
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Alignment gradientBegin;
  final Alignment gradientEnd;

  // Halo doré (cadre œuf)
  final Color haloOuterColor;
  final Color haloInnerColor;
  final double haloOuterWidth;
  final double haloInnerWidth;
  final double haloGlowBlur;
  final Color haloGlowColor;

  // Forme de l'œuf (coord. référentiel 242×428)
  final double ovalCx;
  final double ovalCy;
  final double ovalW;     // largeur max
  final double ovalH;     // hauteur totale
  final double ovalGap;   // écart entre lignes ext/int

  // Bannière titre (espèce)
  final double bannerCx;
  final double bannerCy;
  final double bannerW;   // largeur du corps central
  final double bannerH;
  final double bannerTailLen;   // longueur des pans (en px réf.)
  final double bannerTailDrop;  // descente verticale des pans
  final double bannerFoldDepth; // profondeur du pli d'ombre
  final Color bannerColorLight;
  final Color bannerColorDark;
  final Color bannerColorBack;  // couleur des pans repliés (plus sombre)
  final Color bannerBorderColor;

  // Petite bannière du nom
  final double nameBannerCx;
  final double nameBannerCy;
  final double nameBannerW;
  final double nameBannerH;
  final Color nameBannerFill;
  final Color nameBannerBorder;

  // Cases de stats
  final double statCellW;
  final double statCellH;
  final double statCellRadius;
  final Color statCellFill;
  final Color statCellBorder;
  final Color statCellGlowColor;
  final double statCellGlowBlur;
  final List<Offset> statCellCenters;

  ArkDinoCardBackgroundStyle({
    this.gradientColors = const [
      Color(0xFF111418),
      Color(0xFF24272C),
      Color(0xFF0C0E11),
    ],
    this.gradientStops = const [0.0, 0.55, 1.0],
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    //
    this.haloOuterColor = const Color(0xFFE6C36A),
    this.haloInnerColor = const Color(0xFFC9A24A),
    this.haloOuterWidth = 2.2,
    this.haloInnerWidth = 1.4,
    this.haloGlowBlur = 8.0,
    this.haloGlowColor = const Color(0x66E6C36A),
    //
    this.ovalCx = 123,
    this.ovalCy = 135,
    this.ovalW = 170,   // plus étroit → forme ovoïde verticale
    this.ovalH = 250,   // bien plus haut que large
    this.ovalGap = 6.0,
    //
    this.bannerCx = 123,
    this.bannerCy = 230,
    this.bannerW = 150,           // corps central plus étroit
    this.bannerH = 32,
    this.bannerTailLen = 38,      // pans plus courts (restent dans le cadre)
    this.bannerTailDrop = 10,     // descente diagonale vers le bas
    this.bannerFoldDepth = 6,     // petit triangle d'ombre seulement
    this.bannerColorLight = const Color(0xFFF6D87A),
    this.bannerColorDark = const Color(0xFFB8862E),
    this.bannerColorBack = const Color(0xFF7A5818), // pans plus sombres
    this.bannerBorderColor = const Color(0xFF4A3210),
    //
    this.nameBannerCx = 123,
    this.nameBannerCy = 258,
    this.nameBannerW = 140,
    this.nameBannerH = 20,
    this.nameBannerFill = const Color(0xCC1A1A1A),
    this.nameBannerBorder = const Color(0xFFC9A24A),
    //
    this.statCellW = 64,
    this.statCellH = 56,
    this.statCellRadius = 8,
    this.statCellFill = const Color(0xCC1C1F24),
    this.statCellBorder = const Color(0x66C9A24A),
    this.statCellGlowColor = const Color(0x44E6C36A),
    this.statCellGlowBlur = 10.0,
    List<Offset>? statCellCenters,
  }) : statCellCenters = statCellCenters ??
            const [
              Offset(48, 305),
              Offset(123, 305),
              Offset(200, 305),
              Offset(48, 365),
              Offset(125, 365),
              Offset(200, 365),
            ];

  static ArkDinoCardBackgroundStyle get goldDark =>
      ArkDinoCardBackgroundStyle();

  static ArkDinoCardBackgroundStyle get silver => ArkDinoCardBackgroundStyle(
        haloOuterColor: const Color(0xFFE6E6E6),
        haloInnerColor: const Color(0xFFB8B8B8),
        haloGlowColor: const Color(0x66CFCFCF),
        bannerColorLight: const Color(0xFFEDEDED),
        bannerColorDark: const Color(0xFF8A8A8A),
        bannerColorBack: const Color(0xFF555555),
        bannerBorderColor: const Color(0xFF2A2A2A),
        nameBannerBorder: const Color(0xFFB8B8B8),
        statCellBorder: const Color(0x66CFCFCF),
        statCellGlowColor: const Color(0x44CFCFCF),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class ArkDinoCardBackground extends StatelessWidget {
  final ArkDinoCardBackgroundStyle? style;
  final double refW;
  final double refH;

  const ArkDinoCardBackground({
    super.key,
    this.style,
    this.refW = 242,
    this.refH = 428,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? ArkDinoCardBackgroundStyle.goldDark;
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ArkDinoCardBackgroundPainter(
            style: effectiveStyle,
            refW: refW,
            refH: refH,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _ArkDinoCardBackgroundPainter extends CustomPainter {
  final ArkDinoCardBackgroundStyle style;
  final double refW;
  final double refH;

  _ArkDinoCardBackgroundPainter({
    required this.style,
    required this.refW,
    required this.refH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final scale = size.width / refW;

    _paintGradient(canvas, size);
    _paintStatCellsGlowAndBoxes(canvas, scale);
    _paintEggHalo(canvas, scale);
    _paintBanner(canvas, scale);
    _paintNameBanner(canvas, scale);
  }

  // 1. Dégradé
  void _paintGradient(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: style.gradientBegin,
        end: style.gradientEnd,
        colors: style.gradientColors,
        stops: style.gradientStops,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  // 2. Halo œuf — ovale symétrique allongé verticalement
  //    Pas de forme asymétrique cette fois : un vrai ovale bien fermé,
  //    plus haut que large (rapport ~1:1.5), tel que sur la référence.
  void _paintEggHalo(Canvas canvas, double scale) {
    final cx = style.ovalCx * scale;
    final cy = style.ovalCy * scale;
    final w = style.ovalW * scale;
    final h = style.ovalH * scale;
    final gap = style.ovalGap * scale;

    final outerRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: w,
      height: h,
    );
    final innerRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: w - gap * 2,
      height: h - gap * 2,
    );

    // Glow externe diffus
    final glowPaint = Paint()
      ..color = style.haloGlowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (style.haloOuterWidth + 5) * scale
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, style.haloGlowBlur * scale);
    canvas.drawOval(outerRect, glowPaint);

    // Ligne extérieure
    final outerLine = Paint()
      ..color = style.haloOuterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.haloOuterWidth * scale;
    canvas.drawOval(outerRect, outerLine);

    // Ligne intérieure
    final innerLine = Paint()
      ..color = style.haloInnerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.haloInnerWidth * scale;
    canvas.drawOval(innerRect, innerLine);

    // Glow interne subtil
    final innerGlow = Paint()
      ..color = style.haloGlowColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale);
    canvas.drawOval(innerRect, innerGlow);
  }

  // 3. Bannière dorée avec pans repliés en diagonale bas-arrière
  void _paintBanner(Canvas canvas, double scale) {
    final cx = style.bannerCx * scale;
    final cy = style.bannerCy * scale;
    final w = style.bannerW * scale;
    final h = style.bannerH * scale;

    final left = cx - w / 2;
    final right = cx + w / 2;
    final top = cy - h / 2;
    final bottom = cy + h / 2;

    final tailLen = style.bannerTailLen * scale;
    final tailDrop = style.bannerTailDrop * scale; // descente diagonale
    final foldDepth = style.bannerFoldDepth * scale;
    final notch = h * 0.30; // encoche en V plus petite

    // ── 1) PAN GAUCHE — part du corps, descend en diagonale vers gauche-bas
    final leftTailTopX = left;
    final leftTailTopY = top + h * 0.10;
    final leftTailBotX = left;
    final leftTailBotY = bottom - h * 0.10;

    final leftTailFarTopX = left - tailLen;
    final leftTailFarTopY = top + tailDrop;            // descendu
    final leftTailFarBotX = left - tailLen;
    final leftTailFarBotY = bottom + tailDrop;         // descendu
    final leftTailNotchX = left - tailLen + notch;
    final leftTailNotchY = (leftTailFarTopY + leftTailFarBotY) / 2;

    final leftTailPath = Path()
      ..moveTo(leftTailTopX, leftTailTopY)
      ..lineTo(leftTailFarTopX, leftTailFarTopY)
      ..lineTo(leftTailNotchX, leftTailNotchY)
      ..lineTo(leftTailFarBotX, leftTailFarBotY)
      ..lineTo(leftTailBotX, leftTailBotY)
      ..close();

    // Couleur des pans repliés = plus sombre (bannerColorBack)
    final leftTailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          style.bannerColorBack,
          style.bannerColorBack.withOpacity(0.7),
        ],
      ).createShader(
        Rect.fromLTRB(leftTailFarTopX, leftTailFarTopY,
            leftTailTopX, leftTailFarBotY),
      );
    canvas.drawPath(leftTailPath, leftTailPaint);

    final tailBorderPaint = Paint()
      ..color = style.bannerBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    canvas.drawPath(leftTailPath, tailBorderPaint);

    // Petit triangle de PLI à gauche (ombre courte)
    final leftFoldPath = Path()
      ..moveTo(left, top)
      ..lineTo(left + foldDepth, top + h * 0.20)
      ..lineTo(left + foldDepth, bottom - h * 0.20)
      ..lineTo(left, bottom)
      ..close();
    final foldPaint = Paint()
      ..color = Colors.black.withOpacity(0.45);
    canvas.drawPath(leftFoldPath, foldPaint);

    // ── 2) PAN DROIT (symétrique)
    final rightTailTopX = right;
    final rightTailTopY = top + h * 0.10;
    final rightTailBotX = right;
    final rightTailBotY = bottom - h * 0.10;

    final rightTailFarTopX = right + tailLen;
    final rightTailFarTopY = top + tailDrop;
    final rightTailFarBotX = right + tailLen;
    final rightTailFarBotY = bottom + tailDrop;
    final rightTailNotchX = right + tailLen - notch;
    final rightTailNotchY = (rightTailFarTopY + rightTailFarBotY) / 2;

    final rightTailPath = Path()
      ..moveTo(rightTailTopX, rightTailTopY)
      ..lineTo(rightTailFarTopX, rightTailFarTopY)
      ..lineTo(rightTailNotchX, rightTailNotchY)
      ..lineTo(rightTailFarBotX, rightTailFarBotY)
      ..lineTo(rightTailBotX, rightTailBotY)
      ..close();

    final rightTailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          style.bannerColorBack,
          style.bannerColorBack.withOpacity(0.7),
        ],
      ).createShader(
        Rect.fromLTRB(rightTailTopX, rightTailFarTopY,
            rightTailFarTopX, rightTailFarBotY),
      );
    canvas.drawPath(rightTailPath, rightTailPaint);
    canvas.drawPath(rightTailPath, tailBorderPaint);

    // Petit triangle de PLI à droite
    final rightFoldPath = Path()
      ..moveTo(right, top)
      ..lineTo(right - foldDepth, top + h * 0.20)
      ..lineTo(right - foldDepth, bottom - h * 0.20)
      ..lineTo(right, bottom)
      ..close();
    canvas.drawPath(rightFoldPath, foldPaint);

    // ── 3) CORPS CENTRAL (par-dessus les plis)
    final bodyRectRaw = Rect.fromLTRB(left, top, right, bottom);
    final bodyRect = RRect.fromRectAndRadius(
      bodyRectRaw,
      Radius.circular(3 * scale),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          style.bannerColorLight,
          style.bannerColorDark,
        ],
      ).createShader(bodyRectRaw);
    canvas.drawRRect(bodyRect, bodyPaint);

    final borderPaint = Paint()
      ..color = style.bannerBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(bodyRect, borderPaint);

    // Reflet horizontal
    final shineRect = Rect.fromLTRB(
      left + 4 * scale,
      top + 2 * scale,
      right - 4 * scale,
      top + h * 0.35,
    );
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.45),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(shineRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shineRect, Radius.circular(2 * scale)),
      shinePaint,
    );
  }

  // 4. Petite bannière du nom
  void _paintNameBanner(Canvas canvas, double scale) {
    final cx = style.nameBannerCx * scale;
    final cy = style.nameBannerCy * scale;
    final w = style.nameBannerW * scale;
    final h = style.nameBannerH * scale;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      Radius.circular(h / 2),
    );

    final fillPaint = Paint()..color = style.nameBannerFill;
    canvas.drawRRect(rect, fillPaint);

    final glowPaint = Paint()
      ..color = style.nameBannerBorder.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);
    canvas.drawRRect(rect, glowPaint);

    final borderPaint = Paint()
      ..color = style.nameBannerBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    canvas.drawRRect(rect, borderPaint);
  }

  // 5. Cases stats
  void _paintStatCellsGlowAndBoxes(Canvas canvas, double scale) {
    for (final center in style.statCellCenters) {
      final cx = center.dx * scale;
      final cy = center.dy * scale;
      final w = style.statCellW * scale;
      final h = style.statCellH * scale;

      final rectRaw = Rect.fromCenter(
        center: Offset(cx, cy),
        width: w,
        height: h,
      );
      final rrect = RRect.fromRectAndRadius(
        rectRaw,
        Radius.circular(style.statCellRadius * scale),
      );

      final glowPaint = Paint()
        ..color = style.statCellGlowColor
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, style.statCellGlowBlur * scale);
      canvas.drawRRect(rrect, glowPaint);

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            style.statCellFill,
            style.statCellFill.withOpacity(0.85),
          ],
        ).createShader(rectRaw);
      canvas.drawRRect(rrect, fillPaint);

      final borderPaint = Paint()
        ..color = style.statCellBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArkDinoCardBackgroundPainter old) =>
      old.style != style || old.refW != refW || old.refH != refH;
}
