// lib/widgets/ark_dino_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../models/role_theme.dart';
import '../models/ark_species_color_regions.dart';
import '../models/ark_species_stat.dart';
import '../utils/dino_helpers.dart';
import 'dino_image_widget.dart';
import '../models/ark_species_group.dart';
import 'dart:ui' as ui;



class ArkDinoCard extends StatelessWidget {
  final Dino dino;
  final RoleTheme? roleTheme;

  const ArkDinoCard({
    super.key,
    required this.dino,
    this.roleTheme,
  });

  // ─── Référentiel design (taille logique du PNG) ──────────────────────────
  static const double _refW = 242;
  static const double _refH = 428;

  // ─── Couleurs thème ──────────────────────────────────────────────────────
  Color get _themeColor => roleTheme?.text ?? dino.roleColor;

    // ═══════════════════════════════════════════════════════════════════════
  // FOND DYNAMIQUE — sélectionné selon le groupe de l'espèce
  // ═══════════════════════════════════════════════════════════════════════
  String get _backgroundAssetPath {
    final group = ArkSpeciesGroupData.groupFor(dino.espece);
    switch (group) {
      case ArkSpeciesGroup.terrestre:
        return 'assets/images/ui/share_card_portrait_bg_terrestre.png';
      case ArkSpeciesGroup.aquatic:
        return 'assets/images/ui/share_card_portrait_bg_aqua.png';
      case ArkSpeciesGroup.volant:
        return 'assets/images/ui/share_card_portrait_bg_air.png';
      case ArkSpeciesGroup.fantastic:
        return 'assets/images/ui/share_card_portrait_bg_fantastic.png';
      case ArkSpeciesGroup.compagnon:
        return 'assets/images/ui/share_card_portrait_bg_compagnon.png';
    }
  }

  /// Asset de secours universel si le fond du groupe est introuvable.
  static const String _fallbackAssetPath =
      'assets/images/ui/share_card_portrait_bg.png';


  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _refW / _refH,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final scale = w / _refW;

          return Stack(
            clipBehavior: Clip.none,
            children: [
                           // ── 0. FOND IMAGE (dynamique selon groupe d'espèce) ──────────
              Positioned.fill(
                child: Image.asset(
                  _backgroundAssetPath,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) {
                    // Niveau 1 : le fond spécifique au groupe est absent
                    // → on retombe sur le fond global historique.
                    return Image.asset(
                      _fallbackAssetPath,
                      fit: BoxFit.fill,
                      // Niveau 2 : même le fallback PNG est absent
                      // → on peint le gradient violet par défaut.
                      errorBuilder: (_, __, ___) => _fallbackBackground(),
                    );
                  },
                ),
              ),

              // ── 1. ŒUF IMAGE DINO (centre 123, 108 ; 169×202) ───────────
              _positionedCentered(
                cx: 123, cy: 115, w: 169, h: 202,
                scale: scale,
                child: _buildEggImage(),
              ),

              // ── 2. MÉDAILLON LVL (centre 27, 36 ; Ø32) ──────────────────
              _positionedCentered(
                cx: 30, cy: 35, w: 32, h: 32,
                scale: scale,
                child: _buildLvlBadge(scale),
              ),

              // ── 3. BADGE SEXE (centre 215, 36 ; Ø32) ── EN HAUT À DROITE
              if (dino.sexe != 'Inconnu')
                _positionedCentered(
                  cx: 215, cy: 36, w: 32, h: 32,
                  scale: scale,
                  child: _buildSexBadge(scale),
                ),

              // ── 4. PARCHEMIN ESPÈCE (centre 123, 214 ; 170×32) ──────────
              _positionedCentered(
                cx: 123, cy: 218, w: 170, h: 32,
                scale: scale,
                child: _buildSpeciesText(scale),
              ),

              // ── 5. PARCHEMIN NOM + TAG (centre 123, 243 ; 120×16) ───────
              _positionedCentered(
                cx: 123, cy: 243, w: 120, h: 16,
                scale: scale,
                child: _buildNameAndTag(scale),
              ),

              // ── 6. STATS GRID ────────────────────────────────────────────
              ..._buildAllStatCells(scale),

              // ── 7. CARRÉS DE COULEUR ────────────────────────────────────
              ..._buildAllColorSquares(scale),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER : positionnement par CENTRE (cx, cy, w, h) en px du référentiel
  // ═══════════════════════════════════════════════════════════════════════
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
  // FALLBACK BACKGROUND si asset manquant
  // ═══════════════════════════════════════════════════════════════════════
  Widget _fallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1A4A), Color(0xFF1A1230)],
        ),
      ),
    );
  }

    // ═══════════════════════════════════════════════════════════════════════
  // ŒUF — image du dino + halo flou de la même image (effet volume)
  // Stack de bas en haut :
  //   1. Halo radial sombre (CustomPaint existant)
  //   2. Copie floutée de l'image du dino, agrandie 110%, opacité ~10%
  //   3. Image nette du dino
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEggImage() {
    final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;

    // Widget réutilisable : la même image que la version nette,
    // mais qui servira pour le halo flou en arrière-plan.
    Widget blurredCopy() {
      Widget img = hasCustomImage
          ? Image.file(
              File(dino.image!),
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => _buildSpeciesImage(),
            )
          : _buildSpeciesImage();

      return IgnorePointer(
        child: Opacity(
          opacity: 0.10, // ← 10% comme demandé
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
              tileMode: TileMode.decal,
            ),
            child: Transform.scale(
              scale: 1.10, // léger débord pour le halo
              child: img,
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // 1. Halo radial sombre (inchangé)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _OvalGlowPainter(
                glowColor: Colors.black.withValues(alpha: 0.45),
                edgeColor: Colors.transparent,
              ),
            ),
          ),
        ),

        // 2. Halo flou = copie floutée de l'image du dino
        Positioned.fill(child: blurredCopy()),

        // 3. Image nette du dino (au-dessus)
        Positioned.fill(
          child: hasCustomImage
              ? Image.file(
                  File(dino.image!),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => _buildSpeciesImage(),
                )
              : _buildSpeciesImage(),
        ),
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
  // MÉDAILLON LVL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLvlBadge(double scale) {
    final c = DinoHelpers.getCardRarityColor(dino.niveau);
    final clamped = scale.clamp(1.0, 3.5);
    final fontLvl = 6.0 * clamped;
    final fontNum = (dino.niveau >= 1000 ? 9.0 : 11.0) * clamped;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: c, width: 1.5 * scale.clamp(1.0, 2.5)),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.6),
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
              color: c.withValues(alpha: 0.85),
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

  // ═══════════════════════════════════════════════════════════════════════
  // BADGE SEXE — mis à l'échelle du référentiel (comme le médaillon LVL)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSexBadge(double scale) {
    final clamped = scale.clamp(1.0, 3.5);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dino.sexeColor.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(
          color: dino.sexeColor.withValues(alpha: 0.75),
          width: 1.5 * scale.clamp(1.0, 2.5),
        ),
        boxShadow: [
          BoxShadow(
            color: dino.sexeColor.withValues(alpha: 0.45),
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
  // PARCHEMIN ESPÈCE — taille de base grande, réduit auto si trop long
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSpeciesText(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcule la fontSize qui fait tenir le texte dans la largeur dispo.
          final text = DinoHelpers.toTitleCase(dino.espece);
          const double maxFont = 22.0;
          const double minFont = 11.0;
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

  // ═══════════════════════════════════════════════════════════════════════
  // PARCHEMIN NOM + 1 SEUL TAG
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildNameAndTag(double scale) {
    final hasTag  = dino.tags.isNotEmpty;
    final tagLbl  = hasTag ? dino.tags.first : null;
    final tagCol  = hasTag ? _tagColor(tagLbl!) : _themeColor;

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
                    color: Colors.black.withValues(alpha: 0.7),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: tagCol.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: tagCol.withValues(alpha: 0.7),
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
      default:             return _themeColor;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS — 6 cases positionnées (inchangé)
  // ═══════════════════════════════════════════════════════════════════════
   // ═══════════════════════════════════════════════════════════════════════
  // STATS — 6 cases positionnées
  //
  // Règle d'affichage :
  //   - Si l'utilisateur n'a PAS saisi de valeur pour la stat (== 0)
  //       → valeur affichée  : '???'
  //       → points affichés  : aucun (zone vide)
  //   - Sinon
  //       → valeur affichée  : valeur saisie
  //       → points affichés  : valeur saisie de points si > 0, sinon rien
  // On ne complète JAMAIS avec les stats de base de l'espèce.
  // ═══════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllStatCells(double scale) {
    String intVal(int v) => v > 0 ? DinoHelpers.formatNumber(v) : '???';
    String dmgVal(double v) => v > 0 ? '${v.toStringAsFixed(0)}%' : '???';

    int? userPts(int pts) => pts > 0 ? pts : null;

    final cells = <_StatCellData>[
      _StatCellData(
        cx: 48, cy: 291,
        emoji: '❤️', label: 'VIE',
        value: intVal(dino.hp),
        color: const Color(0xFF4CAF50),
        isDefault: dino.hp == 0,
        points: dino.hp > 0 ? userPts(dino.hpPoints) : null,
      ),
      _StatCellData(
        cx: 123, cy: 291,
        emoji: '⚡', label: 'STAM',
        value: intVal(dino.stamina),
        color: const Color(0xFFFFD700),
        isDefault: dino.stamina == 0,
        points: dino.stamina > 0 ? userPts(dino.staminaPoints) : null,
      ),
      _StatCellData(
        cx: 200, cy: 291,
        emoji: '⚔️', label: 'ATTACK',
        value: dmgVal(dino.degats),
        color: const Color(0xFFEF4444),
        isDefault: dino.degats == 0,
        points: dino.degats > 0 ? userPts(dino.degatsPoints) : null,
      ),
      _StatCellData(
        cx: 48, cy: 353,
        emoji: '⚖️', label: 'POIDS',
        value: intVal(dino.poids),
        color: const Color(0xFF3B82F6),
        isDefault: dino.poids == 0,
        points: dino.poids > 0 ? userPts(dino.poidsPoints) : null,
      ),
      _StatCellData(
        cx: 125, cy: 353,
        emoji: '🍖', label: 'FOOD',
        value: intVal(dino.nourriture),
        color: const Color(0xFF8B5CF6),
        isDefault: dino.nourriture == 0,
        points: dino.nourriture > 0 ? userPts(dino.nourriturePoints) : null,
      ),
      _StatCellData(
        cx: 200, cy: 353,
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
    final effColor = c.isDefault ? c.color.withValues(alpha: 0.50) : c.color;

    // Hauteurs fixes (référentiel 47 px de hauteur de cellule) :
    //   - ligne 1 (label)  : ~13 px
    //   - ligne 2 (valeur) : ~18 px
    //   - ligne 3 (points) : ~12 px
    // → total ≈ 43 px, le reste = padding interne.
    const double rowLabel  = 13.0;
    const double rowValue  = 18.0;
    const double rowPoints = 12.0;

    // Texte des points (ou chaîne vide si rien à afficher).
    String pointsText = '';
    Color pointsColor = Colors.transparent;
    if (c.points != null) {
      if (c.points == -1) {
        pointsText  = '??? pts';
        pointsColor = Colors.white.withValues(alpha: 0.55);
      } else if (c.points! > 0) {
        pointsText  = '+${c.points} pts';
        pointsColor = effColor.withValues(alpha: 0.85);
      } else {
        pointsText  = '+0 pts';
        pointsColor = effColor.withValues(alpha: 0.85);
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
          // ── Ligne 1 : label (toujours alignée) ──────────────────────────
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
                          .withValues(alpha: c.isDefault ? 0.45 : 0.85),
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

          // ── Ligne 2 : valeur (toujours au même Y) ────────────────────────
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
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Ligne 3 : points (zone réservée même si vide) ────────────────
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

 int? _resolvePoints(int storedPoints, int dinoVal, int? baseVal) {
    if (storedPoints > 0) return storedPoints;
    if (baseVal == null || baseVal == 0) return null;
    final diff = dinoVal - baseVal;
    if (diff < 0) return -1; // ← sentinelle "inconnu"
    if (diff == 0) return 0;
    final pts = (diff / (baseVal * 0.1)).round();
    return pts > 0 ? pts : 0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CARRÉS DE COULEUR — NOUVELLE LOGIQUE
  //   1. Couleur réelle posée  → carré coloré + ID écrit en couleur contrastée
  //   2. Zone active mais vide → carré gris uni sans rien
  //   3. Zone inactive         → carré à rayures diagonales sur fond gris
  // ═══════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllColorSquares(double scale) {
    final colors = _resolveDisplayColors();
    final ids    = _resolveDisplayIds();
    final xs = [34.0, 69.0, 105.0, 140.0, 176.0, 211.0];

    return List.generate(6, (i) {
      final hex = i < colors.length ? colors[i] : null;
      final id  = i < ids.length    ? ids[i]    : 0;
      final parsed = _parseHex(hex);
      final isFilled = parsed != null &&
          hex != '#808080' &&
          hex != '#7F7F7F' &&
          id > 0;

      return _positionedCentered(
        cx: xs[i], cy: 400, w: 22, h: 22,
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

    // ─── Case vide : aucune couleur déclarée ─────────────────────────────
    // Plus de distinction zone active / inactive : si rien n'est posé,
    // c'est juste un carré gris uni.
    if (!isFilled) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6B6B6B),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
      );
    }

    // ─── Case avec couleur posée : on l'affiche systématiquement ─────────
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
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.55),
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
  // Logique Solid / VisualSolid (couleurs)
  // ═══════════════════════════════════════════════════════════════════════
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

  /// Idem mais pour les IDs (utilisés pour l'affichage du n° dans le carré).
  /// On suit la même logique Solid / VisualSolid : si solid, on duplique
  /// l'ID de la première région ayant une couleur réelle.
  List<int> _resolveDisplayIds() {
    final baseIds = [
      dino.colorId0,
      dino.colorId1,
      dino.colorId2,
      dino.colorId3,
      dino.colorId4,
      dino.colorId5,
    ];

    final hasSolid       = dino.tags.any((t) => t.toLowerCase() == 'solid');
    final hasVisualSolid = dino.tags.any((t) => t.toLowerCase() == 'visualsolid');

    if (!hasSolid && !hasVisualSolid) return baseIds;

    int firstId = 0;
    for (final id in baseIds) {
      if (id > 0) { firstId = id; break; }
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

// ─────────────────────────────────────────────────────────────────────────────
// Structure de données pour une case stat
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Clipper ovale pour épouser la forme de l'œuf cristallin
// ─────────────────────────────────────────────────────────────────────────────
class _OvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter : rayures diagonales pour zones inactives
// ─────────────────────────────────────────────────────────────────────────────
class _DiagonalStripesPainter extends CustomPainter {
  final Color background;
  final Color stripeColor;
  final double stripeWidth;
  final double gap;
  final double cornerRadius;

  _DiagonalStripesPainter({
    required this.background,
    required this.stripeColor,
    required this.stripeWidth,
    required this.gap,
    this.cornerRadius = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = background;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, bgPaint);

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    final step = stripeWidth + gap;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        stripePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter old) =>
      old.background != background ||
      old.stripeColor != stripeColor ||
      old.stripeWidth != stripeWidth ||
      old.gap != gap ||
      old.cornerRadius != cornerRadius;
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter : halo flou ovale (remplace l'ancien clip ovale par un effet doux)
// ─────────────────────────────────────────────────────────────────────────────
class _OvalGlowPainter extends CustomPainter {
  final Color glowColor;
  final Color edgeColor;

  _OvalGlowPainter({
    required this.glowColor,
    required this.edgeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Gradient radial : centre opaque (glowColor) → bords transparents.
    // Inversé : on veut un assombrissement central léger pour ancrer le dino,
    // ou plutôt un halo qui s'estompe vers les bords pour suggérer l'œuf.
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.7,
        colors: [
          glowColor,
          glowColor.withValues(alpha: glowColor.a * 0.4),
          edgeColor,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    // On dessine une ellipse pour rester dans l'esprit "œuf".
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
