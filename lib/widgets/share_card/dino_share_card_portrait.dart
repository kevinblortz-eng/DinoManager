// lib/widgets/share_card/dino_share_card_portrait.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dino.dart';
import '../../models/role_theme.dart';
import '../../models/ark_species_color_regions.dart';
import '../../models/ark_species_stat.dart';
import '../../utils/dino_helpers.dart';
import '../../widgets/dino_image_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SHARE CARD PORTRAIT — 607 × 1077
//  Fond : assets/images/ui/share_card_portrait_bg.png
//
//  Structure verticale (mesurée sur le fond) :
//    [0..542]   Ovale dino
//    [522..600] Parchemin espèce  (chevauche légèrement le bas de l'ovale)
//    [600..648] Bandeau nom/role
//    [658..790] Rangée stats 1   (3 cases)
//    [796..928] Rangée stats 2   (3 cases)
//    [938..1010] Cases couleurs  (6 cases)
//
//  Médaillon LVL  : centre (75, 85)   diam 95
//  Badge genre    : (487, 48)→(577,122)
// ═══════════════════════════════════════════════════════════════════════════

class DinoShareCardPortrait extends StatelessWidget {
  final Dino       dino;
  final Color      themeColor;
  final RoleTheme? roleTheme;

  static const double cardW = 607.0;
  static const double cardH = 1077.0;

  // ── zones mesurées sur le fond ────────────────────────────────────────
  static const _dinoR   = _Rect(55,   28,  552,  542);
  static const _scrollR = _Rect(70,  530,  537,  600);
  static const _nameR   = _Rect(80,  602,  527,  648);
  static const _lvl     = _Circle(75,  85, 95);
  static const _gender  = _Rect(487,  48,  577,  122);

  // stats — 2 rangées × 3 colonnes
  static const _sc1 = _Rect( 30, 658, 215, 790);
  static const _sc2 = _Rect(221, 658, 386, 790);
  static const _sc3 = _Rect(392, 658, 577, 790);
  static const _sc4 = _Rect( 30, 796, 215, 928);
  static const _sc5 = _Rect(221, 796, 386, 928);
  static const _sc6 = _Rect(392, 796, 577, 928);

  // couleurs
  static const _colorR = _Rect(30, 938, 577, 1010);

  const DinoShareCardPortrait({
    super.key,
    required this.dino,
    required this.themeColor,
    this.roleTheme,
  });

  // couleurs résolues (identiques à ArkDinoCard)
  Color get _borderColor => roleTheme?.border ?? dino.roleColor;
  Color get _textColor   => roleTheme?.text   ?? dino.roleColor;

  @override
  Widget build(BuildContext context) {
    final hasCustom = dino.image != null && dino.image!.isNotEmpty;

    return MediaQuery(
      data: const MediaQueryData(
        textScaler:       TextScaler.noScaling,
        padding:          EdgeInsets.zero,
        viewInsets:       EdgeInsets.zero,
        viewPadding:      EdgeInsets.zero,
        devicePixelRatio: 1.0,
      ),
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none, height: 1.0),
        child: SizedBox(
          width: cardW, height: cardH,
          child: Stack(children: [

            // ── 0. FOND ────────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/ui/share_card_portrait_bg.png',
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1a0e05)),
              ),
            ),

            // ── 1. DINO dans l'ovale ───────────────────────────────
            _pos(_dinoR, _DinoZone(dino: dino, hasCustomImage: hasCustom,
                                   borderColor: _borderColor)),

            // ── 2. MÉDAILLON LVL ───────────────────────────────────
            Positioned(
              left: _lvl.cx - _lvl.d / 2,
              top:  _lvl.cy - _lvl.d / 2,
              width: _lvl.d, height: _lvl.d,
              child: _LvlBadge(niveau: dino.niveau),
            ),

            // ── 3. BADGE GENRE ─────────────────────────────────────
            if (dino.sexe != 'Inconnu')
              _pos(_gender, _SexBadge(dino: dino)),

            // ── 4. PARCHEMIN ESPÈCE ────────────────────────────────
            _pos(_scrollR, _SpeciesScroll(espece: dino.espece)),

            // ── 5. BANDEAU NOM + ROLE ──────────────────────────────
            _pos(_nameR, _NameBand(dino: dino, textColor: _textColor)),

            // ── 6–11. STATS ────────────────────────────────────────
            _statAt(_sc1, dino, 0),
            _statAt(_sc2, dino, 1),
            _statAt(_sc3, dino, 2),
            _statAt(_sc4, dino, 3),
            _statAt(_sc5, dino, 4),
            _statAt(_sc6, dino, 5),

            // ── 12. COULEURS ───────────────────────────────────────
            _pos(_colorR, _ColorStrip(
              colors: dino.colorRegions,
              species: dino.espece,
            )),
          ]),
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────
  static Widget _pos(_Rect r, Widget child) => Positioned(
    left: r.x1, top: r.y1,
    width: r.w, height: r.h,
    child: child,
  );

  Widget _statAt(_Rect r, Dino dino, int idx) =>
      _pos(r, _StatBox(data: _stats(dino)[idx], species: dino.espece));

  List<_StatData> _stats(Dino d) => [
    _StatData('assets/images/icons/hp.png',      'HP',
              DinoHelpers.formatNumber(d.hp),
              d.hpPoints,       const Color(0xFF4CAF50)),
    _StatData('assets/images/icons/stamina.png', 'Stam',
              DinoHelpers.formatNumber(d.stamina),
              d.staminaPoints,  const Color(0xFFFFD700)),
    _StatData('assets/images/icons/damage.png',  'Dmg',
              '${d.degats.toStringAsFixed(0)}%',
              d.degatsPoints,   const Color(0xFFEF4444)),
    _StatData('assets/images/icons/weight.png',  'Poids',
              DinoHelpers.formatNumber(d.poids),
              d.poidsPoints,    const Color(0xFF3B82F6)),
    _StatData('assets/images/icons/food.png',    'Food',
              DinoHelpers.formatNumber(d.nourriture),
              d.nourriturePoints, const Color(0xFF8B5CF6)),
    _StatData('assets/images/icons/oxygen.png',  'O₂',
              DinoHelpers.formatNumber(d.oxygene),
              d.oxygenePoints,  const Color(0xFF10B981)),
  ];
}

// ── Géométrie ─────────────────────────────────────────────────────────────────
class _Rect {
  final double x1, y1, x2, y2;
  const _Rect(this.x1, this.y1, this.x2, this.y2);
  double get w => x2 - x1;
  double get h => y2 - y1;
}

class _Circle {
  final double cx, cy, d;
  const _Circle(this.cx, this.cy, this.d);
}

// ═══════════════════════════════════════════════════════════════════════════
//  SOUS-WIDGETS  — repris fidèlement depuis ArkDinoCard
// ═══════════════════════════════════════════════════════════════════════════

// ── Zone dino ─────────────────────────────────────────────────────────────────
class _DinoZone extends StatelessWidget {
  final Dino  dino;
  final bool  hasCustomImage;
  final Color borderColor;
  const _DinoZone({
    required this.dino,
    required this.hasCustomImage,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, cs) {
      final w = cs.maxWidth;
      final h = cs.maxHeight;

      Widget img = hasCustomImage
          ? Image.file(File(dino.image!),
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => _arkImg(w, h))
          : _arkImg(w, h);

      return Stack(children: [
        // halo identique à ArkDinoCard
        Positioned.fill(
          child: Center(child: Container(
            width: w * 0.82, height: h * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.05),
                Colors.transparent,
              ], stops: const [0.0, 0.5, 1.0]),
            ),
          )),
        ),
        Positioned.fill(child: img),
      ]);
    });
  }

  Widget _arkImg(double w, double h) => DinoImageWidget(
    species: dino.espece, regionColors: dino.colorRegions,
    width: w, height: h,
    fit: BoxFit.contain, showColorBand: false,
    alignment: Alignment.bottomCenter,
  );
}

// ── Médaillon LVL ─────────────────────────────────────────────────────────────
class _LvlBadge extends StatelessWidget {
  final int niveau;
  const _LvlBadge({required this.niveau});

  @override
  Widget build(BuildContext context) {
    final c = DinoHelpers.getCardRarityColor(niveau);
    return LayoutBuilder(builder: (_, cs) {
      final s = cs.maxHeight;
      return Container(
        width: s, height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.88),
          border: Border.all(color: c, width: 3),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.70),
                                blurRadius: 18, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('LVL', style: GoogleFonts.exo2(
              color: c.withValues(alpha: 0.85), fontSize: s * 0.16,
              fontWeight: FontWeight.w800, letterSpacing: 1.5,
              height: 1.0, decoration: TextDecoration.none,
            )),
            Text('$niveau', style: GoogleFonts.exo2(
              color: c, fontSize: s * 0.36, fontWeight: FontWeight.w900,
              height: 1.0, decoration: TextDecoration.none,
              shadows: [Shadow(color: c.withValues(alpha: 0.8),
                               blurRadius: 8)],
            )),
          ],
        ),
      );
    });
  }
}

// ── Badge sexe — copié exactement de ArkDinoCard._buildSexBadge ──────────────
class _SexBadge extends StatelessWidget {
  final Dino dino;
  const _SexBadge({required this.dino});

  @override
  Widget build(BuildContext context) {
    // Pour Mâle+Femelle on affiche les deux symboles côte à côte
    final isBoth = dino.sexe == 'Mâle+Femelle';

    if (isBoth) {
      return LayoutBuilder(builder: (_, cs) {
        final fs = cs.maxHeight * 0.42;
        return Container(
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Colors.purple.withValues(alpha: 0.60), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('♂', style: TextStyle(
                color: Colors.blue[300], fontSize: fs,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              )),
              SizedBox(width: cs.maxWidth * 0.06),
              Text('♀', style: TextStyle(
                color: Colors.pink[300], fontSize: fs,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              )),
            ],
          ),
        );
      });
    }

    // Copie exacte de _buildSexBadge
    return LayoutBuilder(builder: (_, cs) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: cs.maxWidth  * 0.12,
          vertical:   cs.maxHeight * 0.10,
        ),
        decoration: BoxDecoration(
          color: dino.sexeColor.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dino.sexeColor.withValues(alpha: 0.60),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          dino.sexeSymbol,
          style: TextStyle(
            color: dino.sexeColor,
            fontSize: cs.maxHeight * 0.45,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
          ),
        ),
      );
    });
  }
}

// ── Parchemin espèce ──────────────────────────────────────────────────────────
class _SpeciesScroll extends StatelessWidget {
  final String espece;
  const _SpeciesScroll({required this.espece});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, cs) {
      return Align(
        alignment: Alignment.center,
        child: Text(
          DinoHelpers.toTitleCase(espece),
          style: GoogleFonts.cinzelDecorative(
            color: const Color(0xFF2C1A00),
            fontSize: cs.maxHeight * 0.40,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            height: 1.0,
            decoration: TextDecoration.none,
            shadows: const [Shadow(color: Color(0x44000000),
                blurRadius: 2, offset: Offset(1, 1))],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}

// ── Bandeau nom + tags + diet — remplace l'ancien badge rôle ─────────────────
class _NameBand extends StatelessWidget {
  final Dino  dino;
  final Color textColor;
  const _NameBand({required this.dino, required this.textColor});

  Color _tagColor(String tag, Color fallback) {
    switch (tag.toLowerCase()) {
      case 'boss':        return const Color(0xFFEF4444);
      case 'breeding':    return const Color(0xFFF48FB1);
      case 'solid':       return const Color(0xFFFFD700);
      case 'visualsolid': return const Color(0xFFFFD700);
      case 'farm':        return const Color(0xFF4CAF50);
      case 'collection':  return const Color(0xFF8B5CF6);
      case 'combat':      return const Color(0xFFFF6B00);
      default:            return fallback;
    }
  }

  Color _dietColor(ArkDiet diet) {
    switch (diet) {
      case ArkDiet.carnivore: return const Color(0xFFEF5350);
      case ArkDiet.herbivore: return const Color(0xFF66BB6A);
      case ArkDiet.omnivore:  return const Color(0xFFFF9800);
      case ArkDiet.special:   return const Color(0xFFAB47BC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats  = ArkSpeciesStatsDb.get(dino.espece);
    final tags   = dino.tags.take(3).toList();

    return LayoutBuilder(builder: (_, cs) {
      final h  = cs.maxHeight;
      final fs = h * 0.38;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ligne 1 : nom + tags
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  dino.nom,
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: fs,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.0,
                    decoration: TextDecoration.none,
                    shadows: [Shadow(
                      color: Colors.black.withValues(alpha: 0.60),
                      blurRadius: 4,
                    )],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tags.isNotEmpty) ...[  
                const SizedBox(width: 6),
                ...tags.map((tag) {
                  final tc = _tagColor(tag, textColor);
                  return Container(
                    margin: const EdgeInsets.only(left: 3),
                    padding: EdgeInsets.symmetric(
                      horizontal: h * 0.18,
                      vertical:   h * 0.06,
                    ),
                    decoration: BoxDecoration(
                      color: tc.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: tc.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: TextStyle(
                        color: tc,
                        fontSize: fs * 0.52,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
          // Ligne 2 : diet chip (si connu)
          if (stats != null) ...[  
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: h * 0.22,
                    vertical:   h * 0.05,
                  ),
                  decoration: BoxDecoration(
                    color: _dietColor(stats.diet).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _dietColor(stats.diet).withValues(alpha: 0.50),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(stats.dietEmoji,
                        style: TextStyle(fontSize: fs * 0.48, height: 1.0)),
                      const SizedBox(width: 3),
                      Text(
                        stats.dietLabel.toUpperCase(),
                        style: TextStyle(
                          color: _dietColor(stats.diet),
                          fontSize: fs * 0.44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

// ── Case stat — layout vertical centré (adapté au format portrait) ────────────
class _StatBox extends StatelessWidget {
  final _StatData data;
  final String    species;
  const _StatBox({required this.data, required this.species});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, cs) {
      final w      = cs.maxWidth;
      final h      = cs.maxHeight;
      final iconSz = h * 0.28;
      final lblSz  = h * 0.11;
      final valSz  = h * 0.24;

      return Container(
        decoration: BoxDecoration(
          // gradient identique à ArkDinoCard stats
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: data.color.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: data.color.withValues(alpha: 0.15),
                      blurRadius: 8, spreadRadius: 1),
            BoxShadow(color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 6),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.06,
          vertical:   h * 0.06,
        ),
        child: Column(
          mainAxisAlignment:  MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône
            SizedBox(
              width: iconSz, height: iconSz,
              child: Image.asset(data.icon, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.bar_chart_rounded,
                    color: data.color, size: iconSz)),
            ),
            SizedBox(height: h * 0.04),
            // Label — style ArkDinoCard
            Text(data.label, style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: lblSz, fontWeight: FontWeight.w700,
              height: 1.0, decoration: TextDecoration.none,
            )),
            SizedBox(height: h * 0.02),
            // Valeur — style ArkDinoCard
            Text(data.value, style: GoogleFonts.exo2(
              color: data.color, fontSize: valSz,
              fontWeight: FontWeight.w900, height: 1.0,
              decoration: TextDecoration.none,
              shadows: [Shadow(color: data.color.withValues(alpha: 0.65),
                               blurRadius: 6)],
            )),
          ],
        ),
      );
    });
  }
}

// ── Bande couleurs avec zones inactives masquées ─────────────────────────────
class _ColorStrip extends StatelessWidget {
  final List<String?> colors;
  final String        species;
  const _ColorStrip({required this.colors, required this.species});

  @override
  Widget build(BuildContext context) {
    final visibility = ArkSpeciesColorRegions.visibilityFor(species);

    return LayoutBuilder(builder: (_, cs) {
      const gap = 6.0;
      final cw  = (cs.maxWidth - gap * 5) / 6;
      final ch  = cs.maxHeight;

      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          children: List.generate(6, (i) {
            final isZoneActive = i < visibility.length ? visibility[i] : true;

            // Zone inactive → case transparente
            if (!isZoneActive) {
              return Container(
                width: cw, height: ch,
                margin: EdgeInsets.only(right: i < 5 ? gap : 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 0.5,
                  ),
                ),
              );
            }

            final hex      = i < colors.length ? colors[i] : null;
            final inactive = hex == null ||
                             hex == '#808080' ||
                             hex == '#7F7F7F';
            final col = inactive
                ? const Color(0xFF1F2937)
                : DinoHelpers.parseHex(hex) ?? const Color(0xFF1F2937);

            return Container(
              width: cw, height: ch,
              margin: EdgeInsets.only(right: i < 5 ? gap : 0),
              decoration: BoxDecoration(
                color: col,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(
                      alpha: inactive ? 0.05 : 0.25),
                  width: 0.5,
                ),
                boxShadow: inactive ? null : [BoxShadow(
                  color: col.withValues(alpha: 0.40), blurRadius: 4)],
              ),
            );
          }),
        ),
      );
    });
  }
}

// ── Modèle stat ───────────────────────────────────────────────────────────────
class _StatData {
  final String icon, label, value;
  final int    pts;
  final Color  color;
  const _StatData(this.icon, this.label, this.value, this.pts, this.color);
}
