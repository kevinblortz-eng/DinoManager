// lib/widgets/share_card/dino_share_card.dart

import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dino.dart';
import '../../models/ark_species_stat.dart';
import '../../utils/dino_helpers.dart';
import '../../widgets/dino_image_widget.dart';

class DinoShareCard extends StatelessWidget {
  final Dino  dino;
  final Color themeColor;

  static const double cardW = 1280.0;
  static const double cardH =  807.0;

  const DinoShareCard({
    super.key,
    required this.dino,
    required this.themeColor,
  });

  // ── Couleurs identiques à ArkDinoCard ────────────────────────────────
  Color get _borderColor => dino.roleColor;

  Color get _textColor   => dino.roleColor;

  @override
  Widget build(BuildContext context) {
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
          width:  cardW,
          height: cardH,
          child: Stack(children: [

            // ── 0. FOND ──────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/ui/share_card_bg.png',
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1a0e05)),
              ),
            ),

            // ── 1. CONTENU principal ─────────────────────────────
            // Même structure que ArkDinoCard mais en grand format
            Positioned(
              left:   62,
              top:    48,
              right:  62,
              bottom: 58,
              child: _CardContent(dino: dino,
                                  borderColor: _borderColor,
                                  textColor:   _textColor),
            ),

          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CONTENU PRINCIPAL — reproduit fidèlement ArkDinoCard en grand
// ═══════════════════════════════════════════════════════════════════════════
class _CardContent extends StatelessWidget {
  final Dino  dino;
  final Color borderColor;
  final Color textColor;

  const _CardContent({
    required this.dino,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ── COLONNE GAUCHE : dino image ───────────────────────────
        _DinoSection(dino: dino, borderColor: borderColor),

        // ── COLONNE DROITE : infos ────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header nom + espèce + badges
                _HeaderSection(dino: dino, textColor: textColor),
                const SizedBox(height: 16),

                // Stats grid — copie de _buildStatsGrid
                Expanded(child: _StatsGrid(dino: dino)),
                const SizedBox(height: 12),

                // Bande couleurs — copie de _buildColorStrip
                _ColorStrip(colors: dino.colorRegions),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION DINO IMAGE — copie de _buildDinoSection
// ═══════════════════════════════════════════════════════════════════════════
class _DinoSection extends StatelessWidget {
  final Dino  dino;
  final Color borderColor;
  const _DinoSection({required this.dino, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final hasCustom = dino.image != null && dino.image!.isNotEmpty;

    return Container(
      width: 500,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.centerLeft,
          radius: 1.5,
          colors: [
            borderColor.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle fond — identique ArkDinoCard
          Container(
            width:  460,
            height: 460,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.95),
              ]),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 40, spreadRadius: 6),
                BoxShadow(color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 30, spreadRadius: 2),
                BoxShadow(color: borderColor.withValues(alpha: 0.3),
                          blurRadius: 40, spreadRadius: -4),
              ],
            ),
          ),
          // Image dans le cercle
          ClipOval(
            child: SizedBox(
              width: 460, height: 460,
              child: hasCustom
                  ? Image.file(File(dino.image!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _flippedImg())
                  : _flippedImg(),
            ),
          ),
          // Médaillon LVL — haut gauche du cercle
          Positioned(
            left: 0, top: 0,
            child: _LvlBadge(niveau: dino.niveau),
          ),
        ],
      ),
    );
  }

  Widget _flippedImg() => Transform(
    alignment: Alignment.center,
    transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
    child: DinoImageWidget(
      species:      dino.espece,
      regionColors: dino.colorRegions,
      width:  460,
      height: 460,
      fit:          BoxFit.cover,
      showColorBand: false,
      alignment:    Alignment.center,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  MÉDAILLON LVL
// ═══════════════════════════════════════════════════════════════════════════
class _LvlBadge extends StatelessWidget {
  final int niveau;
  const _LvlBadge({required this.niveau});

  @override
  Widget build(BuildContext context) {
    final c = DinoHelpers.getCardRarityColor(niveau);
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.88),
        border: Border.all(color: c, width: 4),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.70),
                              blurRadius: 22, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('LVL', style: GoogleFonts.exo2(
            color: c.withValues(alpha: 0.85), fontSize: 15,
            fontWeight: FontWeight.w800, letterSpacing: 2,
            height: 1.0, decoration: TextDecoration.none,
          )),
          Text('$niveau', style: GoogleFonts.exo2(
            color: c, fontSize: 38, fontWeight: FontWeight.w900,
            height: 1.0, decoration: TextDecoration.none,
            shadows: [Shadow(color: c.withValues(alpha: 0.8),
                             blurRadius: 10)],
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HEADER — copie de _buildHeaderSection
// ═══════════════════════════════════════════════════════════════════════════
class _HeaderSection extends StatelessWidget {
  final Dino  dino;
  final Color textColor;
  const _HeaderSection({required this.dino, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne 1 : nom + badge sexe
        Row(children: [
          Expanded(
            child: Text(dino.nom, style: GoogleFonts.exo2(
              color: Colors.white, fontSize: 52,
              fontWeight: FontWeight.w900, letterSpacing: 0.5,
              height: 1.0, decoration: TextDecoration.none,
              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5),
                               blurRadius: 8)],
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          if (dino.sexe != 'Inconnu') _SexBadge(dino: dino),
        ]),
        const SizedBox(height: 6),
        // Ligne 2 : espèce + lvl + badge rôle
        Row(children: [
          Expanded(
            child: Text(
              '${dino.espece}  ·  Lvl ${dino.niveau}',
              style: GoogleFonts.exo2(
                color: const Color(0xFF9CA3AF), fontSize: 28,
                fontWeight: FontWeight.w600,
                height: 1.0, decoration: TextDecoration.none,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          _RoleBadge(dino: dino, textColor: textColor),
        ]),
      ],
    );
  }
}

// ── Badge sexe — copie exacte de _buildSexBadge ──────────────────────────────
class _SexBadge extends StatelessWidget {
  final Dino dino;
  const _SexBadge({required this.dino});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: dino.sexeColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dino.sexeColor.withValues(alpha: 0.60),
          width: 2,
        ),
      ),
      child: Text(
        dino.sexeSymbol,
        style: TextStyle(
          color: dino.sexeColor,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

// ── Tags + Diet badges (remplace l'ancien _RoleBadge) ────────────────────────
class _RoleBadge extends StatelessWidget {
  final Dino  dino;
  final Color textColor;
  const _RoleBadge({required this.dino, required this.textColor});

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'boss':        return const Color(0xFFEF4444);
      case 'breeding':    return const Color(0xFFF48FB1);
      case 'solid':       return const Color(0xFFFFD700);
      case 'visualsolid': return const Color(0xFFFFD700);
      case 'farm':        return const Color(0xFF4CAF50);
      case 'collection':  return const Color(0xFF8B5CF6);
      case 'combat':      return const Color(0xFFFF6B00);
      default:            return textColor;
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
    final tags  = dino.tags.take(3).toList();
    final stats = ArkSpeciesStatsDb.get(dino.espece);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        // Diet chip
        if (stats != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _dietColor(stats.diet).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _dietColor(stats.diet).withValues(alpha: 0.50),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stats.dietEmoji,
                    style: const TextStyle(
                      fontSize: 16, height: 1.0,
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(width: 5),
                Text(
                  stats.dietLabel.toUpperCase(),
                  style: TextStyle(
                    color: _dietColor(stats.diet),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        // Tag chips
        ...tags.map((tag) {
          final tc = _tagColor(tag);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tc.withValues(alpha: 0.50),
                width: 1.5,
              ),
            ),
            child: Text(
              tag.toUpperCase(),
              style: TextStyle(
                color: tc,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                decoration: TextDecoration.none,
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATS GRID — copie exacte de _buildStatsGrid + _buildCompactStat
// ═══════════════════════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final Dino dino;
  const _StatsGrid({required this.dino});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Ligne 1 — HP / Stam / Dmg
          Row(children: [
            Expanded(child: _Stat('HP',
                DinoHelpers.formatNumber(dino.hp),
                const Color(0xFF4CAF50))),
            _Divider(),
            Expanded(child: _Stat('Stam',
                DinoHelpers.formatNumber(dino.stamina),
                const Color(0xFFFFD700))),
            _Divider(),
            Expanded(child: _Stat('Dmg',
                '${dino.degats.toStringAsFixed(0)}%',
                const Color(0xFFEF4444))),
          ]),
          // Ligne 2 — Poids / Food / O₂
          Row(children: [
            Expanded(child: _Stat('Poids',
                DinoHelpers.formatNumber(dino.poids),
                const Color(0xFF3B82F6))),
            _Divider(),
            Expanded(child: _Stat('Food',
                DinoHelpers.formatNumber(dino.nourriture),
                const Color(0xFF8B5CF6))),
            _Divider(),
            Expanded(child: _Stat('O₂',
                DinoHelpers.formatNumber(dino.oxygene),
                const Color(0xFF10B981))),
          ]),
        ],
      ),
    );
  }
}

// ── Stat individuelle — copie de _buildCompactStat ────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.exo2(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 22, fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          )),
          Text(' - ', style: GoogleFonts.exo2(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 22, fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          )),
          Text(value, style: GoogleFonts.exo2(
            color: color, fontSize: 26,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
          )),
        ],
      ),
    );
  }
}

// ── Séparateur — copie de _buildStatDivider ───────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2, height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BANDE COULEURS — copie exacte de _buildColorStrip
// ═══════════════════════════════════════════════════════════════════════════
class _ColorStrip extends StatelessWidget {
  final List<String?> colors;
  const _ColorStrip({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Séparateur gradient
      Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          children: List.generate(6, (i) {
            final hex = i < colors.length ? colors[i] : null;
            final inactive = hex == null ||
                             hex == '#808080' ||
                             hex == '#7F7F7F';
            final col = inactive
                ? const Color(0xFF1F2937)
                : DinoHelpers.parseHex(hex) ?? const Color(0xFF1F2937);

            return Expanded(
              child: Container(
                height: 28,
                margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                decoration: BoxDecoration(
                  color: col,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(
                        alpha: inactive ? 0.05 : 0.25),
                    width: 0.5,
                  ),
                  boxShadow: inactive ? null : [BoxShadow(
                    color: col.withValues(alpha: 0.4), blurRadius: 4)],
                ),
              ),
            );
          }),
        ),
      ),
    ]);
  }
}
