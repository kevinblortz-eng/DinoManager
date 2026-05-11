import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../models/role_theme.dart';
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

  // Couleurs résolues — thème perso si disponible, sinon roleColor du dino
  Color get _borderColor => roleTheme?.border ?? dino.roleColor;
  Color get _bgColor => roleTheme?.background ?? const Color(0xFF1A1F2E);
  Color get _textColor => roleTheme?.text ?? dino.roleColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 145,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _bgColor,
              Color.lerp(_bgColor, const Color(0xFF111827), 0.6)!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Row(
            children: [
              _buildDinoSection(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 4),
                      Expanded(child: _buildStatsGrid()),
                      const SizedBox(height: 3),
                      _buildColorStrip(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION GAUCHE
  // ══════════════════════════════════════════════════════════════════════════
Widget _buildDinoSection() {
  final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;

  return Container(
    width: 120,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.centerLeft,
        radius: 1.5,
        colors: [
          _borderColor.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // ── Cercle fond ──
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: _borderColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 15,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: _borderColor.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
        ),

        // ── Image dans le cercle ──
        ClipOval(
          child: SizedBox(
            width: 104,
            height: 104,
            child: hasCustomImage
                // Image custom — PAS de flip
                ? Image.file(
                    File(dino.image!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDinoImageWidgetFlipped(),
                  )
                // Image espèce ARK — flip horizontal
                : _buildDinoImageWidgetFlipped(),
          ),
        ),
      ],
    ),
  );
}

/// Image ARK flippée horizontalement (dino regardant vers la droite)
Widget _buildDinoImageWidgetFlipped() {
  return Transform(
    alignment: Alignment.center,
    transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
    child: DinoImageWidget(
      species: dino.espece,
      regionColors: dino.colorRegions,
      width: 104,
      height: 104,
      fit: BoxFit.cover,
      showColorBand: false,
      alignment: Alignment.center,
    ),
  );
}

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dino.nom,
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (dino.sexe != 'Inconnu') _buildSexBadge(),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                '${dino.espece}  ·  Lvl ${dino.niveau}',
                style: GoogleFonts.exo2(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildRoleBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildSexBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: dino.sexeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: dino.sexeColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Text(
        dino.sexeSymbol,
        style: TextStyle(
          color: dino.sexeColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _textColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: _textColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        dino.role.toUpperCase(),
        style: TextStyle(
          color: _textColor,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Expanded(child: _buildCompactStat('HP', _formatNumber(dino.hp), const Color(0xFF4CAF50))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Stam', _formatNumber(dino.stamina), const Color(0xFFFFD700))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Dmg', '${dino.degats.toStringAsFixed(0)}%', const Color(0xFFEF4444))),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildCompactStat('Poids', _formatNumber(dino.poids), const Color(0xFF3B82F6))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Food', _formatNumber(dino.nourriture), const Color(0xFF8B5CF6))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('O₂', _formatNumber(dino.oxygene), const Color(0xFF10B981))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' - ',
            style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.exo2(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BANDE DE COULEURS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildColorStrip() {
    final colors = dino.colorRegions;

    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: List.generate(6, (i) {
              final hex = i < colors.length ? colors[i] : null;
              final isInactive = hex == null ||
                  hex == '#808080' ||
                  hex == '#7F7F7F';
              final color = isInactive
                  ? const Color(0xFF1F2937)
                  : _parseHex(hex) ?? const Color(0xFF1F2937);

              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < 5 ? 1 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: isInactive ? 0.05 : 0.25),
                      width: 0.5,
                    ),
                    boxShadow: !isInactive
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  String _formatNumber(int value) => DinoHelpers.formatNumber(value);
  Color? _parseHex(String? hex) => DinoHelpers.parseHex(hex);
}
