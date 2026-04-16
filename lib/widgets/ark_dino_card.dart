import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import 'dino_image_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CARTE DINO LISTE - VERSION OPTIMISÉE ET CORRIGÉE
// ══════════════════════════════════════════════════════════════════════════════
class ArkDinoCard extends StatelessWidget {
  final Dino dino;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ArkDinoCard({
    super.key,
    required this.dino,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 145,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F2E), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dino.roleColor.withOpacity(0.3), // ✅ Corrigé
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), // ✅ Corrigé
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: dino.roleColor.withOpacity(0.15), // ✅ Corrigé
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
                  color: Colors.white.withOpacity(0.2), // ✅ Corrigé
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
  // SECTION GAUCHE : BULLE NOIRE + DINO INVERSÉ
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
            dino.roleColor.withOpacity(0.15), // ✅ Corrigé
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.black.withOpacity(0.85), // ✅ Corrigé
                  Colors.black.withOpacity(0.95), // ✅ Corrigé
                ],
              ),
              border: Border.all(
                color: dino.roleColor.withOpacity(0.4), // ✅ Corrigé
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7), // ✅ Corrigé
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.25), // ✅ Corrigé
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: dino.roleColor.withOpacity(0.3), // ✅ Corrigé
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0), // ✅ Syntaxe correcte
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2), // ✅ Corrigé
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: hasCustomImage
                    ? Image.file(
                        File(dino.image!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDinoImageWidget(),
                      )
                    : _buildDinoImageWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDinoImageWidget() {
    return DinoImageWidget(
      species: dino.espece,
      regionColors: dino.colorRegions,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      showColorBand: false,
      alignment: Alignment.center,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER : NOM + ESPÈCE/NIVEAU + BADGES
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
                      color: Colors.black.withOpacity(0.5), // ✅ Corrigé
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
        color: dino.sexeColor.withOpacity(0.2), // ✅ Corrigé
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: dino.sexeColor.withOpacity(0.6), // ✅ Corrigé
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
        color: dino.roleColor.withOpacity(0.15), // ✅ Corrigé
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: dino.roleColor.withOpacity(0.5), // ✅ Corrigé
          width: 1,
        ),
      ),
      child: Text(
        dino.role.toUpperCase(),
        style: TextStyle(
          color: dino.roleColor,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS ULTRA-COMPACTES - CORRIGÉES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25), // ✅ Corrigé
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1), // ✅ Corrigé
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // LIGNE 1 : HP | STAM | DMG
          Row(
            children: [
              Expanded(child: _buildCompactStat('HP', _formatNumber(dino.hp), const Color(0xFF4CAF50))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Stam', _formatNumber(dino.stamina), const Color(0xFFFFD700))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Dmg', '${dino.degats.toStringAsFixed(0)}%', const Color(0xFFEF4444))),
            ],
          ),
          // LIGNE 2 : POIDS | FOOD | OXYGÈNE
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
              color: Colors.white.withOpacity(0.7), // ✅ Corrigé
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' - ',
            style: GoogleFonts.exo2(
              color: Colors.white.withOpacity(0.4), // ✅ Corrigé
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
      color: Colors.white.withOpacity(0.15), // ✅ Corrigé
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BANDE DE COULEURS - CORRIGÉE
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
                Colors.white.withOpacity(0.15), // ✅ Corrigé
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2), // ✅ Corrigé
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withOpacity(0.08), // ✅ Corrigé
              width: 1,
            ),
          ),
          child: Row(
            children: List.generate(6, (i) {
              final hex = i < colors.length ? colors[i] : null;
              final isInactive = hex == null || hex == '#808080' || hex == '#7F7F7F';
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
                      color: Colors.white.withOpacity(isInactive ? 0.05 : 0.25), // ✅ CORRECTION CRITIQUE
                      width: 0.5,
                    ),
                    boxShadow: !isInactive ? [
                      BoxShadow(
                        color: color.withOpacity(0.4), // ✅ Corrigé
                        blurRadius: 2,
                      ),
                    ] : null,
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

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return null;
  }
}
